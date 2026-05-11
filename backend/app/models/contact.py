from typing import List, Optional

from app.models.common import ApiModel


class ContactInfoCardResponse(ApiModel):
    title: str
    lines: List[str] = []
    previewLabel: Optional[str] = None


class ContactFormFieldResponse(ApiModel):
    label: str
    placeholder: str
    multiline: bool = False


class ContactPageResponse(ApiModel):
    heroTitle: str
    heroDescription: str
    formTitle: str
    submitLabel: str
    mobileTitle: str
    mobileBadge: str
    fields: List[ContactFormFieldResponse]
    infoCards: List[ContactInfoCardResponse]
    bottomNavLabels: List[str]


class ContactSubmitRequest(ApiModel):
    fullName: str
    email: str
    phone: Optional[str] = None
    message: str


class ContactSubmitResponse(ApiModel):
    message: str
