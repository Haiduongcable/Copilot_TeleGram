from fastapi import APIRouter

from app.routes import admin, auth, files, messaging, notifications, posts, realtime, system, users

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(posts.router)
api_router.include_router(messaging.router)
api_router.include_router(notifications.router)
api_router.include_router(files.router)
api_router.include_router(admin.router)
api_router.include_router(system.router)
api_router.include_router(realtime.router, include_in_schema=False)

__all__ = ["api_router"]
