import json
import sqlite3
from pathlib import Path

db = Path.home() / ".cc-switch" / "cc-switch.db"
con = sqlite3.connect(f"file:{db.as_posix()}?mode=ro", uri=True)
row = con.execute(
    "SELECT settings_config FROM providers WHERE id = 'default' AND app_type = 'codex'"
).fetchone()
if not row:
    raise SystemExit("cc-switch codex provider not found")
key = json.loads(row[0])["auth"]["OPENAI_API_KEY"]
print(key, end="")
