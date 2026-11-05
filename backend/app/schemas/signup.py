from pydantic import BaseModel, EmailStr, Field, field_validator


class SignupRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: EmailStr) -> str:
        return str(value).strip().casefold()

    username: str = Field(
        min_length=3,
        max_length=30,
        pattern=r"^[a-zA-Z0-9_.]+$",
    )
    full_name: str = Field(min_length=1, max_length=100)

    @field_validator("username")
    @classmethod
    def normalize_username(cls, value: str) -> str:
        return value.strip().lower()

    @field_validator("full_name")
    @classmethod
    def normalize_full_name(cls, value: str) -> str:
        value = " ".join(value.split())

        if not value:
            raise ValueError("Full name cannot be empty.")

        return value

class SignupResponse(BaseModel):
    id: str
    email: EmailStr
    username: str
    full_name: str
    is_email_verified: bool
    message: str = "Account created successfully."
