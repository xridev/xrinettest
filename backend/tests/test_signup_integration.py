import pytest
from sqlalchemy import select

from app.models import EmailOTP, User, UserProfile
from app.schemas.signup import SignupRequest
from app.services.otp_policy import get_otp_expiry
from app.services.otp_service import hash_otp
from app.services.signup_manager import SignupManager


@pytest.mark.asyncio
async def test_signup_with_verified_email(db_session):
    email = "integration-test@example.com"
    username = "integration_test"
    otp = "123456"

    async with db_session.begin():
        db_session.add(
            EmailOTP(
                email=email,
                purpose="signup",
                otp_hash=hash_otp(otp, email, "signup"),
                expires_at=get_otp_expiry(),
                is_verified=True,
                is_used=False,
                attempts=0,
            )
        )

    request = SignupRequest(
        email=email,
        password="TestPassword123!",
        username=username,
        full_name="Integration Test",
    )

    response = await SignupManager(db_session).register(request)

    assert response.email == email
    assert response.username == username
    assert response.is_email_verified is True

    user = await db_session.scalar(
        select(User).where(User.email == email)
    )
    assert user is not None
    assert user.is_email_verified is True

    profile = await db_session.scalar(
        select(UserProfile).where(UserProfile.user_id == user.id)
    )
    assert profile is not None
    assert profile.username == username

    verified_otp = await db_session.scalar(
        select(EmailOTP).where(EmailOTP.email == email)
    )
    assert verified_otp.is_used is True
