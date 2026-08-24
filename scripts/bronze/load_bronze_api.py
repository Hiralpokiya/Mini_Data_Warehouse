# scripts/bronze/load_bronze_api.py

import requests
import psycopg2
import psycopg2.extras
import logging
from datetime import datetime
from dotenv import load_dotenv
import os

load_dotenv()
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

# ── DB Config ─────────────────────────────────────────────────────────────────
DB_CONFIG = {
    "host":     os.getenv("DB_HOST", "localhost"),
    "port":     int(os.getenv("DB_PORT", 5432)),
    "dbname":   os.getenv("DB_NAME", "your_db"),
    "user":     os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", ""),
}

# ── API URLs (dummyjson.com — free, no key needed) ────────────────────────────
USERS_URL    = "https://dummyjson.com/users"
PRODUCTS_URL = "https://dummyjson.com/products"
CARTS_URL    = "https://dummyjson.com/carts"


def fetch_all(url: str, limit: int = 30) -> list:
    """Fetch all pages from a dummyjson paginated endpoint."""
    records, skip = [], 0
    while True:
        res = requests.get(url, params={"limit": limit, "skip": skip}, timeout=15)
        res.raise_for_status()
        data = res.json()
        page = data.get("users") or data.get("products") or data.get("carts") or []
        if not page:
            break
        records.extend(page)
        skip += limit
        logger.info(f"  Fetched {len(records)}/{data.get('total', '?')} from {url}")
        if len(records) >= data.get("total", 0):
            break
    return records


def load_customers(conn):
    logger.info("Loading customers...")
    users = fetch_all(USERS_URL)
    rows = [(
        u["id"],
        f"CUST{u['id']:04d}",
        u.get("firstName", ""),
        u.get("lastName", ""),
        u.get("email", ""),
        u.get("phone", ""),
        "Active" if u.get("role") != "moderator" else "Inactive",
        u.get("birthDate", datetime.now().isoformat()),
    ) for u in users]

    with conn.cursor() as cur:
        cur.execute("TRUNCATE TABLE bronze.api_customers CASCADE;")
        psycopg2.extras.execute_values(cur, """
            INSERT INTO bronze.api_customers
              (cst_id, cst_key, cst_firstname, cst_lastname,
               cst_email, cst_phone, cst_status, cst_create_date)
            VALUES %s
        """, rows, page_size=100)
    conn.commit()
    logger.info(f"  ✅ {len(rows)} customers loaded")


def load_products(conn):
    logger.info("Loading products...")
    products = fetch_all(PRODUCTS_URL)
    rows = [(
        p["id"],
        f"PROD{p['id']:04d}",
        p.get("title", ""),
        p.get("description", ""),
        float(p.get("price", 0)),
        p.get("category", "Uncategorized").title(),
        "Active" if p.get("stock", 0) > 0 else "Inactive",
        datetime.now(),
    ) for p in products]

    with conn.cursor() as cur:
        cur.execute("TRUNCATE TABLE bronze.api_products CASCADE;")
        psycopg2.extras.execute_values(cur, """
            INSERT INTO bronze.api_products
              (prd_id, prd_key, prd_name, prd_description,
               prd_price, prd_category, prd_status, prd_last_updated)
            VALUES %s
        """, rows, page_size=100)
    conn.commit()
    logger.info(f"  ✅ {len(rows)} products loaded")


def load_orders(conn):
    logger.info("Loading orders (from carts)...")
    carts = fetch_all(CARTS_URL)
    rows = []
    order_id = 1

    for cart in carts:
        cust_id = cart.get("userId", 1)
        for item in cart.get("products", []):
            qty        = item.get("quantity", 1)
            unit_price = float(item.get("price", 0))
            total      = round(qty * unit_price, 2)

            if   order_id % 10 == 0: status, ship = "Cancelled", None
            elif order_id % 4  == 0: status, ship = "Pending",   None
            else:                    status, ship = "Completed",  datetime.now()

            rows.append((
                order_id, f"ORD{order_id:04d}",
                cust_id, item.get("id", 1),
                qty, unit_price, total,
                status, datetime.now(), ship,
            ))
            order_id += 1

    with conn.cursor() as cur:
        cur.execute("TRUNCATE TABLE bronze.api_orders CASCADE;")
        psycopg2.extras.execute_values(cur, """
            INSERT INTO bronze.api_orders
              (ord_id, ord_key, ord_cust_id, ord_prd_id, ord_quantity,
               ord_unit_price, ord_total_amount, ord_status,
               ord_date, ord_ship_date)
            VALUES %s
        """, rows, page_size=200)
    conn.commit()
    logger.info(f"  ✅ {len(rows)} orders loaded")


def verify(conn):
    logger.info("\n📊 Row counts:")
    with conn.cursor() as cur:
        for t in ["bronze.api_customers", "bronze.api_products", "bronze.api_orders"]:
            cur.execute(f"SELECT COUNT(*) FROM {t}")
            logger.info(f"  {t}: {cur.fetchone()[0]} rows")


if __name__ == "__main__":
    conn = psycopg2.connect(**DB_CONFIG)
    try:
        load_customers(conn)
        load_products(conn)
        load_orders(conn)
        verify(conn)
    finally:
        conn.close()