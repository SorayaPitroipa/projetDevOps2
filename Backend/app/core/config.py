from pathlib import Path
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    API_KEY: str = "changeme"
    UPLOAD_DIR: Path = Path("uploads")

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()
