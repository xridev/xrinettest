import time

import pytest
from fastapi import HTTPException

from app.core import login_security


@pytest.mark.asyncio
async def test_progressive_login_lockout(test_redis_client, monkeypatch):
    monkeypatch.setattr(
        login_security,
        "redis_client",
        test_redis_client,
    )

    email = "login-lockout@example.com"
    ip = "192.0.2.50"
    key = login_security._get_login_key(email, ip)

    try:
        await test_redis_client.delete(key)

        expected_durations = (1800, 3600, 10800)

        for expected_duration in expected_durations:
            for _ in range(5):
                await login_security.record_login_failure(email, ip)

            locked_until = int(
                await test_redis_client.hget(key, "locked_until")
            )

            remaining = locked_until - int(time.time())
            assert remaining == expected_duration

            with pytest.raises(HTTPException) as exc_info:
                await login_security.check_login_lock(email, ip)

            assert exc_info.value.status_code == 429

            await test_redis_client.hset(key, "locked_until", 0)
            await login_security.check_login_lock(email, ip)

    finally:
        await test_redis_client.delete(key)


@pytest.mark.asyncio
async def test_successful_login_resets_failures(
    test_redis_client,
    monkeypatch,
):
    monkeypatch.setattr(
        login_security,
        "redis_client",
        test_redis_client,
    )

    email = "login-reset@example.com"
    ip = "192.0.2.51"
    key = login_security._get_login_key(email, ip)

    try:
        await test_redis_client.delete(key)

        for _ in range(4):
            await login_security.record_login_failure(email, ip)

        assert await test_redis_client.exists(key)

        await login_security.reset_login_failures(email, ip)

        assert await test_redis_client.exists(key) == 0

    finally:
        await test_redis_client.delete(key)
