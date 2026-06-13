from pathlib import Path
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    API_KEY: str = "changeme"
    UPLOAD_DIR: Path = Path("uploads")
    GOOGLE_CLIENT_ID: str | None = None
    JWT_SECRET: str | None = None

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"

settings = Settings()
