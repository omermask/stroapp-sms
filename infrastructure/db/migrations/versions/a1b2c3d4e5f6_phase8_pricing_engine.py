"""phase8_pricing_engine

Revision ID: a1b2c3d4e5f6
Revises: 8d4e6f2a1c3b
Create Date: 2026-06-22 09:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, Sequence[str], None] = '8d4e6f2a1c3b'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table('pricing_templates',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('name', sa.String(), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('markup_multiplier', sa.Float(), nullable=True),
        sa.Column('discount_percentage', sa.Float(), nullable=True),
        sa.Column('region', sa.String(), nullable=True),
        sa.Column('currency', sa.String(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('is_promo', sa.Boolean(), nullable=True),
        sa.Column('promo_code', sa.String(), nullable=True),
        sa.Column('promo_max_uses', sa.Integer(), nullable=True),
        sa.Column('promo_used_count', sa.Integer(), nullable=True),
        sa.Column('promo_expires_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('effective_date', sa.DateTime(timezone=True), nullable=False),
        sa.Column('max_assignments', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('name'),
        sa.UniqueConstraint('promo_code'),
    )
    op.create_table('tier_pricing',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('template_id', sa.String(), nullable=False),
        sa.Column('tier_name', sa.String(), nullable=False),
        sa.Column('monthly_price', sa.Float(), nullable=True),
        sa.Column('included_quota_usd', sa.Float(), nullable=True),
        sa.Column('overage_rate', sa.Float(), nullable=True),
        sa.Column('features', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['template_id'], ['pricing_templates.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_table('pricing_history',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('template_id', sa.String(), nullable=False),
        sa.Column('action', sa.String(), nullable=False),
        sa.Column('changed_by', sa.String(), nullable=False),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('snapshot_before', sa.JSON(), nullable=True),
        sa.Column('snapshot_after', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['template_id'], ['pricing_templates.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_table('user_pricing_assignments',
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('template_id', sa.String(), nullable=False),
        sa.Column('assigned_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.ForeignKeyConstraint(['template_id'], ['pricing_templates.id'], ),
        sa.PrimaryKeyConstraint('user_id'),
    )
    op.create_table('service_promotions',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('service', sa.String(), nullable=False),
        sa.Column('country', sa.String(), nullable=True),
        sa.Column('discount_percentage', sa.Float(), nullable=False),
        sa.Column('original_price', sa.Float(), nullable=False),
        sa.Column('promotional_price', sa.Float(), nullable=False),
        sa.Column('max_uses', sa.Integer(), nullable=True),
        sa.Column('used_count', sa.Integer(), nullable=True),
        sa.Column('starts_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_table('promo_code_usages',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('template_id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('order_id', sa.String(), nullable=True),
        sa.Column('discount_amount', sa.Float(), nullable=False),
        sa.Column('original_amount', sa.Float(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['template_id'], ['pricing_templates.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.ForeignKeyConstraint(['order_id'], ['sms_orders.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )


def downgrade() -> None:
    op.drop_table('promo_code_usages')
    op.drop_table('service_promotions')
    op.drop_table('user_pricing_assignments')
    op.drop_table('pricing_history')
    op.drop_table('tier_pricing')
    op.drop_table('pricing_templates')
