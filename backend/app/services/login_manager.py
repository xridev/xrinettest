from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.session_repository import SessionRepository
from app.repositories.user_repository import UserRepository
from app.schemas.login import LoginRequest, LoginResponse
from app.services.password_service import (
    verify_password,
    verify_dummy_password,
)
from app.services.token_service import (
    create_access_token,
    create_refresh_token,
    decode_token,
)


class LoginManager:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.users = UserRepository(db)
        self.sessions = SessionRepository(db)

    async def login(self, data: LoginRequest) -> LoginResponse:
        email = str(data.email).strip().casefold()

        async with self.db.begin():
            user = await self.users.get_by_email(email)

            if user is None:
                verify_dummy_password(data.password)
                raise ValueError("Invalid email or password.")

            if not verify_password(data.password, user.password_hash):
                raise ValueError("Invalid email or password.")

            if not user.is_active or not user.is_email_verified:
                raise ValueError("Invalid email or password.")

            user_id = str(user.id)

            access_token = create_access_token(user_id)
            refresh_token = create_refresh_token(user_id)

            refresh_payload = decode_token(
                refresh_token,
                expected_type="refresh",
            )

            refresh_expiry = datetime.fromtimestamp(
                refresh_payload["exp"],
                tz=timezone.utc,
            )

            await self.sessions.create(
                user_id=user.id,
                refresh_token_jti=refresh_payload["jti"],
                expires_at=refresh_expiry,
            )

            response = LoginResponse(
                access_token=access_token,
                refresh_token=refresh_token,
            )

        return response
