# from __future__ import annotations

# from bson import ObjectId
# from pydantic import BaseModel, ConfigDict, field_serializer


# class PyObjectId(ObjectId):
#     """Custom ObjectId type compatible with Pydantic v2."""

#     @classmethod
#     def __get_validators__(cls):  # type: ignore[override]
#         yield cls.validate

#     @classmethod
#     def validate(cls, value: str | bytes | ObjectId) -> ObjectId:
#         if isinstance(value, ObjectId):
#             return value
#         if isinstance(value, bytes):
#             value = value.decode()
#         if not ObjectId.is_valid(value):
#             raise ValueError("Invalid ObjectId")
#         return ObjectId(value)

#     @classmethod
#     def __get_pydantic_json_schema__(cls, _schema, _handler):  # type: ignore[override]
#         return {"type": "string", "pattern": "^[0-9a-fA-F]{24}$"}


# class MongoModel(BaseModel):
#     """Base model with MongoDB friendly configuration."""

#     model_config = ConfigDict(populate_by_name=True, arbitrary_types_allowed=True)

#     id: PyObjectId | None = None

#     @field_serializer("id")
#     def serialize_id(self, value: PyObjectId | None) -> str | None:
#         return str(value) if value is not None else None

from __future__ import annotations

from typing import Any

from bson import ObjectId
from pydantic import BaseModel, ConfigDict, field_serializer
from pydantic_core import core_schema


class PyObjectId(ObjectId):
    """Custom ObjectId type compatible with Pydantic v2."""

    @classmethod
    def __get_pydantic_core_schema__(cls, _source: Any, _handler: Any) -> core_schema.CoreSchema:
        # One validator that accepts ObjectId | str | bytes and always returns ObjectId
        def _validate(v: Any) -> ObjectId:
            if isinstance(v, ObjectId):
                return v
            if isinstance(v, bytes):
                v = v.decode()
            if isinstance(v, str) and ObjectId.is_valid(v):
                return ObjectId(v)
            raise ValueError("Invalid ObjectId")

        # Accept both JSON (string) and Python inputs, and serialize as string
        return core_schema.json_or_python_schema(
            json_schema=core_schema.no_info_before_validator_function(
                _validate, core_schema.str_schema()
            ),
            python_schema=core_schema.no_info_before_validator_function(
                _validate,
                core_schema.union_schema(
                    [
                        core_schema.is_instance_schema(ObjectId),
                        core_schema.bytes_schema(),
                        core_schema.str_schema(),
                    ]
                ),
            ),
            serialization=core_schema.plain_serializer_function_ser_schema(
                lambda v: str(v), when_used="json-unless-none"
            ),
        )

    @classmethod
    def __get_pydantic_json_schema__(cls, schema: core_schema.CoreSchema, handler: Any) -> dict:
        # Ensure OpenAPI/JSON Schema shows it as a 24-hex string
        json_schema = handler(schema)
        json_schema.update({"type": "string", "pattern": "^[0-9a-fA-F]{24}$"})
        return json_schema


class MongoModel(BaseModel):
    """Base model with MongoDB-friendly configuration."""

    model_config = ConfigDict(populate_by_name=True, arbitrary_types_allowed=True)

    id: PyObjectId | None = None

    @field_serializer("id")
    def serialize_id(self, value: PyObjectId | None) -> str | None:
        return str(value) if value is not None else None
