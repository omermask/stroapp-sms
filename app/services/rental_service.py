from datetime import datetime, timezone, timedelta

from sqlalchemy.orm import Session

from app.core.config import get_settings, get_app_setting
from app.core.exceptions import AppException
from app.domain.models import NumberRental, User, gen_uuid
from app.infrastructure.providers import ProviderRouter
from app.services.audit_service import AuditService
from app.services.notification_service import NotificationService

provider_router = ProviderRouter()


class RentalService:
    def __init__(self, db: Session):
        self.db = db
        self.settings = get_settings()
        self.coins_per_usd = get_app_setting(db, "coins_per_usd", self.settings.coins_per_usd)
        self.default_markup = get_app_setting(db, "default_markup", self.settings.default_markup)

    async def get_rental_providers(self):
        return [p for p in provider_router.enabled_providers if p.supports_rentals]

    async def calculate_cost(self, price: float, hours: int) -> int:
        # C-3 FIX: التحقق من صحة البيانات لمنع الحساب الخاطئ (price=0 تعني الحصول على رقم مجاناً)
        if hours <= 0:
            raise AppException("VALIDATION_ERROR", "عدد الساعات يجب أن يكون أكبر من صفر", 400)
        if price <= 0:
            raise AppException("PROVIDER_ERROR", "سعر غير صالح من المزود", 502)
        markup = self.default_markup
        hourly_rate = price / 24
        cost = int(hourly_rate * hours * markup * self.coins_per_usd)
        return max(1, cost)  # ضمان ألا يكون التكلفة صفراً أبداً

    async def create_rental(self, user_id: str, service: str, country: str, hours: int, auto_extend: bool) -> dict:
        providers = await self.get_rental_providers()
        if not providers:
            raise AppException("SERVICE_UNAVAILABLE", "لا يوجد مزيد يدعم الإيجار حالياً", 503)

        best_provider = None
        best_price = None
        for p in providers:
            try:
                price = await p.get_price(service, country)
                if best_price is None or price < best_price:
                    best_price = price
                    best_provider = p
            except Exception:
                continue

        if not best_provider or best_price is None:
            raise AppException("SERVICE_UNAVAILABLE", "هذه الخدمة غير متاحة للإيجار حالياً", 404)

        cost_coins = await self.calculate_cost(best_price, hours)
        # C-1 FIX: قفل صف المستخدم لمنع Race Condition في خصم الرصيد
        user = self.db.query(User).filter(User.id == user_id).with_for_update().first()
        if not user:
            raise AppException("NOT_FOUND", "المستخدم غير موجود", 404)
        if user.coins < cost_coins:
            raise AppException("INSUFFICIENT_BALANCE", "رصيدك غير كافٍ", 402)

        try:
            result = await best_provider.purchase_number(service, country)
        except Exception as e:
            self.db.rollback()
            raise AppException("PROVIDER_ERROR", "عذراً، المزود غير متاح حالياً، يرجى المحاولة لاحقاً", 502)

        user.coins -= cost_coins
        expires_at = datetime.now(timezone.utc) + timedelta(hours=hours)

        rental = NumberRental(
            id=gen_uuid(),
            user_id=user_id,
            service=service,
            country=country,
            provider=best_provider.name,
            phone_number=result.phone_number,
            activation_id=result.order_id,
            status="active",
            duration_hours=hours,
            cost_coins=cost_coins,
            auto_extend=auto_extend,
            expires_at=expires_at,
        )
        self.db.add(rental)
        self.db.commit()

        AuditService.log(self.db, user_id, "rental.create", "number_rental", rental.id,
                       {"service": service, "country": country, "provider": best_provider.name,
                        "hours": hours, "cost_coins": cost_coins}, "", "")

        notif = NotificationService(self.db)
        await notif.notify(user_id, "rental.created", "تم إنشاء الإيجار",
                          f"تم استئجار رقم {result.phone_number} لمدة {hours} ساعة",
                          {"rental_id": rental.id})

        return {
            "id": rental.id,
            "phone_number": result.phone_number,
            "service": service,
            "country": country,
            "provider": best_provider.name,
            "hours": hours,
            "cost_coins": cost_coins,
            "auto_extend": auto_extend,
            "balance": user.coins,
            "expires_at": expires_at.isoformat(),
            "status": "active",
        }

    async def extend_rental(self, rental_id: str, user_id: str, extra_hours: int) -> dict:
        rental = self.db.query(NumberRental).filter(
            NumberRental.id == rental_id,
            NumberRental.user_id == user_id,
            NumberRental.status == "active",
        ).first()
        if not rental:
            raise AppException("NOT_FOUND", "الإيجار غير موجود أو منتهي", 404)

        providers = await self.get_rental_providers()
        best_provider = None
        for p in providers:
            if p.name == rental.provider:
                best_provider = p
                break
        if not best_provider:
            raise AppException("PROVIDER_ERROR", "المزود غير متاح حالياً", 503)

        price = await best_provider.get_price(rental.service, rental.country)
        extra_coins = await self.calculate_cost(price, extra_hours)
        # C-1 FIX: قفل صف المستخدم لمنع Race Condition
        user = self.db.query(User).filter(User.id == user_id).with_for_update().first()
        if not user:
            raise AppException("NOT_FOUND", "المستخدم غير موجود", 404)
        if user.coins < extra_coins:
            raise AppException("INSUFFICIENT_BALANCE", "رصيدك غير كافٍ للتمديد", 402)

        user.coins -= extra_coins
        rental.expires_at = rental.expires_at + timedelta(hours=extra_hours)
        rental.duration_hours += extra_hours
        rental.cost_coins += extra_coins
        self.db.commit()

        AuditService.log(self.db, user_id, "rental.extend", "number_rental", rental.id,
                       {"extra_hours": extra_hours, "extra_coins": extra_coins}, "", "")

        return {
            "id": rental.id,
            "expires_at": rental.expires_at.isoformat(),
            "duration_hours": rental.duration_hours,
            "cost_coins": rental.cost_coins,
            "balance": user.coins,
        }

    async def cancel_rental(self, rental_id: str, user_id: str) -> dict:
        rental = self.db.query(NumberRental).filter(
            NumberRental.id == rental_id,
            NumberRental.user_id == user_id,
            NumberRental.status == "active",
        ).with_for_update().first()  # C-2 style FIX: قفل صف الإيجار لمنع الإلغاء المزدوج
        if not rental:
            raise AppException("NOT_FOUND", "الإيجار غير موجود أو منتهي بالفعل", 404)

        total_hours = (datetime.now(timezone.utc) - rental.created_at).total_seconds() / 3600
        used_hours = min(total_hours, rental.duration_hours)
        remaining_hours = rental.duration_hours - used_hours
        refund_ratio = remaining_hours / rental.duration_hours if rental.duration_hours > 0 else 0
        refund_coins = int(rental.cost_coins * refund_ratio)

        # C-1 FIX: قفل صف المستخدم عند استرداد الكوينز
        user = self.db.query(User).filter(User.id == user_id).with_for_update().first()
        if not user:
            raise AppException("NOT_FOUND", "المستخدم غير موجود", 404)
        user.coins += refund_coins
        rental.status = "cancelled"
        rental.cancelled_at = datetime.now(timezone.utc)

        # M-1 FIX: إخطار المزود بالإلغاء لإيقاف تحصيل الرسوم على الرقم المال مجاناً
        providers = await self.get_rental_providers()
        for p in providers:
            if p.name == rental.provider:
                try:
                    if hasattr(p, "cancel") and rental.activation_id:
                        await p.cancel(rental.activation_id)
                except Exception as e:
                    import logging
                    logging.getLogger(__name__).warning(
                        f"Provider cancel failed for rental {rental.id}: {e}"
                    )
                break

        self.db.commit()

        AuditService.log(self.db, user_id, "rental.cancel", "number_rental", rental.id,
                       {"refund_coins": refund_coins, "used_hours": used_hours}, "", "")

        return {
            "id": rental.id,
            "status": "cancelled",
            "refund_coins": refund_coins,
            "balance": user.coins,
        }

    def get_user_rentals(self, user_id: str, status: str = ""):
        query = self.db.query(NumberRental).filter(NumberRental.user_id == user_id)
        if status:
            query = query.filter(NumberRental.status == status)
        return query.order_by(NumberRental.created_at.desc()).all()

    async def get_rental_messages(self, rental_id: str, user_id: str) -> list[dict]:
        rental = self.db.query(NumberRental).filter(
            NumberRental.id == rental_id,
            NumberRental.user_id == user_id,
        ).first()
        if not rental:
            raise AppException("NOT_FOUND", "الإيجار غير موجود", 404)

        providers = await self.get_rental_providers()
        for p in providers:
            if p.name == rental.provider and rental.activation_id:
                try:
                    messages = await p.check_messages(rental.activation_id)
                    result = []
                    for msg in messages:
                        result.append({
                            "id": str(len(result) + 1),
                            "text": msg.text,
                            "code": msg.code,
                            "created_at": msg.received_at or "",
                        })
                    rental.messages_count = len(result)
                    self.db.commit()
                    return result
                except Exception:
                    pass
                break
        return []

    async def get_available_countries(self) -> list[dict]:
        providers = await self.get_rental_providers()
        seen = set()
        result = []
        for p in providers:
            try:
                pcountries = await p.get_countries()
                for c in pcountries:
                    code = (c.get("code") or c.get("short_name", "")).upper()
                    name = c.get("name", "") or code
                    if code and code not in seen:
                        seen.add(code)
                        result.append({"code": code, "name": name})
            except Exception:
                continue
        return result

    async def get_available_services(self, country: str) -> list[dict]:
        providers = await self.get_rental_providers()
        seen = set()
        result = []
        for p in providers:
            try:
                pservices = await p.get_services(country)
                for s in pservices:
                    if s.service_id not in seen:
                        seen.add(s.service_id)
                        result.append({
                            "id": s.service_id,
                            "name": s.service_name,
                            "cost": s.cost,
                            "stock": s.count,
                        })
            except Exception:
                continue
        return result
