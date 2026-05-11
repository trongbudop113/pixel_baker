from fastapi import APIRouter, Depends

from app.models.story import StoryPageResponse
from app.repositories.story_repository import StoryRepository, get_story_repository

router = APIRouter()


@router.get("", response_model=StoryPageResponse)
async def get_story_page(
    repository: StoryRepository = Depends(get_story_repository),
) -> StoryPageResponse:
    return await repository.get_page()
