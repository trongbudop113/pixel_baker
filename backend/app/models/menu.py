from typing import List, Optional

from app.models.common import ApiModel


class MenuIntroSection(ApiModel):
    title: str
    description: str


class MenuFilterOption(ApiModel):
    label: str
    category: str
    imageUrl: Optional[str] = None


class MenuProductResponse(ApiModel):
    id: int
    title: str
    price: str
    priceValue: int
    category: str
    description: str
    images: List[str]
    ingredientsText: str = ""
    optionGroups: List["ProductOptionGroup"] = []
    averageRating: float = 0
    reviewCount: int = 0
    mooncakeConfig: Optional["MooncakeProductConfig"] = None


class ProductOptionItem(ApiModel):
    id: str
    label: str
    priceDelta: int = 0
    isDefault: bool = False


class ProductOptionGroup(ApiModel):
    id: str
    label: str
    options: List[ProductOptionItem]


class MooncakeEggOption(ApiModel):
    count: int
    label: str
    priceValue: int
    price: str


class MooncakeWeightOption(ApiModel):
    code: str
    label: str
    eggOptions: List[MooncakeEggOption]


class MooncakeBoxOption(ApiModel):
    code: str
    label: str
    cakeCount: int
    imageUrl: str
    packagePriceValue: int = 0
    packagePrice: str = ""


class MooncakeProductConfig(ApiModel):
    weightOptions: List[MooncakeWeightOption]
    boxOptions: List[MooncakeBoxOption]


class MenuReviewItem(ApiModel):
    author: str
    content: str
    rating: int = 5
    mediaUrls: List[str] = []
    createdAt: Optional[str] = None
    userId: Optional[str] = None


class MenuReviewCreateRequest(ApiModel):
    rating: int
    content: str
    mediaUrls: List[str] = []


class MenuProductDetailResponse(MenuProductResponse):
    sku: str
    stockStatus: str
    weight: str
    storageNote: str
    deliveryNote: str
    detailBullets: List[str]
    reviews: List[MenuReviewItem]
    relatedProducts: List[MenuProductResponse]


class MenuComboSection(ApiModel):
    title: str
    description: str
    actionLabel: str


class MenuFaqItem(ApiModel):
    question: str
    answer: str


class MenuFooterSection(ApiModel):
    tagline: str


class MenuPageResponse(ApiModel):
    intro: MenuIntroSection
    filters: List[MenuFilterOption]
    productsSectionTitle: str
    products: List[MenuProductResponse]
    combo: MenuComboSection
    faqs: List[MenuFaqItem]
    footer: MenuFooterSection
