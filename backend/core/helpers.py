from bson import ObjectId


def serialize_doc(doc: dict) -> dict:
    """Chuyển _id: ObjectId → id: str để JSON serializable (Flutter hiểu được).
    
    MongoDB bug kinh điển: ObjectId không thể serialize thành JSON trực tiếp.
    Hàm này cần được gọi trước khi return bất kỳ document nào từ MongoDB.
    """
    if doc and "_id" in doc:
        doc["id"] = str(doc.pop("_id"))
    return doc


def serialize_list(docs: list) -> list:
    """Serialize danh sách documents."""
    return [serialize_doc(d) for d in docs]


def to_object_id(id_str: str) -> ObjectId:
    """Chuyển string ID thành ObjectId, raise ValueError nếu không hợp lệ."""
    try:
        return ObjectId(id_str)
    except Exception:
        raise ValueError(f"ID không hợp lệ: {id_str}")
