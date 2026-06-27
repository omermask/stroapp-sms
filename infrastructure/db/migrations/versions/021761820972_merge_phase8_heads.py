"""merge_phase8_heads

Revision ID: 021761820972
Revises: 6a3ec6b65d81, e5f6a7b8c9d0
Create Date: 2026-06-22 10:01:48.539323

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '021761820972'
down_revision: Union[str, Sequence[str], None] = ('6a3ec6b65d81', 'e5f6a7b8c9d0')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
