from datetime import datetime, timezone

from fastapi import APIRouter, Depends

from app.models.contact import (
    ContactPageResponse,
    ContactSubmitRequest,
    ContactSubmitResponse,
)
from app.repositories.contact_repository import (
    ContactRepository,
    get_contact_repository,
    ContactSubmissionRepository,
    get_contact_submission_repository,
)

router = APIRouter()


@router.get("", response_model=ContactPageResponse)
async def get_contact_page(
    repository: ContactRepository = Depends(get_contact_repository),
) -> ContactPageResponse:
    return await repository.get_page()


@router.post("/submit", response_model=ContactSubmitResponse)
async def submit_contact_form(
    payload: ContactSubmitRequest,
    repository: ContactSubmissionRepository = Depends(
        get_contact_submission_repository,
    ),
) -> ContactSubmitResponse:
    await repository.create_submission(
        {
            "fullName": payload.fullName.strip(),
            "email": payload.email.strip(),
            "phone": payload.phone.strip() if payload.phone else None,
            "message": payload.message.strip(),
            "createdAt": datetime.now(timezone.utc).isoformat(),
        }
    )
    return ContactSubmitResponse(
        message="Đã gửi liên hệ thành công. Chúng tôi sẽ phản hồi sớm nhất.",
    )
