#!/usr/bin/env python3
import json
import math
import random
import subprocess
import sys
import time
import wave
from pathlib import Path

import bcrypt
import requests


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "demo-assets"
MYSQL_CONTAINER = "some-mysql"
MYSQL_PASSWORD = "12345"
API_BASE = "http://localhost:8080/api"
DEFAULT_PASSWORD = "123456"


def mysql(sql, capture=False):
    subprocess.run(["sudo", "-S", "-v"], input="2809\n", text=True, check=True, stdout=subprocess.DEVNULL)
    cmd = [
        "sudo", "-n", "docker", "exec", "-i", MYSQL_CONTAINER,
        "mysql", "-uroot", f"-p{MYSQL_PASSWORD}", "--default-character-set=utf8mb4", "audio_book",
    ]
    if capture:
        cmd.extend(["-N", "-B"])
    proc = subprocess.run(
        cmd,
        input=sql,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE,
        check=True,
    )
    return proc.stdout.strip() if capture else ""


def http(method, path, body=None, token=None, expect=(200,)):
    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    url = f"{API_BASE}{path}"
    resp = requests.request(method, url, json=body, headers=headers, timeout=30)
    if resp.status_code not in expect:
        raise RuntimeError(f"{method} {path} expected {expect}, got {resp.status_code}: {resp.text[:500]}")
    return resp.json() if resp.text else {}


def wait_api():
    for _ in range(60):
        try:
            requests.post(f"{API_BASE}/auth/login", json={"email": "none@test.com", "password": "bad"}, timeout=3)
            return
        except requests.RequestException:
            time.sleep(2)
    raise RuntimeError("API is not reachable")


def esc(value):
    return value.replace("\\", "\\\\").replace("'", "''")


def seed_users():
    password_hash = bcrypt.hashpw(DEFAULT_PASSWORD.encode(), bcrypt.gensalt(rounds=12)).decode()
    mysql(f"""
DELETE FROM admin WHERE user_id IN (SELECT id FROM users WHERE email IN ('admin@test.com','minh.user@test.com','linh.user@test.com'));
DELETE FROM client WHERE user_id IN (SELECT id FROM users WHERE email IN ('admin@test.com','minh.user@test.com','linh.user@test.com'));
DELETE FROM users WHERE email IN ('admin@test.com','minh.user@test.com','linh.user@test.com');

INSERT INTO users(password, name, email, active, role, is_deleted, created_by, created_at, last_modified_by, last_modified_at)
VALUES
('{password_hash}', 'Quản trị viên', 'admin@test.com', b'1', 'ADMIN', b'0', 'seed', NOW(6), 'seed', NOW(6)),
('{password_hash}', 'Minh An', 'minh.user@test.com', b'1', 'USER', b'0', 'seed', NOW(6), 'seed', NOW(6)),
('{password_hash}', 'Linh Chi', 'linh.user@test.com', b'1', 'USER', b'0', 'seed', NOW(6), 'seed', NOW(6));

INSERT INTO admin(user_id) SELECT id FROM users WHERE email='admin@test.com';
INSERT INTO client(user_id, total_credit) SELECT id, 260 FROM users WHERE email='minh.user@test.com';
INSERT INTO client(user_id, total_credit) SELECT id, 180 FROM users WHERE email='linh.user@test.com';
""")


def build_story(words_target=10000):
    scenes = [
        "Bến ga nhỏ bên sông thức dậy trong mùi cà phê rang và tiếng bánh xe lăn trên nền gạch cũ.",
        "An cầm cuốn sổ bìa xanh, ghi lại từng âm thanh của thành phố để hoàn thành kho lưu trữ ký ức.",
        "Mỗi người khách để lại một câu chuyện về gia đình, lòng tin, và những lời hứa tưởng đã ngủ quên.",
        "Khi mưa xuống, các mảnh ký ức hòa vào tiếng mái tôn và mở ra manh mối về chuyến tàu biến mất.",
        "An hiểu điều cần tìm không phải kho báu, mà là cách đưa mọi người trở về với điều họ từng yêu quý.",
    ]
    words = []
    chapter = 1
    while len(words) < words_target:
        paragraph = f"Chương {chapter}. " + " ".join(scenes)
        paragraph += " Họ bước tiếp bằng những lựa chọn nhỏ, tử tế và có hậu, để hành trình trở nên thật sự đáng nhớ."
        words.extend(paragraph.split())
        chapter += 1
    return " ".join(words[:words_target])


