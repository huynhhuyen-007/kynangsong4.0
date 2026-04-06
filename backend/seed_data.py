import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from datetime import datetime, timezone

MONGO_URL = "mongodb+srv://huynhhuyen01022004_db_user:JnR2UDe7WftTl4nL@cluster0.zpr4s7u.mongodb.net/?appName=Cluster0"
DB_NAME = "ky_nang_song"

news_data = [
    {
        "title": "Cẩm nang an toàn: Kỹ năng sinh tồn khi xảy ra hỏa hoạn",
        "summary": "10 bước cơ bản giúp bạn và gia đình an toàn khi sống ở chung cư và đối mặt với sự cố cháy nổ.",
        "content": "Hỏa hoạn là một trong những tai nạn nguy hiểm nhất.\n\nĐê bảo vệ bản thân và gia đình:\n1. Bình tĩnh và giữ thấp người (khí độc bay ở trên).\n2. Dùng khăn ướt che mũi miệng.\n3. Tuyệt đối không sử dụng thang máy.\n4. Tìm lối ra lối thoát hiểm gần nhất.\n\nTrong trường hợp bị mắc kẹt, hãy chặn khe cửa bằng đồ ướt và ra ban công gọi cứu hộ 114.",
        "image_url": "https://images.unsplash.com/photo-1549468057-5ce754b4fa66?q=80&w=600&auto=format&fit=crop",
        "author": "Đội PCCC",
        "created_at": datetime.now(timezone.utc).isoformat()
    },
    {
        "title": "Nghệ thuật giao tiếp: Cách nói chuyện tự tin trước đám đông",
        "summary": "Mọi người đều sợ nói trước đám đông, nhưng đây là kỹ năng có thể luyện tập.",
        "content": "Sợ hãi khi thuyết trình là bản năng tự nhiên. Nhưng bạn có thể vượt qua nó bằng cách: \n- Chuẩn bị thật kỹ nội dung và thiết kế Slide bắt mắt.\n- Luyện tập trước gương hoặc với nhóm nhỏ.\n- Hít thở sâu trước khi bắt đầu.\n- Giao tiếp bằng mắt với người nghe.\n- Sử dụng ngôn ngữ cơ thể thoải mái, tự tin.",
        "image_url": "https://images.unsplash.com/photo-1475721027785-f74eccf877e2?q=80&w=600&auto=format&fit=crop",
        "author": "Master Communication",
        "created_at": datetime.now(timezone.utc).isoformat()
    },
    {
        "title": "Quản lý tài chính cá nhân cho học sinh, sinh viên",
        "summary": "Cách tiết kiệm tiền hiệu quả và không bị viêm màng túi vào cuối tháng.",
        "content": "Sinh viên thường xuyên gặp cảnh đầu tháng ăn nhà hàng, cuối tháng ăn mì gói.\n\nHãy lập ngân sách theo quy tắc 50-30-20:\n- 50% nhu cầu thiết yếu (nhà ở, ăn uống, đi lại)\n- 30% sở thích cá nhân\n- 20% rèn luyện và tiết kiệm dự phòng.\n\nHãy ưu tiên ghi chép các khoản chi tiêu mỗi cuối ngày.",
        "image_url": "https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?q=80&w=600&auto=format&fit=crop",
        "author": "Admin Tài chính",
        "created_at": datetime.now(timezone.utc).isoformat()
    }
]

fun_data = [
    {
        "title": "Mẹo vặt: Mở nắp hộp thủy tinh siêu chặt cực nhanh",
        "type": "tip",
        "media_url": "https://images.unsplash.com/photo-1627485937980-221c88ce04ea?q=80&w=600&auto=format&fit=crop",
        "content": "Nếu lọ mứt nhà bạn vặn quá chặt, hãy chúi ngược và nhúng nắp hộp ngập nước nóng 30 giây để giãn nở. Hoặc đơn giản là dùng một dây thun nịt cuốn quanh viền nắp để bám tay hơn 10 độ.",
        "created_at": datetime.now(timezone.utc).isoformat()
    },
    {
        "title": "Khám phá: Những vùng đất lạnh giá nhất thế giới",
        "type": "video",
        "media_url": "https://images.unsplash.com/photo-1478719059408-592965723cbc?q=80&w=600&auto=format&fit=crop",
        "content": "Khám phá những vùng thuộc Oymyakon, nơi nhiệt độ có thể xuống -71 độ C khiến mọi thứ lập tức đông cứng.",
        "created_at": datetime.now(timezone.utc).isoformat()
    },
    {
        "title": "Cảm hứng mỗi ngày",
        "type": "tip",
        "media_url": "https://images.unsplash.com/photo-1499750310107-5fef28a66643?q=80&w=600&auto=format&fit=crop",
        "content": "\"Người thành công không bao giờ từ bỏ, còn người từ bỏ không bao giờ thành công.\" Cuộc sống là một cuộc chạy Marathon, hãy bền bỉ rèn luyện mỗi ngày.",
        "created_at": datetime.now(timezone.utc).isoformat()
    }
]

