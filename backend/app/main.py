from __future__ import annotations

from datetime import datetime

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.staticfiles import StaticFiles

from app.config import settings
from app.core.logging_config import configure_logging
from app.db.mongo import close_client, init_indexes
from app.routes import api_router

configure_logging()

app = FastAPI(
    title=settings.project_name,
    version="0.1.0",
    openapi_url=f"{settings.api_prefix}/openapi.json",
    docs_url=f"{settings.api_prefix}/docs",
    redoc_url=f"{settings.api_prefix}/redoc",
)


# Custom middleware to handle OPTIONS requests before they reach route validation
class PreflightMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if request.method == "OPTIONS":
            return Response(
                status_code=200,
                headers={
                    "Access-Control-Allow-Origin": request.headers.get("origin", "*"),
                    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, PATCH, OPTIONS",
                    "Access-Control-Allow-Headers": request.headers.get("access-control-request-headers", "*"),
                    "Access-Control-Allow-Credentials": "true",
                    "Access-Control-Max-Age": "600",
                },
            )
        return await call_next(request)


# Add preflight handler first
app.add_middleware(PreflightMiddleware)

# Then add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["Content-Range", "X-Content-Range", "Content-Disposition"],
    max_age=600,
)

app.include_router(api_router, prefix=settings.api_prefix)

if settings.media_base_path.exists():
    app.mount(settings.media_base_url, StaticFiles(directory=settings.media_base_path), name="media")


@app.on_event("startup")
async def on_startup() -> None:
    app.state.started_at = datetime.utcnow()
    await init_indexes()


@app.on_event("shutdown")
async def on_shutdown() -> None:
    await close_client()


@app.get("/", include_in_schema=False)
async def root() -> dict[str, str]:
    return {"message": "TeleGramApp backend is running", "docs": app.docs_url or ""}
