from fastapi import APIRouter

from app.api.v1.admin import router as admin_router
from app.api.v1.auth import router as auth_router
from app.api.v1.checkout import router as checkout_router
from app.api.v1.contact import router as contact_router
from app.api.v1.health import router as health_router
from app.api.v1.home import router as home_router
from app.api.v1.menu import router as menu_router
from app.api.v1.story import router as story_router
from app.api.v1.voucher import router as voucher_router

api_router = APIRouter()
api_router.include_router(health_router, tags=["health"])
api_router.include_router(admin_router, prefix="/admin", tags=["admin"])
api_router.include_router(home_router, prefix="/home", tags=["home"])
api_router.include_router(contact_router, prefix="/contact", tags=["contact"])
api_router.include_router(checkout_router, prefix="/checkout", tags=["checkout"])
api_router.include_router(menu_router, prefix="/menu", tags=["menu"])
api_router.include_router(story_router, prefix="/story", tags=["story"])
api_router.include_router(voucher_router, prefix="/voucher", tags=["voucher"])
api_router.include_router(auth_router, prefix="/auth", tags=["auth"])
