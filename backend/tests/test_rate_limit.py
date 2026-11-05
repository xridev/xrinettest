import pytest
from fastapi import HTTPException, Request
from redis.exceptions import ConnectionError as RedisConnectionError

from app.core.rate_limit import enforce_ip_rate_limit


def make_request(ip: str = "192.0.2.10") -> Request:
    return Request({
        "type": "http",
        "method": "POST",
        "path": "/test",
        "headers": [],
        "client": (ip, 12345),
        "server": ("localhost", 8000),
        "scheme": "http",
        "query_string": b"",
    })


@pytest.mark.asyncio
async def test_rate_limit_blocks_excess_requests(test_redis_client, monkeypatch):
    from app.core import rate_limit
    monkeypatch.setattr(rate_limit, "redis_client", test_redis_client)

    scope = "pytest-rate-limit"
    key = f"rate-limit:{scope}:192.0.2.10"
    request = make_request()

    try:
        await test_redis_client.delete(key)

        await enforce_ip_rate_limit(
            request,
            scope=scope,
            limit=2,
            window_seconds=60,
        )

        await enforce_ip_rate_limit(
            request,
            scope=scope,
            limit=2,
            window_seconds=60,
        )

        with pytest.raises(HTTPException) as exc_info:
            await enforce_ip_rate_limit(
                request,
                scope=scope,
                limit=2,
                window_seconds=60,
            )

        assert exc_info.value.status_code == 429
        assert "Retry-After" in exc_info.value.headers
    finally:
        await test_redis_client.delete(key)


@pytest.mark.asyncio
async def test_rate_limit_fails_closed_when_redis_unavailable(test_redis_client, monkeypatch):
    from app.core import rate_limit
    monkeypatch.setattr(rate_limit, "redis_client", test_redis_client)

    async def unavailable(*args, **kwargs):
        raise RedisConnectionError("Redis unavailable")

    monkeypatch.setattr(test_redis_client, "eval", unavailable)

    with pytest.raises(HTTPException) as exc_info:
        await enforce_ip_rate_limit(
            make_request("192.0.2.11"),
            scope="pytest-redis-failure",
            limit=2,
            window_seconds=60,
        )

    assert exc_info.value.status_code == 503
