import os
import uuid
import json
import math
import random
from datetime import datetime, timedelta, date, time
from decimal import Decimal, ROUND_HALF_UP

import numpy as np
import pandas as pd
from faker import Faker


SEED = 42
random.seed(SEED)
np.random.seed(SEED)
fake = Faker()
Faker.seed(SEED)


OUTPUT_DIR = os.path.join("data")
os.makedirs(OUTPUT_DIR, exist_ok=True)


# -----------------------------
# Helpers
# -----------------------------

def new_uuid() -> str:
    return str(uuid.uuid4())


def ts_between(days_back: int = 365, days_forward: int = 60) -> datetime:
    start = datetime.utcnow() - timedelta(days=days_back)
    end = datetime.utcnow() + timedelta(days=days_forward)
    delta = end - start
    rand_seconds = random.randrange(int(delta.total_seconds()))
    return start + timedelta(seconds=rand_seconds)


def dt_to_iso(dt: datetime) -> str:
    return dt.replace(microsecond=0).isoformat() + "Z"


def date_to_str(d: date) -> str:
    return d.isoformat()


def time_to_str(t: time) -> str:
    return t.strftime("%H:%M:%S")


def money(amount: float) -> str:
    return str(Decimal(amount).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))


def bool_str(v: bool) -> str:
    return "true" if v else "false"


def choose_weighted(items, weights):
    return random.choices(items, weights=weights, k=1)[0]


# -----------------------------
# Reference data
# -----------------------------

AREAS = [
    {"area_code": "CMB-01", "area_name": "Colombo 01 - Fort", "lat": 6.933, "lng": 79.844},
    {"area_code": "CMB-03", "area_name": "Colombo 03 - Kollupitiya", "lat": 6.905, "lng": 79.853},
    {"area_code": "CMB-04", "area_name": "Colombo 04 - Bambalapitiya", "lat": 6.891, "lng": 79.855},
    {"area_code": "CMB-05", "area_name": "Colombo 05 - Havelock", "lat": 6.877, "lng": 79.865},
    {"area_code": "CMB-06", "area_name": "Colombo 06 - Wellawatte", "lat": 6.865, "lng": 79.865},
    {"area_code": "CMB-07", "area_name": "Colombo 07 - Cinnamon Gardens", "lat": 6.905, "lng": 79.861},
    {"area_code": "CMB-08", "area_name": "Colombo 08 - Borella", "lat": 6.915, "lng": 79.877},
    {"area_code": "CMB-10", "area_name": "Colombo 10 - Maradana", "lat": 6.930, "lng": 79.866},
    {"area_code": "CMB-11", "area_name": "Colombo 11 - Pettah", "lat": 6.944, "lng": 79.859},
    {"area_code": "DEH-01", "area_name": "Dehiwala", "lat": 6.840, "lng": 79.865},
    {"area_code": "MTL-01", "area_name": "Mount Lavinia", "lat": 6.830, "lng": 79.863},
    {"area_code": "NUG-01", "area_name": "Nugegoda", "lat": 6.872, "lng": 79.889},
    {"area_code": "KOT-01", "area_name": "Sri Jayawardenepura Kotte", "lat": 6.894, "lng": 79.907},
    {"area_code": "RAJ-01", "area_name": "Rajagiriya", "lat": 6.915, "lng": 79.905},
    {"area_code": "BAT-01", "area_name": "Battaramulla", "lat": 6.906, "lng": 79.918},
    {"area_code": "MAL-01", "area_name": "Malabe", "lat": 6.906, "lng": 79.958},
    {"area_code": "MAH-01", "area_name": "Maharagama", "lat": 6.846, "lng": 79.927},
    {"area_code": "HOM-01", "area_name": "Homagama", "lat": 6.844, "lng": 80.002},
]

