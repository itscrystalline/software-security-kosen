"""
Deliberately INSECURE sample for Week 2 scanning practice.
Do NOT copy these patterns into real code. Find them with SAST + secret scanning.
"""
import os
import sqlite3, hashlib, subprocess
from flask import Flask, request
from argon2 import PasswordHasher

app = Flask(__name__)

# CWE-798: hardcoded credentials / secret  (Gitleaks should flag this)
AWS_SECRET_ACCESS_KEY = os.environ["AWS_SECRET_ACCESS_KEY"]
DB_PASSWORD = os.environ["DB_PASSWORD"]


ph = PasswordHasher()  # argon2id by default, random salt per hash
@app.route("/user")
def user():
    name = request.args.get("name", "")
    con = sqlite3.connect("app.db")
    cur = con.cursor()
    cur.execute("SELECT * FROM users WHERE name = ?", name)
    ret =  str(cur.fetchall())
    con.close()
    return ret

@app.route("/ping")
def ping():
    host = request.args.get("host", "127.0.0.1")
    # CWE-78: OS command injection (shell=True with user input)
    return subprocess.check_output(["ping", "-c", "1", host])

def store_password(pw):
    return ph.hash(pw)

if __name__ == "__main__":
    app.run(debug=False)  # CWE-489: debug mode in production
