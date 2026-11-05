import pytest


ENDPOINT_CASES = [
    (
        "signup",
        "/api/v1/auth/signup",
        5,
        {
            "email": "rate-signup@example.com",
            "password": "TestPassword123!",
            "username": "rate_signup",
            "full_name": "Rate Limit Test",
        },
    ),
    (
        "otp-verify",
        "/api/v1/auth/otp/verify",
        30,
        {
            "email": "rate-otp@example.com",
            "otp": "123456",
        },
    ),
    (
        "password-reset-verify",
        "/api/v1/auth/password/verify-otp",
        10,
        {
            "email": "rate-reset@example.com",
            "otp": "123456",
        },
    ),
    (
        "password-reset",
        "/api/v1/auth/password/reset",
        5,
        {
            "email": "rate-reset@example.com",
            "otp": "123456",
            "new_password": "NewPassword123!",
        },
    ),
    (
        "refresh",
        "/api/v1/auth/refresh",
        30,
        {
            "refresh_token": "invalid-test-token",
        },
    ),
]


@pytest.mark.asyncio
@pytest.mark.parametrize(
    "scope,path,limit,payload",
    ENDPOINT_CASES,
)
async def test_additional_auth_api_rate_limits(
    api_client,
    test_redis_client,
    scope,
    path,
    limit,
    payload,
):
    key = f"rate-limit:{scope}:127.0.0.1"

    try:
        await test_redis_client.delete(key)

        for _ in range(limit):
            response = await api_client.post(path, json=payload)
            assert response.status_code != 429, (
                f"{scope} was blocked before reaching its limit: "
                f"{response.status_code}"
            )

        response = await api_client.post(path, json=payload)

        assert response.status_code == 429
        assert "Retry-After" in response.headers

    finally:
        await test_redis_client.delete(key)
