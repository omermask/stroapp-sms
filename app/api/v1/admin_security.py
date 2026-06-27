from datetime import date
from typing import Optional

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_admin
from app.core.response import success_response
from app.domain.models import User
from app.services.backup_service import BackupService
from app.services.disaster_recovery import DisasterRecoveryService
from app.services.security_scanner import SecurityScanner
from app.infrastructure.security.compliance_reporter import ComplianceReporter
from app.infrastructure.security.secrets_manager import secrets_manager
from app.infrastructure.push.onesignal import onesignal_client
from app.infrastructure.bot.telegram_bot import TelegramBotClient
from app.services.audit_service import AuditService


class ScanRequest(BaseModel):
    scan_type: str = "quick"


class BackupRequest(BaseModel):
    notes: Optional[str] = None


class DRTestRequest(BaseModel):
    test_type: str = "quick"


class OneSignalTestRequest(BaseModel):
    player_id: str
    title: str = "اختبار"
    body: str = "هذه رسالة اختبارية من لوحة التحكم"


class TelegramTestRequest(BaseModel):
    chat_id: str
    message: str = "اختبار: لوحة التحكم تعمل"


router = APIRouter(prefix="/admin/security", tags=["Admin Security"])


@router.post("/scan")
async def run_security_scan(
    body: ScanRequest,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    if body.scan_type == "full":
        result = await SecurityScanner.run_full_scan(db, triggered_by=_.id)
    else:
        result = await SecurityScanner.run_quick_check(db)
    return success_response(result)


@router.get("/scans")
async def get_scan_history(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = SecurityScanner.get_scan_history(db, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/compliance")
async def get_compliance_report(
    start_date: date = Query(...),
    end_date: date = Query(...),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    report = ComplianceReporter.generate_report(db, start_date, end_date)
    AuditService.log(db, _.id, "compliance.report", "compliance", "",
                     {"start_date": str(start_date), "end_date": str(end_date)}, "", "")
    return success_response(report)


@router.get("/secrets/check")
async def check_secrets_manager(
    _: User = Depends(get_current_admin),
):
    test = secrets_manager.encrypt("test-value")
    decrypted = secrets_manager.decrypt(test)
    working = decrypted == "test-value"
    return success_response({"configured": True, "working": working})


@router.post("/backup")
async def create_backup(
    body: BackupRequest,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = BackupService.create_backup(db, triggered_by=_.id, notes=body.notes or "")
    return success_response(result)


@router.get("/backups")
async def list_backups(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = BackupService.get_backups(db, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.post("/backup/{backup_id}/restore")
async def restore_backup(
    backup_id: str,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = BackupService.restore_backup(db, backup_id, triggered_by=_.id)
    return success_response(result)


@router.post("/backup/cleanup")
async def cleanup_old_backups(
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    removed = BackupService.cleanup_old_backups(db)
    return success_response({"removed": removed})


@router.post("/dr/test")
async def run_dr_test(
    body: DRTestRequest,
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    result = DisasterRecoveryService.run_test(db, test_type=body.test_type, triggered_by=_.id)
    return success_response(result)


@router.get("/dr/tests")
async def get_dr_test_history(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    items, total = DisasterRecoveryService.get_test_history(db, page, per_page)
    return success_response({"items": items, "total": total, "page": page, "per_page": per_page})


@router.get("/dr/status")
async def get_dr_status(
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    status = DisasterRecoveryService.get_dr_status(db)
    return success_response(status)


@router.get("/push/onesignal/status")
async def check_onesignal(
    _: User = Depends(get_current_admin),
):
    return success_response({
        "configured": onesignal_client.is_configured(),
    })


@router.post("/push/onesignal/test")
async def test_onesignal(
    body: OneSignalTestRequest,
    _: User = Depends(get_current_admin),
):
    result = await onesignal_client.send_notification([body.player_id], body.title, body.body)
    return success_response(result)


@router.get("/telegram/bot/status")
async def check_telegram_bot(
    _: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    bot = TelegramBotClient()
    me = await bot.get_me()
    webhook = await bot.get_webhook_info()
    return success_response({
        "configured": bot.is_configured(),
        "bot_info": me,
        "webhook": webhook,
    })


@router.post("/telegram/bot/test")
async def test_telegram_bot(
    body: TelegramTestRequest,
    _: User = Depends(get_current_admin),
):
    bot = TelegramBotClient()
    result = await bot.send_message(body.chat_id, body.message)
    return success_response(result)
