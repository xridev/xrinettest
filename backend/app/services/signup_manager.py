from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.otp_repository import OTPRepository
from app.repositories.profile_repository import ProfileRepository
from app.repositories.user_repository import UserRepository
from app.schemas.signup import SignupRequest, SignupResponse
from app.services.password_service import hash_password


class SignupManager:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.users = UserRepository(db)
        self.profiles = ProfileRepository(db)
        self.otps = OTPRepository(db)

    async def register(
        self,
        data: SignupRequest,
    ) -> SignupResponse:
        email = str(data.email).strip().casefold()
        username = data.username.strip().lower()

        try:
            async with self.db.begin():
                verified_otp = await self.otps.get_verified_for_signup(
                    email=email,
                    purpose="signup",
                    for_update=True,
                )

                if verified_otp is None:
                    raise ValueError(
                        "Email verification is required before signup."
                    )

                existing_user = await self.users.get_by_email(email)

                if existing_user is not None:
                    raise ValueError("Email is already registered.")

                existing_profile = await self.profiles.get_by_username(
                    username
                )

                if existing_profile is not None:
                    raise ValueError("Username is already taken.")

                password_hash = hash_password(data.password)

                user = await self.users.create(
                    email=email,
                    password_hash=password_hash,
                )

                profile = await self.profiles.create(
                    user_id=user.id,
                    username=username,
                    full_name=data.full_name,
                )

                await self.otps.consume_verified(verified_otp)

                response = SignupResponse(
                    id=str(user.id),
                    email=user.email,
                    username=profile.username,
                    full_name=profile.full_name,
                    is_email_verified=user.is_email_verified,
                )

            return response

        except IntegrityError as exc:
            raise ValueError(
                "Email or username is already registered."
            ) from exc
