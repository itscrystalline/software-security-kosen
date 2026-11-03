"""
Tiny sample web app for Week 1 threat modeling.
You will NOT exploit this in Week 1 — you will draw a data-flow diagram
and apply STRIDE to its components (web client, app, SQLite DB, /upload).
"""
from flask import Flask, request, jsonify, send_from_directory
from werkzeug.utils import secure_filename
import sqlite3, os, uuid

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = 2 * 1024 * 1024
DB = "notes.db"
UPLOAD_DIR = os.path.realpath("uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)
ALLOWED_EXTENSIONS = {".txt", ".md", ".png", ".jpg", ".jpeg", ".pdf"}

def init_db():
    con = sqlite3.connect(DB)
    con.execute("CREATE TABLE IF NOT EXISTS notes (id INTEGER PRIMARY KEY, owner TEXT, body TEXT)")
    con.commit(); con.close()

@app.route("/notes", methods=["GET", "POST"])
def notes():
    con = sqlite3.connect(DB)
    if request.method == "POST":
        owner = request.json.get("owner", "anon")
        body = request.json.get("body", "")
        con.execute("INSERT INTO notes (owner, body) VALUES (?, ?)", (owner, body))
        con.commit()
    rows = con.execute("SELECT id, owner, body FROM notes").fetchall()
    con.close()
    return jsonify(rows)

@app.route("/upload", methods=["POST"])
def upload():
    f = request.files.get("file")
    if f is None or not f.filename:
        return {"error": "file field required"}, 400
    client_name = f.filename
    name = secure_filename(client_name)
    # The client's string is metadata, never a path: a name that is not already one
    # plain component is refused, not repaired into something else.
    if not name or name != client_name:
        return {"error": "filename must be a plain file name"}, 400
    ext = os.path.splitext(name)[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        return {"error": "extension not allowed"}, 400
    stored = uuid.uuid4().hex + ext          # server-generated path component
    dest = os.path.realpath(os.path.join(UPLOAD_DIR, stored))
    if os.path.dirname(dest) != UPLOAD_DIR:  # containment check
        return {"error": "invalid path"}, 400
    f.save(dest)
    return {"saved": stored}

@app.route("/files/<name>")
def files(name):
    return send_from_directory(UPLOAD_DIR, name)

if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=5000)
