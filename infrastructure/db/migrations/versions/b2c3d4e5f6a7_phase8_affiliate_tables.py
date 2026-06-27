"""phase8_affiliate_tables

Revision ID: b2c3d4e5f6a7
Revises: a1b2c3d4e5f6
Create Date: 2026-06-22 09:35:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'b2c3d4e5f6a7'
down_revision: Union[str, Sequence[str], None] = 'a1b2c3d4e5f6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('users', sa.Column('is_affiliate', sa.Boolean(), nullable=True))

    op.create_table('affiliate_applications',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('program_type', sa.String(), nullable=False),
        sa.Column('message', sa.Text(), nullable=True),
        sa.Column('status', sa.String(), nullable=True),
        sa.Column('reviewed_by', sa.String(), nullable=True),
        sa.Column('reviewed_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('rejection_reason', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_affiliate_applications_user_id'), 'affiliate_applications', ['user_id'], unique=False)

    op.create_table('affiliate_commissions',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('affiliate_id', sa.String(), nullable=False),
        sa.Column('transaction_id', sa.String(), nullable=True),
        sa.Column('order_id', sa.String(), nullable=True),
        sa.Column('referred_user_id', sa.String(), nullable=True),
        sa.Column('amount', sa.Float(), nullable=False),
        sa.Column('commission_rate', sa.Float(), nullable=False),
        sa.Column('status', sa.String(), nullable=True),
        sa.Column('payout_id', sa.String(), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('paid_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['affiliate_id'], ['users.id'], ),
        sa.ForeignKeyConstraint(['transaction_id'], ['transactions.id'], ),
        sa.ForeignKeyConstraint(['order_id'], ['sms_orders.id'], ),
        sa.ForeignKeyConstraint(['referred_user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_affiliate_commissions_affiliate_id'), 'affiliate_commissions', ['affiliate_id'], unique=False)

    op.create_table('commission_tiers',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('name', sa.String(), nullable=False),
        sa.Column('base_rate', sa.Float(), nullable=False),
        sa.Column('bonus_rate', sa.Float(), nullable=True),
        sa.Column('min_volume_usd', sa.Float(), nullable=True),
        sa.Column('min_referrals', sa.Integer(), nullable=True),
        sa.Column('requirements', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('name'),
    )

    op.create_table('payout_requests',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('affiliate_id', sa.String(), nullable=False),
        sa.Column('amount', sa.Float(), nullable=False),
        sa.Column('currency', sa.String(), nullable=True),
        sa.Column('payment_method', sa.String(), nullable=False),
        sa.Column('payment_details', sa.JSON(), nullable=True),
        sa.Column('status', sa.String(), nullable=True),
        sa.Column('processed_by', sa.String(), nullable=True),
        sa.Column('processed_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['affiliate_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_payout_requests_affiliate_id'), 'payout_requests', ['affiliate_id'], unique=False)

    op.create_table('revenue_shares',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('partner_id', sa.String(), nullable=False),
        sa.Column('transaction_id', sa.String(), nullable=True),
        sa.Column('revenue_amount', sa.Float(), nullable=False),
        sa.Column('commission_rate', sa.Float(), nullable=False),
        sa.Column('commission_amount', sa.Float(), nullable=False),
        sa.Column('tier_name', sa.String(), nullable=True),
        sa.Column('status', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['partner_id'], ['users.id'], ),
        sa.ForeignKeyConstraint(['transaction_id'], ['transactions.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )


def downgrade() -> None:
    op.drop_table('revenue_shares')
    op.drop_index(op.f('ix_payout_requests_affiliate_id'), table_name='payout_requests')
    op.drop_table('payout_requests')
    op.drop_table('commission_tiers')
    op.drop_index(op.f('ix_affiliate_commissions_affiliate_id'), table_name='affiliate_commissions')
    op.drop_table('affiliate_commissions')
    op.drop_index(op.f('ix_affiliate_applications_user_id'), table_name='affiliate_applications')
    op.drop_table('affiliate_applications')
    op.drop_column('users', 'is_affiliate')
