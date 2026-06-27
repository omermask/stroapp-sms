"""add city country to user_sessions

Revision ID: f6a9b8c7d0e1
Revises: 2a3b4c5d6e7f
Create Date: 2026-06-25 20:10:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "f6a9b8c7d0e1"
down_revision: Union[str, None] = "2a3b4c5d6e7f"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("user_sessions", sa.Column("city", sa.String(), nullable=True))
    op.add_column("user_sessions", sa.Column("country", sa.String(), nullable=True))


def downgrade() -> None:
    op.drop_column("user_sessions", "country")
    op.drop_column("user_sessions", "city")
