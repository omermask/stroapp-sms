from pydantic import BaseModel, Field


class UserBanRequest(BaseModel):
    reason: str = Field(default="", max_length=500)


class UserAdjustCoinsRequest(BaseModel):
    amount: int = Field(..., description="Can be negative for deduction")
    reason: str = Field(default="", max_length=500)


class UserChangeTierRequest(BaseModel):
    tier: str = Field(..., pattern="^(freemium|basic|premium|enterprise)$")


class ProviderToggleRequest(BaseModel):
    is_active: bool


class SettingsUpdateRequest(BaseModel):
    key: str
    value: str | int | float | bool | list | dict


class BroadcastRequest(BaseModel):
    title: str = Field(..., max_length=200)
    body: str = Field(default="", max_length=2000)
    type: str = Field(default="broadcast", max_length=50)