def make_wav(path, seconds=75, sample_rate=22050):
    with wave.open(str(path), "w") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(sample_rate)
        for i in range(seconds * sample_rate):
            t = i / sample_rate
            freq = 220 + 55 * math.sin(t / 3)
            amp = int(9000 * math.sin(2 * math.pi * freq * t))
            out.writeframesraw(amp.to_bytes(2, byteorder="little", signed=True))


def ensure_file(name, path, file_type):
    existing = mysql(f"SELECT id FROM file WHERE file_name='{esc(name)}' ORDER BY id DESC LIMIT 1;", capture=True)
    if existing:
        return int(existing.splitlines()[-1])
    uri = Path(path).resolve().as_uri()
    mysql(f"""
INSERT INTO file(file_name, file_path, url, type, created_by, created_at, last_modified_by, last_modified_at)
VALUES('{esc(name)}', '{esc(str(path))}', '{esc(uri[:250])}', '{file_type}', 'seed', NOW(6), 'seed', NOW(6));
""")
    return int(mysql(f"SELECT id FROM file WHERE file_name='{esc(name)}' ORDER BY id DESC LIMIT 1;", capture=True).splitlines()[-1])


def seed_files():
    ASSET_DIR.mkdir(exist_ok=True)
    story_path = ASSET_DIR / "ben-ga-ky-uc-10000-tu.txt"
    audio_path = ASSET_DIR / "ben-ga-ky-uc-demo.wav"
    story_path.write_text(json.dumps({
        "content": "<h1>Chapter 1</h1><p>%s</p><blockquote>Những ký ức tử tế luôn tìm được đường về.</blockquote>" % build_story()
    }, ensure_ascii=False), encoding="utf-8")
    if not audio_path.exists():
        make_wav(audio_path)

    story_id = ensure_file(story_path.name, story_path, "document")
    audio_id = ensure_file(audio_path.name, audio_path, "audio")
    cover_ids = []
    for idx in range(1, 21):
        cover = ASSET_DIR / f"cover-{idx:02d}.txt"
        cover.write_text(f"Demo cover placeholder for audiobook {idx:02d}", encoding="utf-8")
        cover_ids.append(ensure_file(cover.name, cover, "image"))
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
    ("Mật Mã Trong Tiếng Chuông", "Nhật Linh", "Tiếng chuông cũ hé lộ mật mã bảo vệ ký ức của thị trấn."),
]


def get_or_create_categories(token):
    wanted = [
        ("Truyện ngắn", "Các tác phẩm ngắn, dễ nghe, giàu cảm xúc."),
        ("Đời sống", "Câu chuyện gần gũi về gia đình, công việc và thành phố."),
        ("Phiêu lưu nhẹ", "Hành trình khám phá có tiết tấu ấm áp."),
        ("Chữa lành", "Tác phẩm mang tinh thần lạc quan và nhân văn."),
    ]
    existing = {item["name"]: item["id"] for item in http("GET", "/categories", token=token)["data"]}
    ids = []
    for name, description in wanted:
        if name in existing:
            ids.append(existing[name])
            continue
        resp = http("POST", "/admin/books/categories", {"name": name, "description": description}, token=token)
        ids.append(resp["data"]["id"])
    return ids