skills_data = [
    {
        "title": "Kỹ năng sơ cứu cầm máu khẩn cấp",
        "category": "Sức khỏe & Y tế",
        "description": "Biết cách cầm máu và sát trùng vết thương hở để tránh nhiễm trùng nghiêm trọng trước khi được cấp cứu.",
        "image_url": "https://images.unsplash.com/photo-1599422314077-f4dfdaa4cd09?q=80&w=600&auto=format&fit=crop",
        "content": "Việc cần làm ngay khi gặp người bị thương:\n1. Rửa tay sát khuẩn nhanh nếu có thể.\n2. Dùng vải/gạc thật sạch ép chặt khu vực vết thương.\n3. Nâng cao vùng bị thương (như tay, chân) cao hơn tim để giảm dòng máu.\n4. Đưa nạn nhân đến trạm y tế gần nhất.",
        "duration_minutes": 10,
        "created_at": datetime.now(timezone.utc).isoformat()
    },
    {
        "title": "Kỹ năng thoát hiểm võ thuật cơ bản",
        "category": "Sinh tồn",
        "description": "Bỏ túi những mẹo thoát thân khi bị nắm tóc, vòng cổ hoặc khống chế bất ngờ.",
        "image_url": "https://images.unsplash.com/photo-1558005391-ab51411cefb4?q=80&w=600&auto=format&fit=crop",
        "content": "Nguyên tắc VÀNG: Bỏ chạy luôn là hạ sách nhưng an toàn nhất.\n- Nếu bị nắm cổ tay: Hãy giật mạnh xoay về hướng khe hở giữa ngón cái và ngón trỏ của kẻ xấu.\n- Nếu bị ôm từ phía sau: Dậm mạnh gót chân bạn vào mu bàn chân của hắn, sau đó húc đầu mạnh về sau.\n- Hô hoán \"CỨU CHÁY!\" thay vì \"Cứu tôi\" để thu hút đông người hơn.",
        "duration_minutes": 15,
        "created_at": datetime.now(timezone.utc).isoformat()
    },
    {
        "title": "Bảo mật tài khoản ngân hàng & Mạng",
        "category": "An toàn Số",
        "description": "Kỹ năng nhận diện lừa đảo SMS và cách thiết lập bức tường phòng thủ ảo.",
        "image_url": "https://images.unsplash.com/photo-1555949963-aa79dcee981c?q=80&w=600&auto=format&fit=crop",
        "content": "- Không nhận link lạ từ bất kể người thân nhắn qua Facebook (họ có thể bị hack).\n- Bật tính năng Xác thực 2 bước (2 Fac Auth) cho mọi nền tảng.\n- Không bao giờ đặt mật khẩu chung cho Ngân Hàng và Mạng xã hội.",
        "duration_minutes": 8,
        "created_at": datetime.now(timezone.utc).isoformat()
    }
]

posts_data = [
    {
        "user_id": "global_admin_id",
        "user_name": "Tuấn Anh (Admin)",
        "content": "Chào mừng các bạn đến với Cộng đồng Kỹ năng sống 4.0! Mọi người hãy thoải mái chia sẻ trải nghiệm, bài học hoặc đặt câu hỏi về các kỹ năng ở đây nhé. 😉",
        "topic": "Chung",
        "likes": ["user_1", "user_2"],
        "likes_count": 2,
        "comments_count": 0,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "is_hidden": False,
        "is_pinned": True,
    },
    {
        "user_id": "user_id_123",
        "user_name": "Minh Nhật",
        "content": "Hôm nay mới đọc mẹo về quản lý tài chính sinh viên. Mọi người có app nào track chi tiêu dễ dùng và hoàn toàn miễn phí không gợi ý cho mình với?",
        "topic": "Hỏi đáp",
        "likes": [],
        "likes_count": 0,
        "comments_count": 0,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "is_hidden": False,
        "is_pinned": False,
    },
    {
        "user_id": "user_id_456",
        "user_name": "Hải Yến",
        "content": "Vừa học xong kỹ năng sơ cứu! Thật sự rất bổ ích các bạn ạ. Chắc chắn tháng tới sau khi nhận lương mình sẽ đầu tư ngay 1 bộ kit sơ cứu ở nhà.",
        "topic": "Chia sẻ",
        "likes": ["global_admin_id", "user_id_123"],
        "likes_count": 2,
        "comments_count": 0,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "is_hidden": False,
        "is_pinned": False,
    }
]

async def seed():
    client = AsyncIOMotorClient(MONGO_URL)
    db = client[DB_NAME]
    
    # Xóa dữ liệu cũ
    await db["news"].delete_many({})
    await db["fun"].delete_many({})
    await db["skills"].delete_many({})
    await db["posts"].delete_many({})
    
    # Thêm dữ liệu mới
    await db["news"].insert_many(news_data)
    await db["fun"].insert_many(fun_data)
    await db["skills"].insert_many(skills_data)
    await db["posts"].insert_many(posts_data)
    print("✅ Đã bơm Mock Data thành công cho Trang Tin Tức, Vui học, Kỹ năng và Cộng đồng!")
    client.close()

if __name__ == "__main__":
    asyncio.run(seed())
