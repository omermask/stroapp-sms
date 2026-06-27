"""phase5: add hashed_password to users

Revision ID: 9a3b2c1d0e5f
Revises: 8f2e1c3d4b5a
Create Date: 2026-06-22 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = '9a3b2c1d0e5f'
down_revision: Union[str, Sequence[str], None] = '8f2e1c3d4b5a'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('users', sa.Column('hashed_password', sa.String(), nullable=True))


def downgrade() -> None:
    op.drop_column('users', 'hashed_password')
