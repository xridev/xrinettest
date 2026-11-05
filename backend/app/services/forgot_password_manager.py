from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.otp_repository import OTPRepository
from app.repositories.user_repository import UserRepository
from app.schemas.forgot_password import ForgotPasswordRequest, ForgotPasswordResponse
from app.services.email_service import EmailService
from app.services.otp_manager import OTPManager


class ForgotPasswordManager:
    def __init__(
        self,
        db: AsyncSession,
        email_service: EmailService,
    ):
        self.db = db
        self.users = UserRepository(db)
        self.otps = OTPRepository(db)
        self.otp_manager = OTPManager(db)
        self.email_service = email_service

    async def request_reset(
        self,
        data: ForgotPasswordRequest,
    ) -> ForgotPasswordResponse:
        email = str(data.email).strip().casefold()

        try:
            async with self.db.begin():
                user = await self.users.get_by_email(email)

                if user is None or not user.is_active or not user.is_email_verified:
                    return ForgotPasswordResponse()

                otp = await self.otp_manager.issue_otp(
                    email=email,
                    purpose="password_reset",
                )

        except ValueError:
            return ForgotPasswordResponse()

        try:
            sent = await self.email_service.send_otp(
                email=email,
                otp=otp,
                purpose="password_reset",
            )
        except Exception:
            sent = False

        if not sent:
            async with self.db.begin():
                await self.otps.invalidate_active(
                    email=email,
                    purpose="password_reset",
                )

        return ForgotPasswordResponse()
