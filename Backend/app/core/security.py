from typing import Optional
from fastapi import Depends, HTTPException
from fastapi.security.api_key import APIKeyHeader
from starlette.status import HTTP_403_FORBIDDEN
from app.core.config import settings

api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)

async def get_api_key(api_key: Optional[str] = Depends(api_key_header)) -> str:
    if api_key == settings.API_KEY:
        return api_key
    raise HTTPException(status_code=HTTP_403_FORBIDDEN, detail="Clé API invalide.")
