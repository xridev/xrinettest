from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.otp_repository import OTPRepository
from app.repositories.session_repository import SessionRepository
from app.repositories.user_repository import UserRepository
from app.schemas.password_reset import (
    PasswordResetRequest,
    PasswordResetResponse,
)
from app.services.password_service import hash_password
from app.services.otp_service import verify_otp


class PasswordResetManager:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.users = UserRepository(db)
        self.otps = OTPRepository(db)
        self.sessions = SessionRepository(db)

    async def verify_reset_otp(self, data) -> bool:
        email = str(data.email).strip().casefold()

        async with self.db.begin():
            return await self._verify_otp(email, data.otp)

    async def _verify_otp(self, email: str, otp: str) -> bool:
        from app.services.otp_manager import OTPManager

        manager = OTPManager(self.db)
        return await manager.verify_email_otp(
            email=email,
            otp=otp,
            purpose="password_reset",
        )

    async def reset_password(
        self,
        data: PasswordResetRequest,
    ) -> PasswordResetResponse:
        email = str(data.email).strip().casefold()

        async with self.db.begin():
            user = await self.users.get_by_email(email)

            if (
                user is None
                or not user.is_active
                or not user.is_email_verified
            ):
                raise ValueError("Invalid or expired password reset proof.")

            verified_otp = await self.otps.get_verified_for_purpose(
                email=email,
                purpose="password_reset",
                for_update=True,
            )

            if verified_otp is None:
                raise ValueError("Invalid or expired password reset proof.")

            if not verify_otp(
                data.otp,
                verified_otp.otp_hash,
                email,
                purpose="password_reset",
            ):
                raise ValueError("Invalid or expired password reset proof.")

            new_hash = hash_password(data.new_password)

            await self.users.update_password_hash(
                user=user,
                password_hash=new_hash,
            )

            await self.otps.consume_verified(verified_otp)

            await self.sessions.revoke_all_for_user(user.id)

        return PasswordResetResponse(
            message="Password reset successfully. Please log in again."
        )
