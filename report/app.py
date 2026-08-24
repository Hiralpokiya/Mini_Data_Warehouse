from flask import Flask, jsonify
from flask_cors import CORS
import psycopg2
import psycopg2.extras
import os
from dotenv import load_dotenv
from flask import render_template
load_dotenv()

app = Flask(__name__)
CORS(app)

DB_CONFIG = {
    "host":     os.getenv("DB_HOST", "localhost"),
    "port":     int(os.getenv("DB_PORT", 5432)),
    "dbname":   os.getenv("DB_NAME", "your_db"),
    "user":     os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", ""),
}

def get_conn():
    return psycopg2.connect(**DB_CONFIG)

def query(sql, params=None):
    conn = get_conn()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(sql, params)
            return cur.fetchall()
    finally:
        conn.close()

@app.route("/api/kpis")
def kpis():
    rows = query("""
        SELECT
            ROUND(SUM(CASE WHEN order_status='Completed' THEN total_amount ELSE 0 END)::NUMERIC, 2) AS total_revenue,
            COUNT(*) AS total_orders,
            COUNT(DISTINCT customer_key) AS total_customers,
            SUM(CASE WHEN order_status='Completed' THEN quantity ELSE 0 END) AS units_sold,
            ROUND(AVG(CASE WHEN order_status='Completed' THEN total_amount END)::NUMERIC, 2) AS avg_order_value,
            COUNT(*) FILTER (WHERE order_status='Completed') AS completed_orders,
            COUNT(*) FILTER (WHERE order_status='Pending')   AS pending_orders,
            COUNT(*) FILTER (WHERE order_status='Cancelled') AS cancelled_orders
        FROM gold.api_fact_orders
    """)
    return jsonify(dict(rows[0]))

@app.route("/api/revenue-by-category")
def revenue_by_category():
    rows = query("""
        SELECT p.category,
            COUNT(f.order_id) AS total_orders,
            SUM(f.quantity)   AS units_sold,
            ROUND(SUM(f.total_amount)::NUMERIC, 2) AS revenue
        FROM gold.api_fact_orders f
        JOIN gold.api_dim_products p ON p.product_key = f.product_key
        WHERE f.order_status = 'Completed'
        GROUP BY p.category ORDER BY revenue DESC
    """)
    return jsonify([dict(r) for r in rows])

@app.route("/api/order-status")
def order_status():
    rows = query("""
        SELECT order_status,
            COUNT(*) AS total_orders,
            ROUND(SUM(total_amount)::NUMERIC, 2) AS total_value,
            ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
        FROM gold.api_fact_orders
        GROUP BY order_status ORDER BY total_orders DESC
    """)
    return jsonify([dict(r) for r in rows])

@app.route("/api/monthly-trend")
def monthly_trend():
    rows = query("""
        SELECT TO_CHAR(order_date, 'YYYY-MM') AS month,
            COUNT(*) AS total_orders,
            ROUND(SUM(total_amount)::NUMERIC, 2) AS revenue
        FROM gold.api_fact_orders
        WHERE order_status = 'Completed' AND order_date IS NOT NULL
        GROUP BY TO_CHAR(order_date, 'YYYY-MM') ORDER BY month
    """)
    return jsonify([dict(r) for r in rows])

@app.route("/api/top-customers")
def top_customers():
    rows = query("""
        SELECT c.first_name || ' ' || c.last_name AS customer_name,
            COUNT(f.order_id) AS total_orders,
            SUM(f.quantity)   AS units_bought,
            ROUND(SUM(f.total_amount)::NUMERIC, 2) AS total_spent
        FROM gold.api_fact_orders f
        JOIN gold.api_dim_customers c ON c.customer_key = f.customer_key
        WHERE f.order_status = 'Completed'
        GROUP BY c.first_name, c.last_name
        ORDER BY total_spent DESC LIMIT 10
    """)
    return jsonify([dict(r) for r in rows])

@app.route("/api/top-products")
def top_products():
    rows = query("""
        SELECT p.product_name, p.category,
            SUM(f.quantity) AS units_sold,
            ROUND(SUM(f.total_amount)::NUMERIC, 2) AS revenue
        FROM gold.api_fact_orders f
        JOIN gold.api_dim_products p ON p.product_key = f.product_key
        WHERE f.order_status = 'Completed'
        GROUP BY p.product_name, p.category
        ORDER BY revenue DESC LIMIT 10
    """)
    return jsonify([dict(r) for r in rows])

@app.route("/api/orders")
def orders():
    rows = query("""
        SELECT f.order_id,
            c.first_name || ' ' || c.last_name AS customer_name,
            p.product_name, p.category,
            f.quantity,
            ROUND(f.total_amount::NUMERIC, 2) AS total_amount,
            f.order_status,
            TO_CHAR(f.order_date, 'YYYY-MM') AS month
        FROM gold.api_fact_orders f
        JOIN gold.api_dim_customers c ON c.customer_key = f.customer_key
        JOIN gold.api_dim_products  p ON p.product_key  = f.product_key
        ORDER BY f.order_date DESC
    """)
    return jsonify([dict(r) for r in rows])

@app.route("/")
def index():
    return render_template("dashboard_live.html")

if __name__ == "__main__":
    print("Mini DWH API running at http://localhost:8000")
    app.run(debug=True, port=8000)
