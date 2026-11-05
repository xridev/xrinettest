import uuid

import jwt
from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.session_repository import SessionRepository
from app.services.token_service import decode_token


class LogoutManager:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.sessions = SessionRepository(db)

    async def logout(self, refresh_token: str) -> bool:
        try:
            payload = decode_token(
                refresh_token,
                expected_type="refresh",
            )
            user_id = uuid.UUID(payload["sub"])
            token_jti = payload["jti"]
        except (jwt.InvalidTokenError, ValueError, TypeError):
            return False

        async with self.db.begin():
            session = await self.sessions.get_active_by_jti(
                token_jti,
                for_update=True,
            )

            if session is None or session.user_id != user_id:
                return False

            await self.sessions.revoke(session)

        return True
