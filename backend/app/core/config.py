from functools import lru_cache

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "XRINet API"
    app_env: str = "development"
    debug: bool = False
    api_v1_prefix: str = "/api/v1"

    database_url: str
    redis_url: str

    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 30

    otp_hash_secret: str
    otp_expire_minutes: int = 5
    otp_max_attempts: int = 5
    otp_resend_cooldown_seconds: int = 60

    media_root: str = "storage"
    max_upload_size_mb: int = 100

    cors_origins: str = ""

    @model_validator(mode="after")
    def validate_jwt_secret(self):
        if self.app_env.lower() == "production":
            if len(self.jwt_secret_key) < 32:
                raise ValueError(
                    "Production JWT secret must be at least 32 characters."
                )

            if self.jwt_secret_key == "replace_with_a_long_random_secret":
                raise ValueError(
                    "Default JWT secret cannot be used in production."
                )

            if len(self.otp_hash_secret) < 32:
                raise ValueError(
                    "Production OTP hash secret must be at least 32 characters."
                )
            if self.otp_hash_secret == "replace_with_a_separate_long_random_secret":
                raise ValueError(
                    "Default OTP hash secret cannot be used in production."
                )
        return self

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @property
    def cors_origins_list(self) -> list[str]:
        return [
            origin.strip()
            for origin in self.cors_origins.split(",")
            if origin.strip()
        ]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
