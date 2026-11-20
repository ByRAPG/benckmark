import os
from psycopg_pool import ConnectionPool

def _get_dsn() -> str:
    user = os.getenv("DB_USER", "postgres")
    password = os.getenv("DB_PASSWORD", "postgres")
    host = os.getenv("DB_HOST", "db")
    port = os.getenv("DB_PORT", "5432")
    dbname = os.getenv("DB_NAME", "orders_db")
    return f"postgresql://{user}:{password}@{host}:{port}/{dbname}"

pool = ConnectionPool(
    conninfo=_get_dsn(),
    min_size=5,
    max_size=30,
    open=True,
)

def insert_order(order_id: str, customer_id: str, total_amount: float, items_count: int, items: list[dict]):
    with pool.connection() as conn:
        with conn.transaction():
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO orders (order_id, customer_id, total_amount, items_count)
                    VALUES (%s, %s, %s, %s)
                    RETURNING created_at
                    """,
                    (order_id, customer_id, total_amount, items_count),
                )
                row = cur.fetchone()
                created_at = row[0]

                cur.executemany(
                    """
                    INSERT INTO order_items (order_id, product_id, quantity, price)
                    VALUES (%s, %s, %s, %s)
                    """,
                    [
                        (order_id, item["productId"], item["quantity"], item["price"])
                        for item in items
                    ],
                )

    return created_at