SUBJECTS = [
    {"subject_code": "OL_MATH", "name": "Mathematics", "level": "OL"},
    {"subject_code": "OL_SCI", "name": "Science", "level": "OL"},
    {"subject_code": "OL_ENG", "name": "English", "level": "OL"},
    {"subject_code": "OL_SIN", "name": "Sinhala", "level": "OL"},
    {"subject_code": "OL_TAM", "name": "Tamil", "level": "OL"},
    {"subject_code": "OL_ICT", "name": "ICT", "level": "OL"},
    {"subject_code": "AL_MATH", "name": "Combined Maths", "level": "AL"},
    {"subject_code": "AL_PHY", "name": "Physics", "level": "AL"},
    {"subject_code": "AL_CHEM", "name": "Chemistry", "level": "AL"},
    {"subject_code": "AL_BIO", "name": "Biology", "level": "AL"},
    {"subject_code": "AL_ECON", "name": "Economics", "level": "AL"},
    {"subject_code": "AL_ACC", "name": "Accounting", "level": "AL"},
    {"subject_code": "OTHER_ART", "name": "Art & Design", "level": "Other"},
    {"subject_code": "OTHER_MUS", "name": "Music", "level": "Other"},
]


# -----------------------------
# Generators
# -----------------------------

def generate_users(num_students=1000, num_tutors=200, num_admins=5):
    users = []
    student_ids, tutor_ids, admin_ids = [], [], []

    used_emails = set()
    used_phones = set()

    def unique_email(prefix: str, idx: int) -> str:
        email = f"{prefix}{idx}@example.com"
        while email in used_emails:
            idx += 1
            email = f"{prefix}{idx}@example.com"
        used_emails.add(email)
        return email

    def unique_phone() -> str:
        # Sri Lanka mobile pattern approx: 07XYYYYYYY
        while True:
            phone = f"07{random.randint(0,9)}{random.randint(1000000,9999999)}"
            if phone not in used_phones:
                used_phones.add(phone)
                return phone

    # Students
    for i in range(1, num_students + 1):
        uid = new_uuid()
        student_ids.append(uid)
        created = ts_between(365, 0)
        users.append({
            "user_id": uid,
            "email": unique_email("student", i),
            "phone": unique_phone() if random.random() < 0.95 else "",
            "display_name": fake.name(),
            "role": "student",
            "is_active": bool_str(True),
            "created_at": dt_to_iso(created),
            "updated_at": dt_to_iso(created + timedelta(days=random.randint(0, 120))),
        })

    # Tutors
    for i in range(1, num_tutors + 1):
        uid = new_uuid()
        tutor_ids.append(uid)
        created = ts_between(365, 0)
        users.append({
            "user_id": uid,
            "email": unique_email("tutor", i),
            "phone": unique_phone() if random.random() < 0.98 else "",
            "display_name": fake.name(),
            "role": "tutor",
            "is_active": bool_str(True),
            "created_at": dt_to_iso(created),
            "updated_at": dt_to_iso(created + timedelta(days=random.randint(0, 120))),
        })

    # Admins
    for i in range(1, num_admins + 1):
        uid = new_uuid()
        admin_ids.append(uid)
        created = ts_between(365, 0)
        users.append({
            "user_id": uid,
            "email": unique_email("admin", i),
            "phone": unique_phone() if random.random() < 0.80 else "",
            "display_name": fake.name(),
            "role": "admin",
            "is_active": bool_str(True),
            "created_at": dt_to_iso(created),
            "updated_at": dt_to_iso(created + timedelta(days=random.randint(0, 120))),
        })

    return users, student_ids, tutor_ids, admin_ids


def generate_student_profiles(student_ids):
    profiles = []
    for uid in student_ids:
        grade = random.randint(6, 13)
        area = random.choice(AREAS)["area_code"]
        # Choose subjects based on grade level
        if grade <= 11:
            pool = [s for s in SUBJECTS if s["level"] == "OL"]
        elif grade >= 12:
            pool = [s for s in SUBJECTS if s["level"] == "AL"]
        else:
            pool = SUBJECTS
        subs = random.sample(pool, k=random.randint(2, min(4, len(pool))))
        profiles.append({
            "user_id": uid,
            "grade": grade,
            "area_code": area,
            "subjects_of_interest": json.dumps([s["subject_code"] for s in subs]),
        })
    return profiles


