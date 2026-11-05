import pytest

from app.core import login_security
from app.models import User
from app.services.password_service import hash_password


@pytest.mark.asyncio
async def test_login_api_progressive_lockout(
    api_client,
    db_session,
    test_redis_client,
    monkeypatch,
):
    monkeypatch.setattr(
        login_security,
        "redis_client",
        test_redis_client,
    )

    email = "api-lockout-test@example.com"
    client_ip = "127.0.0.1"

    security_key = login_security._get_login_key(email, client_ip)
    rate_limit_key = f"rate-limit:login:{client_ip}"

    try:
        await test_redis_client.delete(security_key, rate_limit_key)

        async with db_session.begin():
            db_session.add(
                User(
                    email=email,
                    password_hash=hash_password("CorrectPassword123!"),
                    is_email_verified=True,
                    is_active=True,
                )
            )

        for _ in range(5):
            response = await api_client.post(
                "/api/v1/auth/login",
                json={
                    "email": email,
                    "password": "WrongPassword123!",
                },
            )
            assert response.status_code == 401

        response = await api_client.post(
            "/api/v1/auth/login",
            json={
                "email": email,
                "password": "WrongPassword123!",
            },
        )

        assert response.status_code == 429
        assert "Retry-After" in response.headers

    finally:
        await test_redis_client.delete(security_key, rate_limit_key)

@pytest.mark.asyncio
async def test_login_succeeds_when_failure_reset_redis_fails(
    api_client,
    db_session,
    test_redis_client,
    monkeypatch,
):
    from redis.exceptions import RedisError

    class FailingDeleteRedis:
        def __init__(self, client):
            self.client = client

        async def eval(self, *args):
            return await self.client.eval(*args)

        async def delete(self, *args):
            raise RedisError("Simulated Redis delete failure.")

    monkeypatch.setattr(
        login_security,
        "redis_client",
        FailingDeleteRedis(test_redis_client),
    )

    email = "reset-failure-test@example.com"
    rate_limit_key = "rate-limit:login:127.0.0.1"

    await test_redis_client.delete(rate_limit_key)

    async with db_session.begin():
        db_session.add(
            User(
                email=email,
                password_hash=hash_password("CorrectPassword123!"),
                is_email_verified=True,
                is_active=True,
            )
        )

    response = await api_client.post(
        "/api/v1/auth/login",
        json={
            "email": email,
            "password": "CorrectPassword123!",
        },
    )

    assert response.status_code == 200
    assert response.json()["access_token"]
    assert response.json()["refresh_token"]
