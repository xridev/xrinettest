import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user_profile import UserProfile


class ProfileRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_username(
        self,
        username: str,
    ) -> UserProfile | None:
        statement = select(UserProfile).where(
            UserProfile.username == username.strip().lower()
        )
        result = await self.db.execute(statement)
        return result.scalar_one_or_none()

    async def create(
        self,
        user_id: uuid.UUID,
        username: str,
        full_name: str,
    ) -> UserProfile:
        profile = UserProfile(
            user_id=user_id,
            username=username.strip().lower(),
            full_name=full_name,
        )
        self.db.add(profile)
        await self.db.flush()
        return profile
