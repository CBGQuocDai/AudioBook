#!/usr/bin/env python3
import argparse
import json
import math
import os
import random
import re
import subprocess
import sys
import time
import wave
from pathlib import Path
from urllib import request, error


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "demo-assets"
DEFAULT_PASSWORD = "123456"


def ensure_package(module_name, package_name=None):
    try:
        return __import__(module_name)
    except ImportError:
        package_name = package_name or module_name
        has_pip = subprocess.run(
            [sys.executable, "-m", "pip", "--version"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        ).returncode == 0
        if not has_pip:
            return None
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "--user", package_name])
            return __import__(module_name)
        except Exception:
            return None


bcrypt = ensure_package("bcrypt")
pymysql = ensure_package("pymysql", "PyMySQL")
if bcrypt is None:
    raise RuntimeError("Python package 'bcrypt' is required to generate bcrypt(12) passwords.")


def load_env():
    env = {}
    for env_path in (ROOT / ".env", ROOT / "src/main/.env"):
        if not env_path.exists():
            continue
        for raw in env_path.read_text(encoding="utf-8").splitlines():
            line = raw.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            env[key.strip()] = value.strip().strip('"').strip("'")
    return env


def parse_mysql(env):
    if pymysql is None:
        raise RuntimeError(
            "Python package 'PyMySQL' is required for DB seeding, but this Python has no pip. "
            "Install it with your OS package manager or run this script in a venv that has PyMySQL."
        )
    url = env.get("DB_URL", "jdbc:mysql://localhost:3306/audio_book")
    match = re.search(r"jdbc:mysql://([^:/?]+)(?::(\d+))?/([^?]+)", url)
    if not match:
        raise RuntimeError(f"Unsupported DB_URL: {url}")
    return {
        "host": match.group(1),
        "port": int(match.group(2) or 3306),
        "database": match.group(3),
        "user": env.get("DB_USERNAME", "root"),
        "password": env.get("DB_PASSWORD", "12345"),
        "charset": "utf8mb4",
        "autocommit": False,
        "cursorclass": pymysql.cursors.DictCursor,
    }


def wait_for_db(cfg, timeout=90):
    deadline = time.time() + timeout
    last_error = None
    while time.time() < deadline:
        try:
            conn = pymysql.connect(**cfg)
            conn.close()
            return
        except Exception as exc:
            last_error = exc
            time.sleep(2)
    raise RuntimeError(f"MySQL is not ready: {last_error}")


def http_json(method, url, payload=None, token=None, expect=(200,), timeout=30):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = None if payload is None else json.dumps(payload, ensure_ascii=False).encode("utf-8")
    req = request.Request(url, data=data, headers=headers, method=method)
    try:
        with request.urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode("utf-8")
            parsed = json.loads(body) if body else {}
            if resp.status not in expect:
                raise RuntimeError(f"{method} {url} expected {expect}, got {resp.status}: {parsed}")
            return resp.status, parsed
    except error.HTTPError as exc:
        body = exc.read().decode("utf-8")
        parsed = json.loads(body) if body else {}
        if exc.code not in expect:
            raise RuntimeError(f"{method} {url} expected {expect}, got {exc.code}: {parsed}") from exc
        return exc.code, parsed


def wait_for_api(base_url, timeout=120):
    deadline = time.time() + timeout
    last_error = None
    while time.time() < deadline:
        try:
            http_json("POST", f"{base_url}/auth/login", {"email": "missing@test.com", "password": "bad"}, expect=(400, 401, 500))
            return
        except Exception as exc:
            last_error = exc
            time.sleep(2)
    raise RuntimeError(f"API is not ready: {last_error}")


def password_hash():
    return bcrypt.hashpw(DEFAULT_PASSWORD.encode("utf-8"), bcrypt.gensalt(rounds=12)).decode("utf-8")


def upsert_accounts(conn):
    hashed = password_hash()
    users = [
        ("admin@test.com", "Quản trị viên", "ADMIN", None),
        ("minh.user@test.com", "Minh An", "USER", 260),
        ("linh.user@test.com", "Linh Chi", "USER", 180),
    ]
    with conn.cursor() as cur:
        for email, name, role, credit in users:
            cur.execute(
                """
                INSERT INTO users(password, name, email, active, role, created_by, last_modified_by)
                VALUES(%s, %s, %s, 1, %s, 'seed', 'seed')
                ON DUPLICATE KEY UPDATE
                  password=VALUES(password), name=VALUES(name), active=1, role=VALUES(role), last_modified_by='seed'
                """,
                (hashed, name, email, role),
            )
            cur.execute("SELECT id FROM users WHERE email=%s", (email,))
            user_id = cur.fetchone()["id"]
            if role == "ADMIN":
                cur.execute("INSERT IGNORE INTO admin(user_id) VALUES(%s)", (user_id,))
            else:
                cur.execute(
                    """
                    INSERT INTO client(user_id, total_credit) VALUES(%s, %s)
                    ON DUPLICATE KEY UPDATE total_credit=VALUES(total_credit)
                    """,
                    (user_id, credit),
                )
    conn.commit()


