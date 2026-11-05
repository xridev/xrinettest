import hashlib
import hmac
import secrets

from app.core.config import settings


def generate_otp() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


def _otp_digest(otp: str, email: str, purpose: str) -> str:
    normalized_email = email.strip().casefold()
    message = f"{purpose}:{normalized_email}:{otp}".encode("utf-8")
    secret = settings.otp_hash_secret.encode("utf-8")

    return hmac.new(secret, message, hashlib.sha256).hexdigest()


def hash_otp(
    otp: str,
    email: str,
    purpose: str = "signup",
) -> str:
    if not otp.isdigit() or len(otp) != 6:
        raise ValueError("OTP must contain exactly 6 digits.")

    return _otp_digest(otp, email, purpose)


def verify_otp(
    otp: str,
    otp_hash: str,
    email: str,
    purpose: str = "signup",
) -> bool:
    if not otp.isdigit() or len(otp) != 6:
        return False

    expected_hash = _otp_digest(otp, email, purpose)
    return hmac.compare_digest(expected_hash, otp_hash)
