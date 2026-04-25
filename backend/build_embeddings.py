"""
build_embeddings.py — Chạy 1 lần để tạo embedding cho tất cả skills trong MongoDB.

Usage:
    cd backend
    python build_embeddings.py
"""
import asyncio
import sys
import os

# Fix Windows terminal encoding
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

# Them backend vao path
sys.path.insert(0, os.path.dirname(__file__))

from dotenv import load_dotenv
load_dotenv()

from sentence_transformers import SentenceTransformer
from motor.motor_asyncio import AsyncIOMotorClient
from core.config import settings


MODEL_NAME = "paraphrase-multilingual-MiniLM-L12-v2"


async def build():
    print(f"[1/4] Tải embedding model: {MODEL_NAME}")
    embedder = SentenceTransformer(MODEL_NAME)
    print("      ✅ Model loaded!")

    print("[2/4] Kết nối MongoDB...")
    client = AsyncIOMotorClient(settings.MONGO_URL)
    db = client[settings.DB_NAME]
    print("      ✅ Connected!")

    print("[3/4] Tạo embedding cho Skills...")
    skills = await db.skills.find({}).to_list(length=1000)
    print(f"      Tìm thấy {len(skills)} skills")

    updated = 0
    for s in skills:
        # Kết hợp title + description + content để tạo embedding phong phú
        text_parts = [
            s.get("title", ""),
            s.get("description", ""),
            s.get("content", "")[:500],  # Giới hạn content
        ]
        text = " ".join([p for p in text_parts if p]).strip()
        if not text:
            continue

        embedding = embedder.encode(text).tolist()
        await db.skills.update_one(
            {"_id": s["_id"]},
            {"$set": {"embedding": embedding}}
        )
        updated += 1
        print(f"      [{updated}/{len(skills)}] ✅ {s.get('title', 'unknown')}")

    print(f"[4/4] Hoàn thành! Đã tạo embedding cho {updated} skills.")
    print()
    print("Kiểm tra nhanh:")
    sample = await db.skills.find_one({"embedding": {"$exists": True}})
    if sample:
        emb_len = len(sample.get("embedding", []))
        print(f"  ✅ Sample: '{sample.get('title')}' → embedding dim = {emb_len}")
    else:
        print("  ❌ Không tìm thấy skill nào có embedding!")

    client.close()


if __name__ == "__main__":
    asyncio.run(build())