def generate_tutor_profiles(tutor_ids, admin_ids):
    profiles = []
    for uid in tutor_ids:
        area = random.choice(AREAS)["area_code"]
        mode = choose_weighted(["online", "physical", "hybrid"], [0.5, 0.2, 0.3])
        base_price = random.randint(1500, 8000)
        rating_count = random.randint(0, 350)
        rating_avg = round(random.uniform(2.5, 5.0), 2) if rating_count > 0 else 0
        status = choose_weighted(["approved", "pending", "rejected"], [0.75, 0.2, 0.05])
        reviewed_by = random.choice(admin_ids) if status in ("approved", "rejected") else ""
        reviewed_at = dt_to_iso(ts_between(200, 0)) if reviewed_by else ""
        subs = random.sample(SUBJECTS, k=random.randint(1, 3))
        profiles.append({
            "user_id": uid,
            "bio": fake.paragraph(nb_sentences=3),
            "qualifications": ", ".join(random.sample([
                "BSc", "MSc", "PhD", "PGDip", "BEd", "MEd", "Chartered"], k=random.randint(1, 3))),
            "subjects_taught": json.dumps([s["subject_code"] for s in subs]),
            "area_code": area,
            "mode": mode,
            "base_price": money(base_price),
            "rating_avg": rating_avg,
            "rating_count": rating_count,
            "status": status,
            "reviewed_by": reviewed_by,
            "reviewed_at": reviewed_at,
        })
    return profiles


def generate_admin_profiles(admin_ids):
    profiles = []
    for uid in admin_ids:
        role_type = choose_weighted(["super", "academic", "finance"], [0.2, 0.4, 0.4])
        profiles.append({"user_id": uid, "role_type": role_type})
    return profiles


def generate_subjects():
    return SUBJECTS


def generate_areas():
    return AREAS


def generate_venues(num=25):
    venues = []
    for i in range(1, num + 1):
        area = random.choice(AREAS)["area_code"]
        venues.append({
            "venue_id": new_uuid(),
            "name": f"{fake.company()} Institute",
            "address": fake.address().replace("\n", ", "),
            "area_code": area,
            "capacity": random.randint(30, 200),
        })
    return venues


def price_band_for_fee(fee: float) -> str:
    if fee < 2500:
        return "low"
    if fee <= 5500:
        return "mid"
    return "high"


def generate_classes(num_classes, tutor_profiles, venues):
    classes = []
    tutor_to_mode = {tp["user_id"]: tp["mode"] for tp in tutor_profiles}
    approved_tutors = [tp for tp in tutor_profiles if tp["status"] == "approved"]
    venue_by_area = {}
    for v in venues:
        venue_by_area.setdefault(v["area_code"], []).append(v)

    for i in range(num_classes):
        tutor = random.choice(approved_tutors)
        tutor_id = tutor["user_id"]
        mode = tutor_to_mode[tutor_id]
        subjects = json.loads(tutor["subjects_taught"]) or [random.choice(SUBJECTS)["subject_code"]]
        subject_code = random.choice(subjects)
        subj_meta = next(s for s in SUBJECTS if s["subject_code"] == subject_code)
        grade = random.randint(10, 11) if subj_meta["level"] == "OL" else random.randint(12, 13)
        area_code = tutor["area_code"]

        is_physical = mode in ("physical", "hybrid") and random.random() < (0.85 if mode == "physical" else 0.5)
        venue_id = ""
        if is_physical:
            candidates = venue_by_area.get(area_code, venues)
            venue = random.choice(candidates)
            venue_id = venue["venue_id"]

        base_price = float(tutor["base_price"]) if isinstance(tutor["base_price"], str) else tutor["base_price"]
        fee = base_price * random.uniform(0.9, 1.3)
        capacity_seats = random.randint(20, 120)
        status = choose_weighted(["published", "draft", "archived"], [0.75, 0.2, 0.05])
        created_at = ts_between(200, 0)
        published_at = dt_to_iso(created_at + timedelta(days=random.randint(0, 30))) if status == "published" else ""

        classes.append({
            "class_id": new_uuid(),
            "tutor_id": tutor_id,
            "subject_code": subject_code,
            "grade": grade,
            "mode": "physical" if is_physical else ("online" if mode == "online" else ("online" if not is_physical else "physical")),
            "area_code": area_code,
            "venue_id": venue_id,
            "fee": money(fee),
            "price_band": price_band_for_fee(fee),
            "capacity_seats": capacity_seats,
            "status": status,
            "created_at": dt_to_iso(created_at),
            "published_at": published_at,
        })
    return classes


def overlaps(start_a: time, end_a: time, start_b: time, end_b: time) -> bool:
    return not (end_a <= start_b or end_b <= start_a)


