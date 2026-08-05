from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Pixel Bakery API"
    app_env: str = "development"
    app_debug: bool = True
    api_v1_prefix: str = "/api/v1"
    mongodb_uri: str = "mongodb://localhost:27017"
    mongodb_db: str = "pixel_bakery"
    mongodb_timeout_ms: int = 3000
    jwt_secret_key: str = "change-me"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 30
    jwt_refresh_expire_days: int = 30
    password_reset_expire_minutes: int = 30
    login_max_attempts: int = 5
    login_lock_minutes: int = 15
    log_level: str = "INFO"
    # Gmail SMTP
    smtp_host: str = "smtp.gmail.com"
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_from_name: str = "Pixel Bakery"
    image_storage_provider: str = "local"
    google_drive_folder_id: str = ""
    google_drive_service_account_json: str = ""
    google_drive_service_account_base64: str = ""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
