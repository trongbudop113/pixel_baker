from typing import List

from app.models.common import ApiModel


class StoryTimelineItemResponse(ApiModel):
    year: str
    description: str


class StoryImageTimelineItemResponse(ApiModel):
    year: str
    title: str
    description: str
    previewLabel: str


class StorySectionResponse(ApiModel):
    title: str
    items: List[str]


class StoryCraftSectionResponse(ApiModel):
    title: str
    description: str
    previewLabel: str


class StoryCtaSectionResponse(ApiModel):
    description: str
    buttonLabel: str


class StoryPageResponse(ApiModel):
    headerTitle: str
    heroTitle: str
    heroDescription: str
    heroBadge: str
    timelineTitle: str
    timelineItems: List[StoryTimelineItemResponse]
    imageTimelineTitle: str
    imageTimelineItems: List[StoryImageTimelineItemResponse]
    values: StorySectionResponse
    craft: StoryCraftSectionResponse
    cta: StoryCtaSectionResponse
    footerLabel: str