def generate_class_sessions(classes, venues):
    sessions = []
    tutor_day_schedules = {}

    # Predefined time slots (1.5h)
    slot_starts_weekday = [time(16, 0), time(18, 0), time(19, 30)]
    slot_starts_weekend = [time(8, 0), time(10, 0), time(13, 0), time(15, 0), time(17, 0)]
    duration_minutes = 90

    start_date = (datetime.utcnow() - timedelta(days=45)).date()
    end_date = (datetime.utcnow() + timedelta(days=60)).date()

    for c in classes:
        if c["status"] != "published":
            continue
        class_id = c["class_id"]
        tutor_id = c["tutor_id"]
        is_physical = bool(c.get("venue_id"))

        # Choose a recurring weekday
        weekday = random.choice([0, 1, 2, 3, 4, 5, 6])  # Monday=0
        # First date on/after start_date matching weekday
        d = start_date + timedelta(days=(weekday - start_date.weekday()) % 7)
        occurrences = 0
        while d <= end_date and occurrences < random.randint(6, 12):
            slots = slot_starts_weekend if d.weekday() >= 5 else slot_starts_weekday
            start_t = random.choice(slots)
            end_t = (datetime.combine(date.min, start_t) + timedelta(minutes=duration_minutes)).time()

            day_key = (tutor_id, d)
            day_list = tutor_day_schedules.setdefault(day_key, [])
            conflict = any(overlaps(start_t, end_t, s, e) for (s, e, _, __) in day_list)
            if conflict:
                d += timedelta(days=7)
                continue

            room = "" if not is_physical else f"Room-{random.randint(1, 10)}"
            is_cancelled = random.random() < 0.05
            cancel_reason = "Tutor unavailable" if is_cancelled and random.random() < 0.5 else ("Weather" if is_cancelled else "")
            sessions.append({
                "session_id": new_uuid(),
                "class_id": class_id,
                "session_date": date_to_str(d),
                "start_time": time_to_str(start_t),
                "end_time": time_to_str(end_t),
                "room": room,
                "is_cancelled": bool_str(is_cancelled),
                "cancel_reason": cancel_reason,
            })
            day_list.append((start_t, end_t, c.get("venue_id", ""), room))
            occurrences += 1
            d += timedelta(days=7)

    return sessions


def generate_enrollments(classes, student_ids, target_count=2000):
    enrollments = []
    used_pairs = set()
    class_capacity_left = {c["class_id"]: c["capacity_seats"] for c in classes}

    published_classes = [c for c in classes if c["status"] == "published"]
    if not published_classes:
        return enrollments

    attempts = 0
    while len(enrollments) < target_count and attempts < target_count * 10:
        attempts += 1
        c = random.choice(published_classes)
        sid = random.choice(student_ids)
        key = (sid, c["class_id"])
        if key in used_pairs:
            continue
        if class_capacity_left[c["class_id"]] <= 0:
            continue
        used_pairs.add(key)
        class_capacity_left[c["class_id"]] -= 1

        status = choose_weighted(["active", "completed", "pending", "cancelled"], [0.45, 0.25, 0.2, 0.1])
        enrolled_at = ts_between(150, 0)
        cancelled_at = dt_to_iso(enrolled_at + timedelta(days=random.randint(1, 60))) if status == "cancelled" else ""
        cancel_reason = "Student request" if status == "cancelled" and random.random() < 0.7 else ("Payment issue" if status == "cancelled" else "")

        enrollments.append({
            "enrollment_id": new_uuid(),
            "class_id": c["class_id"],
            "student_id": sid,
            "status": status,
            "enrolled_at": dt_to_iso(enrolled_at),
            "cancelled_at": cancelled_at,
            "cancel_reason": cancel_reason,
        })
    return enrollments


