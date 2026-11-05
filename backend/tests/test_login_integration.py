import pytest
from sqlalchemy import select

from app.models import User, UserSession
from app.schemas.login import LoginRequest
from app.services.login_manager import LoginManager
from app.services.password_service import hash_password
from app.services.token_service import decode_token


@pytest.mark.asyncio
async def test_login_with_postgresql(db_session):
    email = "login-integration@example.com"
    password = "TestPassword123!"

    user = User(
        email=email,
        password_hash=hash_password(password),
        is_email_verified=True,
        is_active=True,
    )

    async with db_session.begin():
        db_session.add(user)
        await db_session.flush()
        user_id = user.id

    manager = LoginManager(db_session)

    with pytest.raises(ValueError, match="Invalid email or password"):
        await manager.login(
            LoginRequest(
                email=email,
                password="WrongPassword123!",
            )
        )

    response = await manager.login(
        LoginRequest(
            email=email,
            password=password,
        )
    )

    access_payload = decode_token(
        response.access_token,
        expected_type="access",
    )
    refresh_payload = decode_token(
        response.refresh_token,
        expected_type="refresh",
    )

    assert access_payload["sub"] == str(user_id)
    assert refresh_payload["sub"] == str(user_id)

    session = await db_session.scalar(
        select(UserSession).where(
            UserSession.refresh_token_jti == refresh_payload["jti"]
        )
    )

    assert session is not None
    assert session.user_id == user_id
    assert session.revoked_at is None
