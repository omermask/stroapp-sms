from pydantic import BaseModel, Field


class PurchaseRequest(BaseModel):
    service: str = Field(..., description="اسم الخدمة")
    country: str = Field(..., description="رمز البلد")


class PurchaseResponse(BaseModel):
    order_id: str
    phone_number: str
    cost_coins: int
    status: str


class OrderStatusResponse(BaseModel):
    order_id: str
    status: str
    phone_number: str | None = None
    verification_code: str | None = None
    sms_text: str | None = None
    created_at: str | None = None


class VoicePurchaseRequest(BaseModel):
    service: str
    country: str


class RentalRequest(BaseModel):
    service: str
    country: str
    duration_hours: int = Field(default=24, ge=1, le=720)
    auto_extend: bool = False