def generate_billing(enrollments, classes, admin_ids):
    invoices = []
    payments = []
    refunds = []

    fee_by_class = {c["class_id"]: float(c["fee"]) for c in classes}

    for e in enrollments:
        amount = fee_by_class.get(e["class_id"], 3000.0)
        created_at = datetime.fromisoformat(e["enrolled_at"].replace("Z", ""))
        due_date = (created_at + timedelta(days=random.randint(3, 20))).date().isoformat()

        inv_status = choose_weighted(
            ["awaiting_proof", "under_review", "verified", "rejected", "refunded"],
            [0.30, 0.20, 0.40, 0.05, 0.05],
        )

        invoice_id = new_uuid()
        invoices.append({
            "invoice_id": invoice_id,
            "enrollment_id": e["enrollment_id"],
            "amount_due": money(amount),
            "due_date": due_date,
            "status": inv_status,
            "created_at": e["enrolled_at"],
        })

        if inv_status in ("under_review", "verified", "rejected", "refunded"):
            pay_status = "verified" if inv_status in ("verified", "refunded") else ("rejected" if inv_status == "rejected" else "pending")
            pay = {
                "payment_id": new_uuid(),
                "invoice_id": invoice_id,
                "paid_amount": money(amount * random.uniform(0.9, 1.0)),
                "paid_at": dt_to_iso(created_at + timedelta(days=random.randint(0, 10))),
                "method": random.choice(["bank_transfer", "card", "cash", "online"]),
                "proof_url": f"https://storage.googleapis.com/proofs/{invoice_id}.jpg",
                "verify_status": pay_status,
                "verified_by": random.choice(admin_ids) if pay_status == "verified" else "",
                "verified_at": dt_to_iso(created_at + timedelta(days=random.randint(1, 15))) if pay_status == "verified" else "",
                "verify_note": "OK" if pay_status == "verified" else ("Mismatch" if pay_status == "rejected" else ""),
            }
            payments.append(pay)
            if inv_status == "refunded":
                refunds.append({
                    "refund_id": new_uuid(),
                    "payment_id": pay["payment_id"],
                    "refund_amount": money(float(pay["paid_amount"]) * random.uniform(0.5, 1.0)),
                    "refunded_at": dt_to_iso(datetime.fromisoformat(pay["paid_at"].replace("Z", "")) + timedelta(days=random.randint(1, 10))),
                    "reason": random.choice(["Class cancelled", "Tutor unavailable", "Student requested"]),
                    "processed_by": random.choice(admin_ids),
                })
    return invoices, payments, refunds


def generate_materials(classes):
    materials = []
    for c in classes:
        num = random.randint(0, 5)
        for _ in range(num):
            materials.append({
                "material_id": new_uuid(),
                "class_id": c["class_id"],
                "title": fake.sentence(nb_words=4),
                "file_url": f"https://storage.googleapis.com/materials/{new_uuid()}.pdf",
                "allow_download": bool_str(random.random() < 0.85),
                "uploaded_by": c["tutor_id"],
                "uploaded_at": dt_to_iso(ts_between(120, 0)),
            })
    return materials


def generate_announcements(classes):
    announcements = []
    for _ in range(200):
        scope = choose_weighted(["class", "grade", "area", "all"], [0.5, 0.2, 0.2, 0.1])
        class_id = random.choice(classes)["class_id"] if scope == "class" else ""
        grade = random.randint(6, 13) if scope == "grade" else ""
        area_code = random.choice(AREAS)["area_code"] if scope == "area" else ""
        announcements.append({
            "announcement_id": new_uuid(),
            "scope": scope,
            "class_id": class_id,
            "grade": grade,
            "area_code": area_code,
            "title": fake.sentence(nb_words=6),
            "body": fake.paragraph(nb_sentences=3),
            "created_by": random.choice(classes)["tutor_id"],
            "created_at": dt_to_iso(ts_between(120, 0)),
        })
    return announcements


def generate_messages(classes, student_ids, tutor_ids, target=3000):
    messages = []
    for _ in range(target):
        class_info = random.choice(classes)
        tutor_id = class_info["tutor_id"] if random.random() < 0.7 else random.choice(tutor_ids)
        student_id = random.choice(student_ids)
        messages.append({
            "message_id": new_uuid(),
            "sender_id": tutor_id if random.random() < 0.5 else student_id,
            "recipient_id": student_id if random.random() < 0.5 else tutor_id,
            "class_id": class_info["class_id"] if random.random() < 0.7 else "",
            "text": fake.sentence(nb_words=12),
            "sent_at": dt_to_iso(ts_between(120, 0)),
            "is_deleted": bool_str(random.random() < 0.02),
        })
    return messages


def generate_notifications(student_ids, tutor_ids):
    notif_types = ["enrollment_status", "payment_status", "schedule_change", "announcement", "system"]
    notifications = []
    recipients = student_ids + tutor_ids
    for _ in range(3000):
        rid = random.choice(recipients)
        notifications.append({
            "notification_id": new_uuid(),
            "recipient_id": rid,
            "type": random.choice(notif_types),
            "title": fake.sentence(nb_words=5),
            "body": fake.sentence(nb_words=10),
            "is_read": bool_str(random.random() < 0.6),
            "created_at": dt_to_iso(ts_between(120, 0)),
        })
    return notifications


