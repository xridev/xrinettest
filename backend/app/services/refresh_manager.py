import uuid
from datetime import datetime, timezone

import jwt
from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.session_repository import SessionRepository
from app.repositories.user_repository import UserRepository
from app.schemas.login import LoginResponse
from app.services.token_service import (
    create_access_token,
    create_refresh_token,
    decode_token,
)


class RefreshManager:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.sessions = SessionRepository(db)
        self.users = UserRepository(db)

    async def refresh(self, refresh_token: str) -> LoginResponse:
        try:
            payload = decode_token(
                refresh_token,
                expected_type="refresh",
            )
            user_id = uuid.UUID(payload["sub"])
            token_jti = payload["jti"]
        except (jwt.InvalidTokenError, ValueError, TypeError) as exc:
            raise ValueError("Invalid or expired refresh token.") from exc

        async with self.db.begin():
            session = await self.sessions.get_active_by_jti(
                token_jti,
                for_update=True,
            )

            if session is None or session.user_id != user_id:
                raise ValueError("Invalid or expired refresh token.")

            user = await self.users.get_by_id(user_id)

            if user is None or not user.is_active or not user.is_email_verified:
                raise ValueError("Invalid or expired refresh token.")

            await self.sessions.revoke(session)

            access_token = create_access_token(str(user.id))
            new_refresh_token = create_refresh_token(str(user.id))

            new_payload = decode_token(
                new_refresh_token,
                expected_type="refresh",
            )

            new_expiry = datetime.fromtimestamp(
                new_payload["exp"],
                tz=timezone.utc,
            )

            await self.sessions.create(
                user_id=user.id,
                refresh_token_jti=new_payload["jti"],
                expires_at=new_expiry,
            )

            response = LoginResponse(
                access_token=access_token,
                refresh_token=new_refresh_token,
            )

        return response
