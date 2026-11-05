import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user_session import UserSession


class SessionRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(
        self,
        user_id: uuid.UUID,
        refresh_token_jti: str,
        expires_at: datetime,
    ) -> UserSession:
        session = UserSession(
            user_id=user_id,
            refresh_token_jti=refresh_token_jti,
            expires_at=expires_at,
        )
        self.db.add(session)
        await self.db.flush()
        return session

    async def get_active_by_jti(
        self,
        jti: str,
        for_update: bool = False,
    ) -> UserSession | None:
        statement = select(UserSession).where(
            UserSession.refresh_token_jti == jti,
            UserSession.revoked_at.is_(None),
            UserSession.expires_at > datetime.now(timezone.utc),
        )

        if for_update:
            statement = statement.with_for_update()

        result = await self.db.execute(statement)
        return result.scalar_one_or_none()

    async def revoke(self, session: UserSession) -> None:
        session.revoked_at = datetime.now(timezone.utc)
        await self.db.flush()

    async def revoke_all_for_user(self, user_id: uuid.UUID) -> None:
        from sqlalchemy import update

        statement = (
            update(UserSession)
            .where(
                UserSession.user_id == user_id,
                UserSession.revoked_at.is_(None),
            )
            .values(revoked_at=datetime.now(timezone.utc))
        )

        await self.db.execute(statement)
        await self.db.flush()