def generate_ratings(enrollments):
    ratings = []
    for e in enrollments:
        if e["status"] not in ("active", "completed"):
            continue
        if random.random() < 0.35:
            ratings.append({
                "rating_id": new_uuid(),
                "student_id": e["student_id"],
                "tutor_id": "",  # fill below when joining from class
                "class_id": e["class_id"],
                "stars": random.randint(3, 5) if e["status"] == "completed" else random.randint(1, 5),
                "comment": fake.sentence(nb_words=10) if random.random() < 0.6 else "",
                "created_at": e["enrolled_at"],
            })
    return ratings


def generate_events(enrollments, classes, student_ids):
    # Create impression/view/click/bookmark/search/enrol events
    events = []
    event_types = ["search", "impression", "view_tutor", "view_class", "click", "bookmark", "enrol"]
    class_by_id = {c["class_id"]: c for c in classes}

    # Random browsing sessions
    for _ in range(20000):
        student = random.choice(student_ids) if random.random() < 0.9 else ""
        c = random.choice(classes)
        tutor_id = c["tutor_id"]
        cls_id = c["class_id"]
        et = choose_weighted(event_types, [0.15, 0.25, 0.10, 0.20, 0.20, 0.05, 0.05])
        q = "" if et != "search" else random.choice([
            "math grade 10", "physics al", "english colombo", "science ol", "tutor near me"])
        events.append({
            "event_id": new_uuid(),
            "student_id": student,
            "tutor_id": tutor_id,
            "class_id": cls_id,
            "event_type": et,
            "query_text": q,
            "ts": dt_to_iso(ts_between(120, 0)),
        })

    # Enrol events matching enrollments
    for e in enrollments:
        c = class_by_id.get(e["class_id"]) or {}
        events.append({
            "event_id": new_uuid(),
            "student_id": e["student_id"],
            "tutor_id": c.get("tutor_id", ""),
            "class_id": e["class_id"],
            "event_type": "enrol",
            "query_text": "",
            "ts": e["enrolled_at"],
        })

    return events


def generate_weekly_demand(events, classes):
    # Aggregate by week_start (Monday), subject_code, area_code
    from collections import defaultdict

    class_meta = {c["class_id"]: (c["subject_code"], c["area_code"]) for c in classes}
    agg = defaultdict(lambda: {"views": 0, "clicks": 0, "enrols": 0})

    def monday_of(dt: datetime) -> date:
        d = dt.date()
        return d - timedelta(days=d.weekday())

    for ev in events:
        cls_id = ev.get("class_id")
        meta = class_meta.get(cls_id)
        if not meta:
            continue
        ts = datetime.fromisoformat(ev["ts"].replace("Z", ""))
        wk = monday_of(ts)
        subj, area = meta
        key = (wk.isoformat(), subj, area)
        if ev["event_type"] in ("view_class", "impression"):
            agg[key]["views"] += 1
        if ev["event_type"] == "click":
            agg[key]["clicks"] += 1
        if ev["event_type"] == "enrol":
            agg[key]["enrols"] += 1

    rows = []
    for (week_start, subject_code, area_code), m in agg.items():
        rows.append({
            "week_start": week_start,
            "subject_code": subject_code,
            "area_code": area_code,
            "views": m["views"],
            "clicks": m["clicks"],
            "enrols": m["enrols"],
        })
    return rows


# -----------------------------
# Main
# -----------------------------

def write_csv(rows, filename, columns=None):
    df = pd.DataFrame(rows)
    if columns:
        missing = [c for c in columns if c not in df.columns]
        for m in missing:
            df[m] = ""
        df = df[columns]
    path = os.path.join(OUTPUT_DIR, filename)
    df.to_csv(path, index=False)
    print(f"Wrote {len(df):,} rows -> {path}")


