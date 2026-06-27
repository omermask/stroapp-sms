from datetime import date

from pydantic import BaseModel, Field


class AnalyticsQuery(BaseModel):
    start_date: date
    end_date: date
    group_by: str = Field(default="day", pattern="^(day|week|month)$")
    metric: str = Field(default="revenue", pattern="^(revenue|orders|users|registrations)$")


class CohortQuery(BaseModel):
    cohort_period: str = Field(default="month", pattern="^(week|month)$")
    lookback_periods: int = Field(default=6, ge=1, le=24)
