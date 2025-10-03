from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import List

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", case_sensitive=False)

    project_name: str = "TeleGramApp Backend"
    environment: str = Field("local", alias="ENVIRONMENT")
    api_prefix: str = Field("/api", alias="API_PREFIX")

    mongodb_uri: str = Field("mongodb://localhost:27017", alias="MONGODB_URI")
    mongo_db_name: str = Field("telegramapp", alias="MONGODB_DB_NAME")

    jwt_access_secret: str = Field("dev-access-secret", alias="JWT_ACCESS_SECRET")
    jwt_refresh_secret: str = Field("dev-refresh-secret", alias="JWT_REFRESH_SECRET")
    jwt_algorithm: str = Field("HS256", alias="JWT_ALGORITHM")
    access_token_expire_minutes: int = Field(60, alias="ACCESS_TOKEN_EXPIRE_MINUTES")
    refresh_token_expire_minutes: int = Field(60 * 24 * 7, alias="REFRESH_TOKEN_EXPIRE_MINUTES")

    cors_origins: List[str] = Field(default_factory=lambda: ["*"], alias="CORS_ORIGINS")

    media_base_path: Path = Field(Path("uploads"), alias="MEDIA_BASE_PATH")
    media_base_url: str = Field("/media", alias="MEDIA_BASE_URL")
    image_max_bytes: int = Field(10 * 1024 * 1024, alias="IMAGE_MAX_BYTES")
    file_max_bytes: int = Field(50 * 1024 * 1024, alias="FILE_MAX_BYTES")
    per_user_storage_quota_bytes: int = Field(1024 * 1024 * 1024, alias="PER_USER_STORAGE_QUOTA_BYTES")

    rate_limit_auth_per_minute: int = Field(100, alias="RATE_LIMIT_AUTH_PER_MINUTE")
    redis_url: str | None = Field(None, alias="REDIS_URL")

    log_level: str = Field("INFO", alias="LOG_LEVEL")

    @field_validator("cors_origins", mode="before")
    @classmethod
    def split_cors(cls, value: str | list[str] | None) -> list[str]:
        if value is None or value == "":
            return ["*"]
        if isinstance(value, str):
            origins = [origin.strip() for origin in value.split(",") if origin.strip()]
            return origins if origins else ["*"]
        return value if value else ["*"]


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    settings = Settings()
    settings.media_base_path.mkdir(parents=True, exist_ok=True)
    return settings


settings = get_settings()
