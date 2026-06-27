"""add service_country sync_log markup_rule tables

Revision ID: 2a3b4c5d6e7f
Revises: 9c75dc80485b
Create Date: 2026-06-24 10:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "2a3b4c5d6e7f"
down_revision: Union[str, None] = "9c75dc80485b"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table("service_countries",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("service", sa.String(), nullable=False, index=True),
        sa.Column("country_code", sa.String(), nullable=False, index=True),
        sa.Column("provider", sa.String(), nullable=False),
        sa.Column("provider_cost", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("available_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("currency", sa.String(), nullable=False, server_default="USD"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("last_synced_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("service", "country_code", "provider", name="uq_service_country_provider"),
    )
    op.create_table("sync_logs",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("sync_type", sa.String(), nullable=False, index=True),
        sa.Column("status", sa.String(), nullable=False, server_default="running"),
        sa.Column("providers_synced", sa.JSON(), nullable=True),
        sa.Column("services_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("countries_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("errors", sa.JSON(), nullable=True),
        sa.Column("duration_seconds", sa.Float(), nullable=True),
        sa.Column("triggered_by", sa.String(), nullable=False, server_default="scheduler"),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table("markup_rules",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("service", sa.String(), nullable=True, index=True),
        sa.Column("country_code", sa.String(), nullable=True, index=True),
        sa.Column("provider", sa.String(), nullable=True),
        sa.Column("user_tier", sa.String(), nullable=True),
        sa.Column("markup_multiplier", sa.Float(), nullable=False, server_default="1.20"),
        sa.Column("priority", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("description", sa.String(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade() -> None:
    op.drop_table("markup_rules")
    op.drop_table("sync_logs")
    op.drop_table("service_countries")
