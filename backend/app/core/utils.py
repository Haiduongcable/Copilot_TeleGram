from __future__ import annotations

from datetime import datetime
from typing import Any

from bson import ObjectId


def to_object_id(value: Any) -> ObjectId:
    if isinstance(value, ObjectId):
        return value
    if isinstance(value, str) and ObjectId.is_valid(value):
        return ObjectId(value)
    raise ValueError("Invalid ObjectId")


def utcnow() -> datetime:
    return datetime.utcnow()
