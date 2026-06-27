from datetime import date

from pydantic import BaseModel, Field


class KYCProfileRequest(BaseModel):
    full_name: str = Field(..., max_length=200)
    date_of_birth: date | None = None
    nationality: str | None = Field(default=None, max_length=100)
    phone_number: str | None = Field(default=None, max_length=20)
    address_line1: str | None = Field(default=None, max_length=200)
    city: str | None = Field(default=None, max_length=100)
    country: str | None = Field(default=None, max_length=100)


class KYCProfileResponse(BaseModel):
    id: str
    status: str
    verification_level: str
    full_name: str | None = None
    nationality: str | None = None
    submitted_at: str | None = None
    verified_at: str | None = None
