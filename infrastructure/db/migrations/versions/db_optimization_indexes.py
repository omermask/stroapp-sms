"""add database indexes for performance optimization

Revision ID: db_optimization_indexes
Revises: 9a44318e47bc
Create Date: 2026-06-22
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "db_optimization_indexes"
down_revision: Union[str, None] = "9a44318e47bc"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


INDEXES = [
    # (index_name, table, columns)
    ("ix_sms_orders_user_id_status", "sms_orders", ["user_id", "status"]),
    ("ix_sms_orders_created_at_status", "sms_orders", ["created_at", "status"]),
    ("ix_sms_orders_provider_status", "sms_orders", ["provider", "status"]),
    ("ix_transactions_user_id_type", "transactions", ["user_id", "type"]),
    ("ix_transactions_created_at_type", "transactions", ["created_at", "type"]),
    ("ix_payment_logs_user_id_status", "payment_logs", ["user_id", "status"]),
    ("ix_payment_logs_created_at_status", "payment_logs", ["created_at", "status"]),
    ("ix_audit_logs_action_created", "audit_logs", ["action", "created_at"]),
    ("ix_audit_logs_ip_address", "audit_logs", ["ip_address"]),
    ("ix_notifications_user_id_is_read", "notifications", ["user_id", "is_read"]),
    ("ix_user_sessions_user_id_active", "user_sessions", ["user_id", "is_active"]),
    ("ix_webhook_events_webhook_id_status", "webhook_events", ["webhook_id", "status"]),
    ("ix_activity_feed_user_id_type", "activity_feed", ["user_id", "activity_type"]),
    ("ix_number_rentals_user_id_status", "number_rentals", ["user_id", "status"]),
    ("ix_number_rentals_expires_at_status", "number_rentals", ["expires_at", "status"]),
    ("ix_countries_service_id_provider", "countries", ["service_id", "provider"]),
    ("ix_provider_settlements_provider_name_status", "provider_settlements", ["provider_name", "status"]),
    ("ix_ledger_entries_user_id_currency", "ledger_entries", ["user_id", "currency"]),
    ("ix_security_scan_results_status", "security_scan_results", ["status"]),
    ("ix_invoices_user_id_status", "invoices", ["user_id", "status"]),
]


def upgrade() -> None:
    for name, table, cols in INDEXES:
        try:
            op.create_index(name, table, cols)
        except Exception:
            pass


def downgrade() -> None:
    for name, table, cols in reversed(INDEXES):
        try:
            op.drop_index(name, table_name=table)
        except Exception:
            pass
