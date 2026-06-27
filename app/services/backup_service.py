import asyncio
import os
import shutil
import subprocess
from datetime import datetime, timezone, timedelta

from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.database import SessionLocal
from app.core.logging import get_logger
from app.domain.models import BackupLog, gen_uuid
from app.services.audit_service import AuditService

logger = get_logger(__name__)


class BackupService:
    @staticmethod
    def _get_backup_dir() -> str:
        settings = get_settings()
        backup_dir = settings.backup_dir
        os.makedirs(backup_dir, exist_ok=True)
        return backup_dir

    @staticmethod
    def create_backup(db: Session, triggered_by: str = "system", notes: str = "") -> dict:
        settings = get_settings()
        backup_dir = BackupService._get_backup_dir()
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        filename = f"stroapp_backup_{timestamp}.sql"
        filepath = os.path.join(backup_dir, filename)

        backup_log = BackupLog(
            id=gen_uuid(),
            filename=filename,
            file_path=filepath,
            file_size=0,
            status="running",
            triggered_by=triggered_by,
            notes=notes,
            started_at=datetime.now(timezone.utc),
        )
        db.add(backup_log)
        db.commit()

        try:
            db_url = settings.database_url
            result = subprocess.run(
                ["pg_dump", db_url, "--no-owner", "--no-acl", "-f", filepath],
                capture_output=True, text=True, timeout=300,
            )
            if result.returncode != 0:
                raise RuntimeError(f"pg_dump failed: {result.stderr}")

            file_size = os.path.getsize(filepath)
            backup_log.file_size = file_size
            backup_log.status = "completed"
            backup_log.completed_at = datetime.now(timezone.utc)

            audit_user = triggered_by if triggered_by != "system" else None
            AuditService.log(db, audit_user, "backup.create", "backup", backup_log.id,
                             {"filename": filename, "size_bytes": file_size}, "", "")
            db.commit()
            logger.info(f"Backup created: {filename} ({file_size} bytes)")
            return {"id": backup_log.id, "filename": filename, "file_size": file_size, "status": "completed"}

        except Exception as e:
            backup_log.status = "failed"
            backup_log.error_message = str(e)
            backup_log.completed_at = datetime.now(timezone.utc)
            db.commit()
            logger.error(f"Backup failed: {e}")
            return {"id": backup_log.id, "status": "failed", "error": str(e)}

    @staticmethod
    def restore_backup(db: Session, backup_id: str, triggered_by: str = "admin") -> dict:
        backup = db.query(BackupLog).filter(BackupLog.id == backup_id).first()
        if not backup:
            return {"success": False, "error": "النسخة الاحتياطية غير موجودة"}
        if backup.status != "completed":
            return {"success": False, "error": "النسخة الاحتياطية غير مكتملة"}
        if not os.path.exists(backup.file_path):
            return {"success": False, "error": "ملف النسخة الاحتياطية غير موجود"}
        try:
            settings = get_settings()
            result = subprocess.run(
                ["psql", settings.database_url, "-f", backup.file_path],
                capture_output=True, text=True, timeout=600,
            )
            if result.returncode != 0:
                raise RuntimeError(f"Restore failed: {result.stderr}")

            audit_user = triggered_by if triggered_by != "system" else None
            AuditService.log(db, audit_user, "backup.restore", "backup", backup.id,
                             {"filename": backup.filename}, "", "")
            logger.info(f"Backup restored: {backup.filename}")
            return {"success": True, "filename": backup.filename}
        except Exception as e:
            logger.error(f"Restore failed: {e}")
            return {"success": False, "error": str(e)}

    @staticmethod
    def get_backups(db: Session, page: int = 1, per_page: int = 20) -> tuple[list[dict], int]:
        total = db.query(BackupLog).count()
        items = (
            db.query(BackupLog)
            .order_by(BackupLog.started_at.desc())
            .offset((page - 1) * per_page)
            .limit(per_page)
            .all()
        )
        return [b.to_dict() for b in items], total

    @staticmethod
    def cleanup_old_backups(db: Session) -> int:
        settings = get_settings()
        cutoff = datetime.now(timezone.utc) - timedelta(days=settings.backup_retention_days)
        old = db.query(BackupLog).filter(BackupLog.started_at < cutoff).all()
        removed = 0
        for backup in old:
            try:
                if os.path.exists(backup.file_path):
                    os.remove(backup.file_path)
                db.delete(backup)
                removed += 1
            except Exception as e:
                logger.warning(f"Failed to remove old backup {backup.id}: {e}")
        db.commit()
        if removed:
            logger.info(f"Cleaned up {removed} old backups")
        return removed


class BackupJob:
    async def run(self):
        while True:
            await asyncio.sleep(86400)
            try:
                db = SessionLocal()
                try:
                    BackupService.create_backup(db, triggered_by="system", notes="Daily automatic backup")
                    BackupService.cleanup_old_backups(db)
                finally:
                    db.close()
            except Exception as e:
                logger.error(f"Backup job failed: {e}")
