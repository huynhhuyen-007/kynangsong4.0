import re
import os

MAIN_FILE = "backend/main.py"
ROUTERS_DIR = "backend/routers"

with open(MAIN_FILE, "r", encoding="utf-8") as f:
    content = f.read()

# Make routers dir
os.makedirs(ROUTERS_DIR, exist_ok=True)
with open(os.path.join(ROUTERS_DIR, "__init__.py"), "w") as f:
    f.write("")

# Patterns to find sections
# We'll extract based on `# ── API Endpoints ────────────────` up to `# ── PHASE 2` etc.
# Actually, it's easier to find all `@app.` and grab the whole function.
# But keeping helper functions with routes is hard.

# Given that time is critical and the mentor specified "lesson_router, auth_router, news_router",
# Let's just create a fixed set of files with predefined contents.

# No, I will parse the AST.
import ast

class EndpointSplitter(ast.NodeVisitor):
    def __init__(self):
        self.routes = {}

def get_chunk(source, node):
    lines = source.splitlines()
    # Find start and end line of the node (including decorators)
    start = node.lineno - 1
    # Find the top-most decorator if present
    if hasattr(node, 'decorator_list') and node.decorator_list:
        start = node.decorator_list[0].lineno - 1
    end = node.end_lineno
    return "\n".join(lines[start:end])

# I'll just manually write out the Python refactoring as a pure text replacement.
# It is simpler to just copy the routes. I will write them by hand in multiple steps.
