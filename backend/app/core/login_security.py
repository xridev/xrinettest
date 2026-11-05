import logging
import hashlib
import hmac
from datetime import timedelta

from fastapi import HTTPException, status
from redis.exceptions import RedisError

from app.core.config import settings
from app.db.redis import redis_client

logger = logging.getLogger(__name__)


LOCKOUT_DURATIONS = (
    30 * 60,
    60 * 60,
    3 * 60 * 60,
)

_FAILURE_SCRIPT = """
local attempts = redis.call("HINCRBY", KEYS[1], "failed_attempts", 1)
local lockout_count = tonumber(redis.call("HGET", KEYS[1], "lockout_count") or "0")

if attempts >= tonumber(ARGV[1]) then
    local duration = tonumber(ARGV[2])

    if lockout_count == 0 then
        duration = tonumber(ARGV[3])
    elseif lockout_count == 1 then
        duration = tonumber(ARGV[4])
    end

    redis.call("HSET", KEYS[1],
        "failed_attempts", 0,
        "lockout_count", lockout_count + 1,
        "locked_until", tonumber(ARGV[5]) + duration
    )
    redis.call("EXPIRE", KEYS[1], tonumber(ARGV[6]))
    return duration
end

redis.call("EXPIRE", KEYS[1], tonumber(ARGV[6]))
return 0
"""

_CHECK_SCRIPT = """
local locked_until = tonumber(redis.call("HGET", KEYS[1], "locked_until") or "0")
local now = tonumber(ARGV[1])

if locked_until > now then
    return locked_until - now
end

if locked_until > 0 then
    redis.call("HSET", KEYS[1],
        "locked_until", 0,
        "failed_attempts", 0
    )
end

return 0
"""


def _get_login_key(email: str, client_ip: str) -> str:
    normalized_email = email.strip().casefold()
    message = f"login:{client_ip}:{normalized_email}".encode("utf-8")
    secret = settings.otp_hash_secret.encode("utf-8")
    digest = hmac.new(secret, message, hashlib.sha256).hexdigest()
    return f"login-security:{digest}"


async def check_login_lock(email: str, client_ip: str) -> None:
    key = _get_login_key(email, client_ip)

    try:
        import time

        remaining = await redis_client.eval(
            _CHECK_SCRIPT,
            1,
            key,
            int(time.time()),
        )
    except RedisError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Login protection is temporarily unavailable.",
        ) from exc

    if int(remaining) > 0:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many failed login attempts. Please try again later.",
            headers={"Retry-After": str(int(remaining))},
        )


async def record_login_failure(email: str, client_ip: str) -> None:
    import time

    key = _get_login_key(email, client_ip)
    now = int(time.time())

    try:
        await redis_client.eval(
            _FAILURE_SCRIPT,
            1,
            key,
            5,
            LOCKOUT_DURATIONS[2],
            LOCKOUT_DURATIONS[0],
            LOCKOUT_DURATIONS[1],
            now,
            int(timedelta(days=90).total_seconds()),
        )
    except RedisError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Login protection is temporarily unavailable.",
        ) from exc


async def reset_login_failures(email: str, client_ip: str) -> None:
    key = _get_login_key(email, client_ip)

    try:
        await redis_client.delete(key)
    except RedisError:
        logger.warning(
            "Could not reset login failure state because Redis is unavailable."
        )
