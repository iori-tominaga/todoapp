import sqlite3
import uuid
from contextlib import contextmanager
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

DB_PATH = Path("todos.db")
STATIC_DIR = Path("static")

app = FastAPI(title="TodoApp")


def init_db():
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS todos (
                id TEXT PRIMARY KEY,
                text TEXT NOT NULL,
                done INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
            )
            """
        )


@contextmanager
def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


class TodoCreate(BaseModel):
    text: str


class TodoUpdate(BaseModel):
    text: str | None = None
    done: bool | None = None


@app.on_event("startup")
def startup():
    init_db()


@app.get("/", response_class=HTMLResponse)
def index():
    return FileResponse(STATIC_DIR / "index.html")


@app.get("/api/todos")
def list_todos():
    with get_db() as db:
        rows = db.execute(
            "SELECT id, text, done, created_at FROM todos ORDER BY created_at DESC"
        ).fetchall()
    return [dict(r) for r in rows]


@app.post("/api/todos", status_code=201)
def create_todo(body: TodoCreate):
    if not body.text.strip():
        raise HTTPException(status_code=422, detail="text must not be empty")
    todo_id = str(uuid.uuid4())
    with get_db() as db:
        db.execute(
            "INSERT INTO todos (id, text) VALUES (?, ?)",
            (todo_id, body.text.strip()),
        )
    return {"id": todo_id, "text": body.text.strip(), "done": 0}


@app.patch("/api/todos/{todo_id}")
def update_todo(todo_id: str, body: TodoUpdate):
    with get_db() as db:
        row = db.execute("SELECT * FROM todos WHERE id = ?", (todo_id,)).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Todo not found")
        new_text = body.text.strip() if body.text is not None else row["text"]
        new_done = int(body.done) if body.done is not None else row["done"]
        db.execute(
            "UPDATE todos SET text = ?, done = ? WHERE id = ?",
            (new_text, new_done, todo_id),
        )
    return {"id": todo_id, "text": new_text, "done": new_done}


@app.delete("/api/todos/{todo_id}", status_code=204)
def delete_todo(todo_id: str):
    with get_db() as db:
        result = db.execute("DELETE FROM todos WHERE id = ?", (todo_id,))
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="Todo not found")