def ensure_file(conn, file_name, file_path, url, file_type):
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO file(file_name, file_path, url, type, created_by, last_modified_by)
            VALUES(%s, %s, %s, %s, 'seed', 'seed')
            ON DUPLICATE KEY UPDATE file_path=VALUES(file_path), url=VALUES(url), type=VALUES(type)
            """,
            (file_name, file_path, url, file_type),
        )
        cur.execute("SELECT id FROM file WHERE file_name=%s ORDER BY id DESC LIMIT 1", (file_name,))
        row = cur.fetchone()
    conn.commit()
    return row["id"]


def build_story(words_target=10000):
    scenes = [
        "Bến ga nhỏ bên sông thức dậy trong mùi cà phê rang và tiếng bánh xe lăn trên nền gạch cũ.",
        "An cầm cuốn sổ bìa xanh, ghi lại từng âm thanh của thành phố để hoàn thành kho lưu trữ ký ức.",
        "Mỗi người khách để lại một câu chuyện: người thợ đồng hồ, cô giáo nghỉ hưu, và cậu bé bán bản đồ.",
        "Khi mưa xuống, những lời kể hòa vào tiếng mái tôn, mở ra manh mối về chuyến tàu đã biến mất mười năm trước.",
        "An hiểu rằng điều cần tìm không phải kho báu, mà là lời hứa đưa mọi người trở về với điều họ từng yêu quý.",
    ]
    words = []
    chapter = 1
    while len(words) < words_target:
        paragraph = f"Chương {chapter}. " + " ".join(scenes)
        paragraph += " Câu chuyện tiếp tục bằng những lựa chọn nhỏ, tử tế và có hậu, để người nghe cảm thấy hành trình này thật sự đáng nhớ."
        words.extend(paragraph.split())
        chapter += 1
    return " ".join(words[:words_target])


def make_wav(path, seconds=75, sample_rate=22050):
    # Fallback audio keeps the API demo self-contained when no local TTS engine exists.
    with wave.open(str(path), "w") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(sample_rate)
        for i in range(seconds * sample_rate):
            t = i / sample_rate
            freq = 220 + 55 * math.sin(t / 3)
            amp = int(9000 * math.sin(2 * math.pi * freq * t))
            out.writeframesraw(amp.to_bytes(2, byteorder="little", signed=True))


def create_assets(conn):
    ASSET_DIR.mkdir(exist_ok=True)
    story_path = ASSET_DIR / "ben-ga-ky-uc-10000-tu.txt"
    audio_path = ASSET_DIR / "ben-ga-ky-uc-demo.wav"
    story_path.write_text(json.dumps({
        "content": "<h1>Chapter 1</h1><p>%s</p><blockquote>Những ký ức tử tế luôn tìm được đường về.</blockquote>" % build_story()
    }, ensure_ascii=False), encoding="utf-8")
    if not audio_path.exists():
        make_wav(audio_path)

    story_id = ensure_file(conn, story_path.name, str(story_path), story_path.as_uri(), "document")
    audio_id = ensure_file(conn, audio_path.name, str(audio_path), audio_path.as_uri(), "audio")

    cover_ids = []
    for idx in range(1, 21):
        cover = ASSET_DIR / f"cover-{idx:02d}.txt"
        cover.write_text(f"Demo cover placeholder for audiobook {idx:02d}", encoding="utf-8")
        cover_ids.append(ensure_file(conn, cover.name, str(cover), cover.as_uri(), "image"))
    return story_id, audio_id, cover_ids


BOOKS = [
    ("Bến Ga Ký Ức", "Dương Minh", "Một cô gái thu thập âm thanh cũ để tìm lại chuyến tàu mất tích."),
    ("Mùa Mưa Ở Phố Cổ", "Hoài An", "Những lá thư dưới mái ngói dẫn ba người bạn về một lời hẹn bị quên."),
    ("Quán Cà Phê Sau Nửa Đêm", "Ngọc Lam", "Chủ quán ghi âm giấc mơ của khách và phát hiện một bí mật ấm áp."),
    ("Ngọn Hải Đăng Số Bảy", "Trần Vũ", "Người giữ đèn trẻ học cách dẫn đường cho cả làng trong đêm bão."),
    ("Thư Viện Trên Đồi Gió", "Mai Khánh", "Một thủ thư bảo vệ cuốn sách biết kể chuyện bằng giọng người đọc."),
    ("Dòng Sông Không Ngủ", "Hải Nam", "Người lái đò đi qua ký ức của thành phố để cứu một bến nước cũ."),
    ("Những Chiếc Đồng Hồ Lặng Im", "Bình Nguyên", "Một tiệm sửa đồng hồ lưu giữ thời khắc quan trọng nhất của mỗi gia đình."),
    ("Khu Vườn Của Mây", "Linh Đan", "Cô bé trồng những hạt giống nghe được tiếng lòng người lớn."),
    ("Bản Đồ Của Ánh Trăng", "Phúc Khang", "Hai anh em đi theo bản đồ đêm để tìm lại người cha thợ ảnh."),
    ("Tiệm May Màu Xanh", "Yến Nhi", "Người thợ may vá lại những mối quan hệ bằng từng đường kim kiên nhẫn."),
    ("Căn Nhà Có Ba Ban Công", "Quốc Bảo", "Ba thế hệ học cách sống chung qua những buổi đọc sách bên hiên."),
    ("Đường Tàu Qua Rừng Tràm", "Hà My", "Một chuyến tàu chậm mở ra hành trình trưởng thành của nhóm học trò."),
    ("Người Gác Cổng Mùa Xuân", "Tuấn Kiệt", "Ông gác cổng công viên giữ chìa khóa cho những cuộc gặp gỡ tử tế."),
    ("Âm Thanh Của Nắng", "Kim Chi", "Kỹ sư âm thanh tìm cách ghi lại tiếng nắng cho người mẹ khiếm thị."),
    ("Cầu Vồng Sau Xưởng Gỗ", "Đức Huy", "Một xưởng gỗ cũ trở thành nơi trẻ con dựng sân khấu kể chuyện."),
    ("Hòm Thư Ở Cuối Hẻm", "Thảo Vy", "Những bức thư không người nhận nối lại tình làng nghĩa xóm."),
    ("Ngày Thành Phố Tắt Đèn", "Minh Châu", "Khi mất điện, mọi người lần đầu nghe rõ tiếng nói của nhau."),
    ("Bức Tranh Còn Mùi Biển", "Anh Khoa", "Một họa sĩ trẻ theo dấu mùi biển để hoàn thành triển lãm của cha."),
    ("Chuyến Xe Buýt Số Mười Hai", "Gia Hân", "Tuyến xe cuối ngày chở theo những quyết định đổi đời."),
    ("Mật Mã Trong Tiếng Chuông", "Nhật Linh", "Tiếng chuông nhà thờ cũ hé lộ mật mã bảo vệ ký ức của thị trấn."),
]


def seed_api(base_url, conn, story_id, audio_id, cover_ids):
    _, login = http_json("POST", f"{base_url}/auth/login", {"email": "admin@test.com", "password": DEFAULT_PASSWORD})
    admin_token = login["data"]["token"]

    category_ids = []
    for name, desc in [
        ("Truyện ngắn", "Các tác phẩm ngắn, dễ nghe, giàu cảm xúc."),
        ("Đời sống", "Câu chuyện gần gũi về gia đình, công việc và thành phố."),
        ("Phiêu lưu nhẹ", "Hành trình khám phá có tiết tấu ấm áp."),
        ("Chữa lành", "Tác phẩm mang tinh thần lạc quan và nhân văn."),
    ]:
        _, resp = http_json("POST", f"{base_url}/admin/books/categories", {"name": name, "description": desc}, admin_token, expect=(200, 409))
        if resp.get("data", {}).get("id"):
            category_ids.append(resp["data"]["id"])

    if not category_ids:
        _, found = http_json("GET", f"{base_url}/categories", token=admin_token)
        category_ids = [item["id"] for item in found.get("data", [])[:4]]

    created_books = []
    for idx, (title, author, desc) in enumerate(BOOKS, start=1):
        chapters = [
            {"title": "Khởi đầu", "chapterNumber": 1, "durationSeconds": 900 + idx, "contentFileId": story_id, "audioFileId": audio_id},
            {"title": "Dấu hiệu", "chapterNumber": 2, "durationSeconds": 960 + idx, "contentFileId": story_id, "audioFileId": audio_id},
            {"title": "Lựa chọn", "chapterNumber": 3, "durationSeconds": 1020 + idx, "contentFileId": story_id, "audioFileId": audio_id},
            {"title": "Trở về", "chapterNumber": 4, "durationSeconds": 880 + idx, "contentFileId": story_id, "audioFileId": audio_id},
        ]
        payload = {
            "name": title,
            "author": author,
            "description": desc,
            "coverFileId": cover_ids[idx - 1],
            "categoryIds": [category_ids[(idx - 1) % len(category_ids)]],
            "ebookChapters": chapters,
            "descriptionImageFileIds": [],
        }
        _, resp = http_json("POST", f"{base_url}/admin/books", payload, admin_token)
        created_books.append(resp["data"])

    _, user_login = http_json("POST", f"{base_url}/auth/login", {"email": "minh.user@test.com", "password": DEFAULT_PASSWORD})
    user_token = user_login["data"]["token"]
    for book in created_books[:12]:
        http_json("POST", f"{base_url}/purchased/{book['id']}", token=user_token)
    for book in created_books[:8]:
        http_json("POST", f"{base_url}/books/favourite/{book['id']}", token=user_token)
    for book in created_books[:6]:
        ebook = book["ebookChapters"][0]
        http_json("POST", f"{base_url}/books/progress/audio", {
            "bookId": book["id"], "chapterId": ebook["id"], "currentTime": random.randint(60, 600),
            "duration": ebook["durationSeconds"], "progressPercent": random.uniform(12, 76), "playbackSpeed": 1.0
        }, token=user_token)
        http_json("POST", f"{base_url}/books/progress/ebook", {
            "bookId": book["id"], "chapterId": ebook["id"], "pageNumber": random.randint(3, 40),
            "offsetInPage": 0.45, "progressPercent": random.uniform(10, 82)
        }, token=user_token)

    return admin_token, user_token, created_books


def test_api(base_url, admin_token, user_token, first_book_id):
    checks = [
        ("admin dashboard", lambda: http_json("GET", f"{base_url}/admin/books/dashboard", token=admin_token)),
        ("book search", lambda: http_json("GET", f"{base_url}/books/search?keyword=Bến&page=0&limit=5", token=user_token)),
        ("book detail", lambda: http_json("GET", f"{base_url}/books/{first_book_id}", token=user_token)),
        ("trending", lambda: http_json("GET", f"{base_url}/books/trending?page=0&size=5", token=user_token)),
        ("favourites", lambda: http_json("GET", f"{base_url}/books/favourite", token=user_token)),
        ("purchased", lambda: http_json("GET", f"{base_url}/purchased?page=0&size=5", token=user_token)),
        ("invalid login", lambda: http_json("POST", f"{base_url}/auth/login", {"email": "admin@test.com", "password": "wrong"}, expect=(400, 401))),
        ("unauthorized me", lambda: http_json("GET", f"{base_url}/client/me", expect=(401, 403))),
        ("invalid book", lambda: http_json("POST", f"{base_url}/admin/books", {"name": "", "categoryIds": []}, token=admin_token, expect=(400,))),
    ]
    for name, fn in checks:
        status, body = fn()
        print(f"[ok] {name}: HTTP {status}, code={body.get('code')}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--api", default=None, help="Base API URL, default from SERVER_PORT: http://localhost:PORT/api")
    parser.add_argument("--skip-api", action="store_true", help="Only seed accounts and file metadata")
    args = parser.parse_args()

    env = load_env()
    port = env.get("SERVER_PORT", "8080")
    base_url = args.api or f"http://localhost:{port}/api"
    db_cfg = parse_mysql(env)

    wait_for_db(db_cfg)
    conn = pymysql.connect(**db_cfg)
    try:
        upsert_accounts(conn)
        story_id, audio_id, cover_ids = create_assets(conn)
    finally:
        conn.close()

    if args.skip_api:
        print("[ok] Seeded accounts and file metadata")
        return

    wait_for_api(base_url)
    conn = pymysql.connect(**db_cfg)
    try:
        admin_token, user_token, books = seed_api(base_url, conn, story_id, audio_id, cover_ids)
    finally:
        conn.close()
    test_api(base_url, admin_token, user_token, books[0]["id"])
    print(f"[ok] Seeded {len(books)} books, demo story: {ASSET_DIR / 'ben-ga-ky-uc-10000-tu.txt'}")


if __name__ == "__main__":
    main()
