from pydantic import BaseModel, Field


class PaymentIntentRequest(BaseModel):
    product_id: str
    provider: str = Field(default="google_play", description="google_play or apple_app_store")


class PaymentReceiptRequest(BaseModel):
    receipt: str = Field(..., description="Base64-encoded receipt data")
    provider: str = Field(default="google_play")
    product_id: str


class PaymentResponse(BaseModel):
    payment_id: str
    coins: int
    amount_usd: float
    status: str


class IAPProduct(BaseModel):
    product_id: str
    amount_usd: float
    coins: int
    label: str
