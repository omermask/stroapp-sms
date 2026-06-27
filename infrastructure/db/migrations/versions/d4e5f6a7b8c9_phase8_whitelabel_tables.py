"""phase8_whitelabel_tables

Revision ID: d4e5f6a7b8c9
Revises: c3d4e5f6a7b8
Create Date: 2026-06-22 09:45:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'd4e5f6a7b8c9'
down_revision: Union[str, Sequence[str], None] = 'c3d4e5f6a7b8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table('whitelabel_domains',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('domain', sa.String(), nullable=False),
        sa.Column('verified', sa.Boolean(), nullable=True),
        sa.Column('verification_token', sa.String(), nullable=False),
        sa.Column('ssl_status', sa.String(), nullable=True),
        sa.Column('ssl_expires_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('domain'),
    )
    op.create_index(op.f('ix_whitelabel_domains_user_id'), 'whitelabel_domains', ['user_id'], unique=False)

    op.create_table('whitelabel_branding',
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('company_name', sa.String(), nullable=True),
        sa.Column('logo_url', sa.String(), nullable=True),
        sa.Column('favicon_url', sa.String(), nullable=True),
        sa.Column('primary_color', sa.String(), nullable=True),
        sa.Column('secondary_color', sa.String(), nullable=True),
        sa.Column('accent_color', sa.String(), nullable=True),
        sa.Column('support_email', sa.String(), nullable=True),
        sa.Column('support_phone', sa.String(), nullable=True),
        sa.Column('website_url', sa.String(), nullable=True),
        sa.Column('custom_css', sa.Text(), nullable=True),
        sa.Column('custom_js', sa.Text(), nullable=True),
        sa.Column('terms_url', sa.String(), nullable=True),
        sa.Column('privacy_url', sa.String(), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('user_id'),
    )

    op.create_table('whitelabel_email_templates',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('template_name', sa.String(), nullable=False),
        sa.Column('subject', sa.String(), nullable=False),
        sa.Column('html_content', sa.Text(), nullable=False),
        sa.Column('text_content', sa.Text(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('version', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'template_name', name='uq_user_template'),
    )
    op.create_index(op.f('ix_whitelabel_email_templates_user_id'), 'whitelabel_email_templates', ['user_id'], unique=False)

    op.create_table('email_template_versions',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('template_id', sa.String(), nullable=False),
        sa.Column('version_number', sa.Integer(), nullable=False),
        sa.Column('subject', sa.String(), nullable=False),
        sa.Column('html_content', sa.Text(), nullable=False),
        sa.Column('text_content', sa.Text(), nullable=True),
        sa.Column('created_by', sa.String(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['template_id'], ['whitelabel_email_templates.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )

    op.create_table('email_template_analytics',
        sa.Column('template_id', sa.String(), nullable=False),
        sa.Column('sent_count', sa.Integer(), nullable=True),
        sa.Column('delivered_count', sa.Integer(), nullable=True),
        sa.Column('opened_count', sa.Integer(), nullable=True),
        sa.Column('clicked_count', sa.Integer(), nullable=True),
        sa.Column('bounced_count', sa.Integer(), nullable=True),
        sa.Column('complained_count', sa.Integer(), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['template_id'], ['whitelabel_email_templates.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('template_id'),
    )


def downgrade() -> None:
    op.drop_table('email_template_analytics')
    op.drop_table('email_template_versions')
    op.drop_index(op.f('ix_whitelabel_email_templates_user_id'), table_name='whitelabel_email_templates')
    op.drop_table('whitelabel_email_templates')
    op.drop_table('whitelabel_branding')
    op.drop_index(op.f('ix_whitelabel_domains_user_id'), table_name='whitelabel_domains')
    op.drop_table('whitelabel_domains')
