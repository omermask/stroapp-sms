"""phase8_analytics_tables

Revision ID: e5f6a7b8c9d0
Revises: d4e5f6a7b8c9
Create Date: 2026-06-22 09:50:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'e5f6a7b8c9d0'
down_revision: Union[str, Sequence[str], None] = 'd4e5f6a7b8c9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table('daily_user_snapshots',
        sa.Column('snapshot_date', sa.Date(), nullable=False),
        sa.Column('total_users', sa.Integer(), nullable=True),
        sa.Column('new_users', sa.Integer(), nullable=True),
        sa.Column('active_users_24h', sa.Integer(), nullable=True),
        sa.Column('active_users_7d', sa.Integer(), nullable=True),
        sa.Column('active_users_30d', sa.Integer(), nullable=True),
        sa.Column('total_verifications', sa.Integer(), nullable=True),
        sa.Column('successful_verifications', sa.Integer(), nullable=True),
        sa.Column('failed_verifications', sa.Integer(), nullable=True),
        sa.Column('total_revenue', sa.Float(), nullable=True),
        sa.Column('daily_revenue', sa.Float(), nullable=True),
        sa.Column('refund_amount', sa.Float(), nullable=True),
        sa.Column('freemium_count', sa.Integer(), nullable=True),
        sa.Column('payg_count', sa.Integer(), nullable=True),
        sa.Column('pro_count', sa.Integer(), nullable=True),
        sa.Column('custom_count', sa.Integer(), nullable=True),
        sa.Column('computed_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('snapshot_date'),
    )
    op.create_table('user_analytics_snapshots',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('snapshot_date', sa.Date(), nullable=False),
        sa.Column('total_verifications', sa.Integer(), nullable=True),
        sa.Column('successful_verifications', sa.Integer(), nullable=True),
        sa.Column('total_spent', sa.Float(), nullable=True),
        sa.Column('avg_cost', sa.Float(), nullable=True),
        sa.Column('success_rate', sa.Float(), nullable=True),
        sa.Column('top_service', sa.String(), nullable=True),
        sa.Column('top_country', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'snapshot_date', name='uq_user_snapshot_date'),
    )
    op.create_index(op.f('ix_user_analytics_snapshots_user_id'), 'user_analytics_snapshots', ['user_id'], unique=False)
    op.create_table('verification_statistics',
        sa.Column('stat_date', sa.Date(), nullable=False),
        sa.Column('total_verifications', sa.Integer(), nullable=True),
        sa.Column('successful_verifications', sa.Integer(), nullable=True),
        sa.Column('failed_verifications', sa.Integer(), nullable=True),
        sa.Column('total_revenue', sa.Float(), nullable=True),
        sa.Column('avg_cost', sa.Float(), nullable=True),
        sa.Column('unique_users', sa.Integer(), nullable=True),
        sa.Column('top_service', sa.String(), nullable=True),
        sa.Column('top_country', sa.String(), nullable=True),
        sa.Column('top_provider', sa.String(), nullable=True),
        sa.Column('computed_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('stat_date'),
    )
    op.create_table('carrier_analytics',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('verification_id', sa.String(), nullable=True),
        sa.Column('user_id', sa.String(), nullable=True),
        sa.Column('requested_carrier', sa.String(), nullable=True),
        sa.Column('normalized_carrier', sa.String(), nullable=True),
        sa.Column('assigned_phone', sa.String(), nullable=True),
        sa.Column('outcome', sa.String(), nullable=True),
        sa.Column('exact_match', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['verification_id'], ['sms_orders.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_table('monthly_targets',
        sa.Column('month', sa.String(), nullable=False),
        sa.Column('target_new_users', sa.Integer(), nullable=True),
        sa.Column('target_revenue', sa.Float(), nullable=True),
        sa.Column('target_verifications', sa.Integer(), nullable=True),
        sa.Column('target_success_rate', sa.Float(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('month'),
    )
    op.create_table('custom_reports',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('report_name', sa.String(), nullable=False),
        sa.Column('report_type', sa.String(), nullable=False),
        sa.Column('filters', sa.JSON(), nullable=True),
        sa.Column('schedule', sa.String(), nullable=True),
        sa.Column('next_run', sa.DateTime(timezone=True), nullable=True),
        sa.Column('enabled', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_table('scheduled_reports',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('report_id', sa.String(), nullable=True),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('report_data', sa.JSON(), nullable=True),
        sa.Column('file_path', sa.String(), nullable=True),
        sa.Column('generated_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('sent_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('status', sa.String(), nullable=True),
        sa.ForeignKeyConstraint(['report_id'], ['custom_reports.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_table('purchase_outcomes',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('verification_id', sa.String(), nullable=True),
        sa.Column('user_id', sa.String(), nullable=True),
        sa.Column('service', sa.String(), nullable=False),
        sa.Column('provider', sa.String(), nullable=False),
        sa.Column('country', sa.String(), nullable=False),
        sa.Column('assigned_code', sa.String(), nullable=True),
        sa.Column('assigned_carrier', sa.String(), nullable=True),
        sa.Column('carrier_type', sa.String(), nullable=True),
        sa.Column('matched', sa.Boolean(), nullable=True),
        sa.Column('sms_received', sa.Boolean(), nullable=True),
        sa.Column('is_refunded', sa.Boolean(), nullable=True),
        sa.Column('provider_cost', sa.Float(), nullable=True),
        sa.Column('user_price', sa.Float(), nullable=True),
        sa.Column('profit', sa.Float(), nullable=True),
        sa.Column('latency_seconds', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['verification_id'], ['sms_orders.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )


def downgrade() -> None:
    op.drop_table('purchase_outcomes')
    op.drop_table('scheduled_reports')
    op.drop_table('custom_reports')
    op.drop_table('monthly_targets')
    op.drop_table('carrier_analytics')
    op.drop_table('verification_statistics')
    op.drop_index(op.f('ix_user_analytics_snapshots_user_id'), table_name='user_analytics_snapshots')
    op.drop_table('user_analytics_snapshots')
    op.drop_table('daily_user_snapshots')
