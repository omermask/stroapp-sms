"""phase8_reseller_tables

Revision ID: c3d4e5f6a7b8
Revises: b2c3d4e5f6a7
Create Date: 2026-06-22 09:40:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'c3d4e5f6a7b8'
down_revision: Union[str, Sequence[str], None] = 'b2c3d4e5f6a7'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table('reseller_accounts',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('tier', sa.String(), nullable=True),
        sa.Column('volume_discount', sa.Float(), nullable=True),
        sa.Column('custom_markup', sa.Float(), nullable=True),
        sa.Column('credit_limit', sa.Float(), nullable=True),
        sa.Column('auto_topup_enabled', sa.Boolean(), nullable=True),
        sa.Column('auto_topup_threshold', sa.Float(), nullable=True),
        sa.Column('auto_topup_amount', sa.Float(), nullable=True),
        sa.Column('total_purchased', sa.Float(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id'),
    )
    op.create_table('sub_accounts',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('reseller_account_id', sa.String(), nullable=False),
        sa.Column('name', sa.String(), nullable=False),
        sa.Column('email', sa.String(), nullable=False),
        sa.Column('coins', sa.Float(), nullable=True),
        sa.Column('usage_limit', sa.Float(), nullable=True),
        sa.Column('rate_multiplier', sa.Float(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('last_used_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['reseller_account_id'], ['reseller_accounts.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_sub_accounts_reseller_account_id'), 'sub_accounts', ['reseller_account_id'], unique=False)
    op.create_table('sub_account_transactions',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('sub_account_id', sa.String(), nullable=False),
        sa.Column('transaction_type', sa.String(), nullable=False),
        sa.Column('amount', sa.Float(), nullable=False),
        sa.Column('description', sa.String(), nullable=True),
        sa.Column('reference', sa.String(), nullable=True),
        sa.Column('balance_before', sa.Float(), nullable=False),
        sa.Column('balance_after', sa.Float(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['sub_account_id'], ['sub_accounts.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('reference'),
    )
    op.create_table('credit_allocations',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('reseller_account_id', sa.String(), nullable=False),
        sa.Column('sub_account_id', sa.String(), nullable=False),
        sa.Column('amount', sa.Float(), nullable=False),
        sa.Column('allocation_type', sa.String(), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['reseller_account_id'], ['reseller_accounts.id'], ),
        sa.ForeignKeyConstraint(['sub_account_id'], ['sub_accounts.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_table('bulk_operations',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('reseller_account_id', sa.String(), nullable=False),
        sa.Column('operation_type', sa.String(), nullable=False),
        sa.Column('total_accounts', sa.Integer(), nullable=True),
        sa.Column('processed_accounts', sa.Integer(), nullable=True),
        sa.Column('failed_accounts', sa.Integer(), nullable=True),
        sa.Column('status', sa.String(), nullable=True),
        sa.Column('config', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('completed_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['reseller_account_id'], ['reseller_accounts.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )


def downgrade() -> None:
    op.drop_table('bulk_operations')
    op.drop_table('credit_allocations')
    op.drop_table('sub_account_transactions')
    op.drop_index(op.f('ix_sub_accounts_reseller_account_id'), table_name='sub_accounts')
    op.drop_table('sub_accounts')
    op.drop_table('reseller_accounts')