def create_books(admin_token, story_id, audio_id, cover_ids, category_ids):
    mysql("SET FOREIGN_KEY_CHECKS=0; DELETE FROM book_favorite; DELETE FROM audio_progress; DELETE FROM ebook_progress; DELETE FROM client_book; DELETE FROM book_category_mapping; DELETE FROM ebook_chapter; DELETE FROM book_description_image; DELETE FROM book; DROP TABLE IF EXISTS audio_book_chapter; SET FOREIGN_KEY_CHECKS=1;")
    created = []
    for idx, (title, author, desc) in enumerate(BOOKS, start=1):
        payload = {
            "name": title,
            "author": author,
            "description": desc,
            "coverFileId": cover_ids[idx - 1],
            "categoryIds": [category_ids[(idx - 1) % len(category_ids)]],
            "ebookChapters": [
                {"title": "Khởi đầu", "chapterNumber": 1, "durationSeconds": 900 + idx, "contentFileId": story_id, "audioFileId": audio_id},
                {"title": "Dấu hiệu", "chapterNumber": 2, "durationSeconds": 960 + idx, "contentFileId": story_id, "audioFileId": audio_id},
                {"title": "Lựa chọn", "chapterNumber": 3, "durationSeconds": 1020 + idx, "contentFileId": story_id, "audioFileId": audio_id},
                {"title": "Trở về", "chapterNumber": 4, "durationSeconds": 880 + idx, "contentFileId": story_id, "audioFileId": audio_id},
            ],
            "descriptionImageFileIds": [],
        }
        created.append(http("POST", "/admin/books", payload, token=admin_token)["data"])
    return created


def seed_interactions(user_token, books):
    for book in books[:12]:
        http("POST", f"/purchased/{book['id']}", token=user_token)
    for book in books[:8]:
        http("POST", f"/books/favourite/{book['id']}", token=user_token)
    for book in books[:6]:
        ebook = book["ebookChapters"][0]
        http("POST", "/books/progress/audio", {
            "bookId": book["id"], "chapterId": ebook["id"], "currentTime": random.randint(60, 600),
            "duration": ebook["durationSeconds"], "progressPercent": round(random.uniform(12, 76), 2), "playbackSpeed": 1.0
        }, token=user_token)
        http("POST", "/books/progress/ebook", {
            "bookId": book["id"], "chapterId": ebook["id"], "pageNumber": random.randint(3, 40),
            "offsetInPage": 0.45, "progressPercent": round(random.uniform(10, 82), 2)
        }, token=user_token)


def run_tests(admin_token, user_token, first_book_id):
    checks = [
        ("login admin", lambda: http("POST", "/auth/login", {"email": "admin@test.com", "password": DEFAULT_PASSWORD})),
        ("login user", lambda: http("POST", "/auth/login", {"email": "minh.user@test.com", "password": DEFAULT_PASSWORD})),
        ("admin dashboard", lambda: http("GET", "/admin/books/dashboard", token=admin_token)),
        ("book search", lambda: http("GET", "/books/search?keyword=Bến&page=0&limit=5", token=user_token)),
        ("book detail", lambda: http("GET", f"/books/{first_book_id}", token=user_token)),
        ("trending", lambda: http("GET", "/books/trending?page=0&size=5", token=user_token)),
        ("favourites", lambda: http("GET", "/books/favourite", token=user_token)),
        ("purchased", lambda: http("GET", "/purchased?page=0&size=5", token=user_token)),
        ("invalid login", lambda: http("POST", "/auth/login", {"email": "admin@test.com", "password": "wrong"}, expect=(400,))),
        ("unauthorized me", lambda: http("GET", "/client/me", expect=(401,))),
        ("invalid book", lambda: http("POST", "/admin/books", {"name": "", "categoryIds": []}, token=admin_token, expect=(400,))),
    ]
    for name, fn in checks:
        result = fn()
        print(f"[ok] {name}: code={result.get('code')}, message={result.get('message')}")


def main():
    wait_api()
    seed_users()
    story_id, audio_id, cover_ids = seed_files()

    admin_token = http("POST", "/auth/login", {"email": "admin@test.com", "password": DEFAULT_PASSWORD})["data"]["token"]
    user_token = http("POST", "/auth/login", {"email": "minh.user@test.com", "password": DEFAULT_PASSWORD})["data"]["token"]

    category_ids = get_or_create_categories(admin_token)
    books = create_books(admin_token, story_id, audio_id, cover_ids, category_ids)
    seed_interactions(user_token, books)
    run_tests(admin_token, user_token, books[0]["id"])

    print(json.dumps({
        "books": len(books),
        "story": str(ASSET_DIR / "ben-ga-ky-uc-10000-tu.txt"),
        "audio": str(ASSET_DIR / "ben-ga-ky-uc-demo.wav"),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
