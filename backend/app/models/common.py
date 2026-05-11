from enum import Enum

from pydantic import BaseModel, ConfigDict


class ApiModel(BaseModel):
    model_config = ConfigDict(populate_by_name=True, from_attributes=True)


class UiAccent(str, Enum):
    red = "red"
    blue = "blue"
    green = "green"
    gray = "gray"
    orange = "orange"
