import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User


class UserRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_email(self, email: str) -> User | None:
        statement = select(User).where(
            User.email == email.strip().casefold()
        )
        result = await self.db.execute(statement)
        return result.scalar_one_or_none()

    async def get_by_id(self, user_id: uuid.UUID) -> User | None:
        statement = select(User).where(User.id == user_id)
        result = await self.db.execute(statement)
        return result.scalar_one_or_none()

    async def create(
        self,
        email: str,
        password_hash: str,
    ) -> User:
        user = User(
            email=email.strip().casefold(),
            password_hash=password_hash,
            is_email_verified=True,
        )
        self.db.add(user)
        await self.db.flush()
        return user

    async def update_password_hash(
        self,
        user: User,
        password_hash: str,
    ) -> None:
        user.password_hash = password_hash
        await self.db.flush()