def main():
    print("Generating synthetic data for AI ClassMate...")

    users, student_ids, tutor_ids, admin_ids = generate_users()

    student_profiles = generate_student_profiles(student_ids)
    tutor_profiles = generate_tutor_profiles(tutor_ids, admin_ids)
    admin_profiles = generate_admin_profiles(admin_ids)

    subjects = generate_subjects()
    areas = generate_areas()
    venues = generate_venues()

    classes = generate_classes(300, tutor_profiles, venues)
    class_sessions = generate_class_sessions(classes, venues)

    enrollments = generate_enrollments(classes, student_ids, 2000)
    invoices, payments, refunds = generate_billing(enrollments, classes, admin_ids)

    materials = generate_materials(classes)
    announcements = generate_announcements(classes)
    messages = generate_messages(classes, student_ids, tutor_ids)
    notifications = generate_notifications(student_ids, tutor_ids)
    ratings = generate_ratings(enrollments)

    # Fill tutor_id in ratings from class mapping
    class_by_id = {c["class_id"]: c for c in classes}
    for r in ratings:
        cls = class_by_id.get(r["class_id"]) or {}
        r["tutor_id"] = cls.get("tutor_id", "")

    events = generate_events(enrollments, classes, student_ids)
    weekly_demand = generate_weekly_demand(events, classes)

    # Write CSVs (order and columns per schema)
    write_csv(users, "user.csv", [
        "user_id", "email", "phone", "display_name", "role", "is_active", "created_at", "updated_at"
    ])

    write_csv(student_profiles, "student_profile.csv", [
        "user_id", "grade", "area_code", "subjects_of_interest"
    ])

    write_csv(tutor_profiles, "tutor_profile.csv", [
        "user_id", "bio", "qualifications", "subjects_taught", "area_code", "mode", "base_price",
        "rating_avg", "rating_count", "status", "reviewed_by", "reviewed_at"
    ])

    write_csv(admin_profiles, "admin_profile.csv", [
        "user_id", "role_type"
    ])

    write_csv(subjects, "subject.csv", [
        "subject_code", "name", "level"
    ])

    write_csv(areas, "area.csv", [
        "area_code", "area_name", "lat", "lng"
    ])

    write_csv(venues, "venue.csv", [
        "venue_id", "name", "address", "area_code", "capacity"
    ])

    write_csv(classes, "class.csv", [
        "class_id", "tutor_id", "subject_code", "grade", "mode", "area_code", "venue_id",
        "fee", "price_band", "capacity_seats", "status", "created_at", "published_at"
    ])

    write_csv(class_sessions, "class_session.csv", [
        "session_id", "class_id", "session_date", "start_time", "end_time", "room",
        "is_cancelled", "cancel_reason"
    ])

    write_csv(enrollments, "enrollment.csv", [
        "enrollment_id", "class_id", "student_id", "status", "enrolled_at", "cancelled_at", "cancel_reason"
    ])

    write_csv(invoices, "invoice.csv", [
        "invoice_id", "enrollment_id", "amount_due", "due_date", "status", "created_at"
    ])

    write_csv(payments, "payment.csv", [
        "payment_id", "invoice_id", "paid_amount", "paid_at", "method", "proof_url",
        "verify_status", "verified_by", "verified_at", "verify_note"
    ])

    write_csv(refunds, "refund.csv", [
        "refund_id", "payment_id", "refund_amount", "refunded_at", "reason", "processed_by"
    ])

    write_csv(materials, "material.csv", [
        "material_id", "class_id", "title", "file_url", "allow_download", "uploaded_by", "uploaded_at"
    ])

    write_csv(announcements, "announcement.csv", [
        "announcement_id", "scope", "class_id", "grade", "area_code", "title", "body", "created_by", "created_at"
    ])

    write_csv(messages, "message.csv", [
        "message_id", "sender_id", "recipient_id", "class_id", "text", "sent_at", "is_deleted"
    ])

    write_csv(notifications, "notification.csv", [
        "notification_id", "recipient_id", "type", "title", "body", "is_read", "created_at"
    ])

    write_csv(ratings, "rating.csv", [
        "rating_id", "student_id", "tutor_id", "class_id", "stars", "comment", "created_at"
    ])

    write_csv(events, "event_interaction.csv", [
        "event_id", "student_id", "tutor_id", "class_id", "event_type", "query_text", "ts"
    ])

    write_csv(weekly_demand, "weekly_demand.csv", [
        "week_start", "subject_code", "area_code", "views", "clicks", "enrols"
    ])

    print("Done. CSVs are in ./data/")


if __name__ == "__main__":
    main()


