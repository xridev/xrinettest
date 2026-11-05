import pytest




@pytest.mark.asyncio
async def test_logout_api_rate_limit(api_client, test_redis_client):
    key = "rate-limit:logout:127.0.0.1"

    try:
        await test_redis_client.delete(key)

        for _ in range(30):
            response = await api_client.post(
                "/api/v1/auth/logout",
                json={"refresh_token": "invalid-test-token"},
            )
            assert response.status_code == 401

        response = await api_client.post(
            "/api/v1/auth/logout",
            json={"refresh_token": "invalid-test-token"},
        )

        assert response.status_code == 429
        assert "Retry-After" in response.headers
    finally:
        await test_redis_client.delete(key)


@pytest.mark.asyncio
async def test_login_api_rate_limit(api_client, test_redis_client):
    key = "rate-limit:login:127.0.0.1"

    try:
        await test_redis_client.delete(key)

        for index in range(10):
            response = await api_client.post(
                "/api/v1/auth/login",
                json={
                    "email": f"rate-limit-test-{index}@example.com",
                    "password": "WrongPassword123!",
                },
            )
            assert response.status_code == 401

        response = await api_client.post(
            "/api/v1/auth/login",
            json={
                "email": "rate-limit-test-final@example.com",
                "password": "WrongPassword123!",
            },
        )

        assert response.status_code == 429
        assert "Retry-After" in response.headers
    finally:
        await test_redis_client.delete(key)
