from pwdlib import PasswordHash


password_hasher = PasswordHash.recommended()


def hash_password(password: str) -> str:
    return password_hasher.hash(password)


def verify_password(
    plain_password: str,
    hashed_password: str,
) -> bool:
    return password_hasher.verify(
        plain_password,
        hashed_password,
    )

# Used to reduce login timing differences for unknown email addresses.
_DUMMY_PASSWORD_HASH = password_hasher.hash(
    "XRINet-Dummy-Password-Not-For-Login"
)


def verify_dummy_password(plain_password: str) -> None:
    password_hasher.verify(
        plain_password,
        _DUMMY_PASSWORD_HASH,
    )
