from datetime import date, datetime, timedelta, timezone
from typing import Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.domain.models import (
    CarrierAnalytics,
    CustomReport,
    DailyUserSnapshot,
    MonthlyTarget,
    PurchaseOutcome,
    SMSOrder,
    ScheduledReport,
    Transaction,
    User,
    UserAnalyticsSnapshot,
    VerificationStatistics,
    gen_uuid,
)


class AnalyticsService:
    @staticmethod
    def compute_daily_snapshot(db: Session, snapshot_date: Optional[date] = None) -> dict:
        target_date = snapshot_date or date.today()
        start_dt = datetime.combine(target_date, datetime.min.time()).replace(tzinfo=timezone.utc)
        end_dt = start_dt + timedelta(days=1)

        total_users = db.query(func.count(User.id)).scalar() or 0
        new_users = db.query(func.count(User.id)).filter(
            User.created_at >= start_dt, User.created_at < end_dt,
        ).scalar() or 0

        since_24h = datetime.now(timezone.utc) - timedelta(hours=24)
        since_7d = datetime.now(timezone.utc) - timedelta(days=7)
        since_30d = datetime.now(timezone.utc) - timedelta(days=30)

        active_24h = db.query(func.count(func.distinct(SMSOrder.user_id))).filter(
            SMSOrder.created_at >= since_24h,
        ).scalar() or 0
        active_7d = db.query(func.count(func.distinct(SMSOrder.user_id))).filter(
            SMSOrder.created_at >= since_7d,
        ).scalar() or 0
        active_30d = db.query(func.count(func.distinct(SMSOrder.user_id))).filter(
            SMSOrder.created_at >= since_30d,
        ).scalar() or 0

        verifications = db.query(func.count(SMSOrder.id)).filter(
            SMSOrder.created_at >= start_dt, SMSOrder.created_at < end_dt,
        ).scalar() or 0
        successful = db.query(func.count(SMSOrder.id)).filter(
            SMSOrder.created_at >= start_dt, SMSOrder.created_at < end_dt,
            SMSOrder.status == "completed",
        ).scalar() or 0
        failed = verifications - successful

        total_revenue = db.query(func.coalesce(func.sum(Transaction.amount), 0)).filter(
            Transaction.type == "purchase",
        ).scalar() or 0
        daily_revenue = db.query(func.coalesce(func.sum(Transaction.amount), 0)).filter(
            Transaction.type == "purchase",
            Transaction.created_at >= start_dt,
            Transaction.created_at < end_dt,
        ).scalar() or 0

        refund_amount = db.query(func.coalesce(func.sum(func.abs(Transaction.amount)), 0)).filter(
            Transaction.type == "refund",
            Transaction.created_at >= start_dt,
            Transaction.created_at < end_dt,
        ).scalar() or 0

        freemium = db.query(func.count(User.id)).filter(User.tier == "freemium").scalar() or 0
        payg = db.query(func.count(User.id)).filter(User.tier == "payg").scalar() or 0
        pro = db.query(func.count(User.id)).filter(User.tier == "pro").scalar() or 0
        custom = db.query(func.count(User.id)).filter(User.tier == "custom").scalar() or 0

        existing = db.query(DailyUserSnapshot).filter(
            DailyUserSnapshot.snapshot_date == target_date,
        ).first()
        if existing:
            existing.total_users = total_users
            existing.new_users = new_users
            existing.active_users_24h = active_24h
            existing.active_users_7d = active_7d
            existing.active_users_30d = active_30d
            existing.total_verifications = verifications
            existing.successful_verifications = successful
            existing.failed_verifications = failed
            existing.total_revenue = total_revenue
            existing.daily_revenue = daily_revenue
            existing.refund_amount = refund_amount
            existing.freemium_count = freemium
            existing.payg_count = payg
            existing.pro_count = pro
            existing.custom_count = custom
        else:
            db.add(DailyUserSnapshot(
                snapshot_date=target_date,
                total_users=total_users, new_users=new_users,
                active_users_24h=active_24h, active_users_7d=active_7d, active_users_30d=active_30d,
                total_verifications=verifications, successful_verifications=successful,
                failed_verifications=failed, total_revenue=total_revenue, daily_revenue=daily_revenue,
                refund_amount=refund_amount, freemium_count=freemium, payg_count=payg,
                pro_count=pro, custom_count=custom,
            ))
        db.commit()
        return {
            "snapshot_date": target_date.isoformat(),
            "total_users": total_users,
            "new_users": new_users,
            "revenue": {"total": total_revenue, "daily": daily_revenue, "refunds": refund_amount},
        }

    @staticmethod
    def get_dashboard(db: Session) -> dict:
        today = date.today()
        snapshot = db.query(DailyUserSnapshot).filter(
            DailyUserSnapshot.snapshot_date == today,
        ).first()
        if not snapshot:
            AnalyticsService.compute_daily_snapshot(db, today)
            snapshot = db.query(DailyUserSnapshot).filter(
                DailyUserSnapshot.snapshot_date == today,
            ).first()

        recent_snapshots = db.query(DailyUserSnapshot).order_by(
            DailyUserSnapshot.snapshot_date.desc(),
        ).limit(30).all()

        user_count = db.query(func.count(User.id)).scalar() or 0
        order_count = db.query(func.count(SMSOrder.id)).scalar() or 0
        revenue = db.query(func.coalesce(func.sum(Transaction.amount), 0)).filter(
            Transaction.type == "purchase",
        ).scalar() or 0

        return {
            "today": {
                "new_users": snapshot.new_users if snapshot else 0,
                "verifications": snapshot.total_verifications if snapshot else 0,
                "revenue": snapshot.daily_revenue if snapshot else 0,
            },
            "totals": {
                "users": user_count,
                "orders": order_count,
                "revenue": revenue,
            },
            "trend": [
                {
                    "date": s.snapshot_date.isoformat(),
                    "users": s.total_users,
                    "new_users": s.new_users,
                    "verifications": s.total_verifications,
                    "revenue": s.daily_revenue,
                }
                for s in recent_snapshots
            ],
        }

    @staticmethod
    def get_user_snapshot(db: Session, user_id: str) -> dict:
        snapshots = db.query(UserAnalyticsSnapshot).filter(
            UserAnalyticsSnapshot.user_id == user_id,
        ).order_by(UserAnalyticsSnapshot.snapshot_date.desc()).limit(30).all()

        total_orders = db.query(func.count(SMSOrder.id)).filter(SMSOrder.user_id == user_id).scalar() or 0
        successful = db.query(func.count(SMSOrder.id)).filter(
            SMSOrder.user_id == user_id, SMSOrder.status == "completed",
        ).scalar() or 0
        total_spent = db.query(func.coalesce(func.sum(func.abs(Transaction.amount)), 0)).filter(
            Transaction.user_id == user_id, Transaction.type == "purchase",
        ).scalar() or 0

        return {
            "totals": {
                "total_orders": total_orders,
                "successful_orders": successful,
                "total_spent": total_spent,
                "success_rate": round((successful / total_orders * 100) if total_orders > 0 else 0, 2),
            },
            "daily": [
                {
                    "date": s.snapshot_date.isoformat(),
                    "verifications": s.total_verifications,
                    "spent": s.total_spent,
                    "success_rate": s.success_rate,
                }
                for s in snapshots
            ],
        }

    @staticmethod
    def get_verification_stats(db: Session, days: int = 30) -> dict:
        since = datetime.now(timezone.utc) - timedelta(days=days)
        stats = db.query(VerificationStatistics).filter(
            VerificationStatistics.stat_date >= since.date(),
        ).order_by(VerificationStatistics.stat_date).all()

        total_orders = db.query(func.count(SMSOrder.id)).filter(
            SMSOrder.created_at >= since,
        ).scalar() or 0
        successful = db.query(func.count(SMSOrder.id)).filter(
            SMSOrder.created_at >= since, SMSOrder.status == "completed",
        ).scalar() or 0
        failed = total_orders - successful

        return {
            "period_days": days,
            "totals": {
                "total": total_orders,
                "successful": successful,
                "failed": failed,
                "success_rate": round((successful / total_orders * 100) if total_orders > 0 else 0, 2),
            },
            "daily": [
                {
                    "date": s.stat_date.isoformat(),
                    "total": s.total_verifications,
                    "successful": s.successful_verifications,
                    "failed": s.failed_verifications,
                    "revenue": s.total_revenue,
                }
                for s in stats
            ],
        }

    @staticmethod
    def get_carrier_analytics(db: Session, days: int = 30) -> dict:
        since = datetime.now(timezone.utc) - timedelta(days=days)
        items = db.query(CarrierAnalytics).filter(
            CarrierAnalytics.created_at >= since,
        ).all()

        by_carrier = {}
        for item in items:
            key = item.normalized_carrier or item.requested_carrier or "unknown"
            if key not in by_carrier:
                by_carrier[key] = {"total": 0, "success": 0, "exact_match": 0}
            by_carrier[key]["total"] += 1
            if item.outcome == "success":
                by_carrier[key]["success"] += 1
            if item.exact_match:
                by_carrier[key]["exact_match"] += 1

        result = []
        for carrier, data in sorted(by_carrier.items(), key=lambda x: x[1]["total"], reverse=True):
            result.append({
                "carrier": carrier,
                "total": data["total"],
                "success": data["success"],
                "exact_match": data["exact_match"],
                "success_rate": round((data["success"] / data["total"] * 100) if data["total"] > 0 else 0, 2),
            })
        return {"carriers": result}

    @staticmethod
    def get_monthly_targets(db: Session) -> list[dict]:
        targets = db.query(MonthlyTarget).order_by(MonthlyTarget.month.desc()).all()
        return [
            {
                "month": t.month,
                "target_new_users": t.target_new_users,
                "target_revenue": t.target_revenue,
                "target_verifications": t.target_verifications,
                "target_success_rate": t.target_success_rate,
                "is_active": t.is_active,
                "notes": t.notes,
            }
            for t in targets
        ]

    @staticmethod
    def set_monthly_target(db: Session, data: dict) -> dict:
        month = data["month"]
        existing = db.query(MonthlyTarget).filter(MonthlyTarget.month == month).first()
        if existing:
            updatable = ["target_new_users", "target_revenue", "target_verifications", "target_success_rate", "notes"]
            for key in updatable:
                if key in data:
                    setattr(existing, key, data[key])
            db.commit()
            return {"month": month, "message": "تم تحديث الهدف"}
        target = MonthlyTarget(
            month=month,
            target_new_users=data.get("target_new_users", 0),
            target_revenue=data.get("target_revenue", 0.0),
            target_verifications=data.get("target_verifications", 0),
            target_success_rate=data.get("target_success_rate", 0.0),
            notes=data.get("notes"),
        )
        db.add(target)
        db.commit()
        return {"month": month, "message": "تم إنشاء الهدف"}

    @staticmethod
    def get_purchase_outcomes(db: Session, page: int = 1, per_page: int = 20, days: int = 7) -> tuple[list[dict], int]:
        since = datetime.now(timezone.utc) - timedelta(days=days)
        query = db.query(PurchaseOutcome).filter(PurchaseOutcome.created_at >= since)
        total = query.count()
        items = query.order_by(PurchaseOutcome.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
        return [
            {
                "id": p.id,
                "service": p.service,
                "provider": p.provider,
                "country": p.country,
                "matched": p.matched,
                "sms_received": p.sms_received,
                "is_refunded": p.is_refunded,
                "provider_cost": p.provider_cost,
                "user_price": p.user_price,
                "profit": p.profit,
                "latency_seconds": p.latency_seconds,
                "created_at": p.created_at.isoformat(),
            }
            for p in items
        ], total

    @staticmethod
    def create_custom_report(db: Session, user_id: str, data: dict) -> dict:
        report = CustomReport(
            id=gen_uuid(),
            user_id=user_id,
            report_name=data["report_name"],
            report_type=data.get("report_type", "verifications"),
            filters=data.get("filters", {}),
            schedule=data.get("schedule"),
        )
        db.add(report)
        db.commit()
        db.refresh(report)
        return {"id": report.id, "report_name": report.report_name, "next_run": report.next_run}

    @staticmethod
    def get_custom_reports(db: Session, user_id: str) -> list[dict]:
        reports = db.query(CustomReport).filter(CustomReport.user_id == user_id).order_by(CustomReport.created_at.desc()).all()
        return [
            {
                "id": r.id,
                "report_name": r.report_name,
                "report_type": r.report_type,
                "filters": r.filters,
                "schedule": r.schedule,
                "next_run": r.next_run.isoformat() if r.next_run else None,
                "enabled": r.enabled,
            }
            for r in reports
        ]
