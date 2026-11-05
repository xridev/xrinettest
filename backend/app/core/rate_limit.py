from fastapi import HTTPException, Request, status
from redis.exceptions import RedisError

from app.db.redis import redis_client


_RATE_LIMIT_SCRIPT = """
local current = redis.call("INCR", KEYS[1])

if current == 1 then
    redis.call("EXPIRE", KEYS[1], ARGV[1])
end

local ttl = redis.call("TTL", KEYS[1])

return {current, ttl}
"""


async def enforce_ip_rate_limit(
    request: Request,
    *,
    scope: str,
    limit: int,
    window_seconds: int = 60,
) -> None:
    if limit < 1 or window_seconds < 1:
        raise ValueError("Rate limit and window must be positive.")

    client_ip = request.client.host if request.client else "unknown"
    redis_key = f"rate-limit:{scope}:{client_ip}"

    try:
        result = await redis_client.eval(
            _RATE_LIMIT_SCRIPT,
            1,
            redis_key,
            window_seconds,
        )
    except RedisError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Request protection is temporarily unavailable.",
        ) from exc

    request_count = int(result[0])
    retry_after = max(int(result[1]), 1)

    if request_count > limit:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many requests. Please try again later.",
            headers={"Retry-After": str(retry_after)},
        )
