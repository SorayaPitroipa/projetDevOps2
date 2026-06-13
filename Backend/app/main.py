import os
from dotenv import load_dotenv
load_dotenv() # Load variables BEFORE importing any other modules

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.routes import upload, scoring, auth
from app.db import init_db

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize the database on startup
    init_db()
    yield

app = FastAPI(title="Credit Scoring Wave", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:4200", "http://127.0.0.1:4200", "http://localhost:34207"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

app.include_router(upload.router, prefix="/api/v1")
app.include_router(scoring.router, prefix="/api/v1")
app.include_router(auth.router, prefix="/api/v1")

@app.get("/health")
def health():
    return {"status": "ok"}
