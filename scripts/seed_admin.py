"""Seed the first admin user. Usage: python scripts/seed_admin.py <email> <password>"""
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.database import SessionLocal
from app.core.security import hash_password
from app.domain.models import User, gen_uuid


def main(email: str, password: str):
    db = SessionLocal()
    try:
        existing = db.query(User).filter(User.email == email).first()
        if existing:
            existing.is_admin = True
            existing.hashed_password = hash_password(password)
            print(f"Updated existing user {email} to admin")
        else:
            user = User(
                id=gen_uuid(),
                email=email,
                display_name="Admin",
                is_admin=True,
                hashed_password=hash_password(password),
                coins=0,
                lifetime_coins=0,
            )
            db.add(user)
            print(f"Created admin user {email}")
        db.commit()
        print("Done")
    finally:
        db.close()


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python scripts/seed_admin.py <email> <password>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
