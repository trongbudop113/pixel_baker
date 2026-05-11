from datetime import datetime
from typing import Dict, List, Optional

from app.models.common import ApiModel, UiAccent


class HomeActionLink(ApiModel):
    label: str
    routeName: Optional[str] = None
    routePath: Optional[str] = None
    queryParameters: Dict[str, str] = {}


class HomeHeroSection(ApiModel):
    title: str
    description: str
    primaryAction: HomeActionLink
    secondaryAction: HomeActionLink


class HomeInfoHighlight(ApiModel):
    title: str
    description: str
    accent: UiAccent


class HomeFeaturedProduct(ApiModel):
    productId: int
    title: str
    price: str
    imageUrl: str
    titleAccent: UiAccent
    priceAccent: UiAccent
    averageRating: float = 0
    reviewCount: int = 0


class HomeStorySection(ApiModel):
    title: str
    description: str
    badgeText: str


class HomeCategory(ApiModel):
    label: str
    routeCategory: str
    accent: UiAccent


class HomeTestimonial(ApiModel):
    id: Optional[str] = None
    content: str
    author: str
    accent: UiAccent
    createdAt: Optional[datetime] = None


class CreateHomeTestimonialRequest(ApiModel):
    content: str


class HomeFaq(ApiModel):
    question: str
    answer: str
    accent: UiAccent


class HomePromoBanner(ApiModel):
    message: str
    action: HomeActionLink


class HomeFooterSection(ApiModel):
    tagline: str
    links: List[HomeActionLink]


class HomePageResponse(ApiModel):
    hero: HomeHeroSection
    highlights: List[HomeInfoHighlight]
    featuredProducts: List[HomeFeaturedProduct]
    story: HomeStorySection
    categories: List[HomeCategory]
    testimonials: List[HomeTestimonial]
    faqs: List[HomeFaq]
    promo: HomePromoBanner
    footer: HomeFooterSection
