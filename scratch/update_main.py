import re

with open("backend/main.py", "r", encoding="utf-8") as f:
    text = f.read()

# Delete get_lessons block
p_get_lessons = re.compile(r'@app\.get\("/api/skills/\{skill_id\}/lessons"\)\n.*?(?=@app\.post\("/api/learning/progress"\))', re.S)
text = p_get_lessons.sub("\n", text)

# Delete update_learning_progress block
p_prog = re.compile(r'@app\.post\("/api/learning/progress"\)\n.*?(?=class QuizSubmit)', re.S)
text = p_prog.sub("\n", text)

# Delete get_lesson_quiz and submit
p_quiz = re.compile(r'@app\.get\("/api/learning/quiz/\{lesson_id\}"\)\n.*?(?=@app\.get\("/api/ai/recommendation/\{user_id\}"\))', re.S)
text = p_quiz.sub("\n", text)

# Append routers
addition = """
# ── REGISTER EXTRACTED ROUTERS ──────────────────────────────────────────────
from routers.auth_router import router as auth_router
from routers.news_router import router as news_router
from routers.lesson_router import router as lesson_router

app.include_router(auth_router)
app.include_router(news_router)
app.include_router(lesson_router)
"""

if "app.include_router(auth_router)" not in text:
    text += addition

with open("backend/main.py", "w", encoding="utf-8") as f:
    f.write(text)
