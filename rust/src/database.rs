use chrono::NaiveDateTime;
use serde::Deserialize;
use sqlx::{postgres::PgPoolOptions, PgPool};
use std::env;

#[derive(Debug, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct OrderItem {
    pub product_id: String,
    pub quantity: i32,
    pub price: f64,
}

pub struct OrderRecord {
    pub order_id: String,
    pub customer_id: String,
    pub total_amount: f64,
    pub items_count: i32,
    pub items: Vec<OrderItem>,
}

pub async fn connect() -> Result<PgPool, sqlx::Error> {
    let user = env::var("DB_USER").unwrap_or_else(|_| "postgres".into());
    let pass = env::var("DB_PASSWORD").unwrap_or_else(|_| "postgres".into());
    let host = env::var("DB_HOST").unwrap_or_else(|_| "db".into());
    let port = env::var("DB_PORT").unwrap_or_else(|_| "5432".into());
    let name = env::var("DB_NAME").unwrap_or_else(|_| "orders_db".into());

    let dsn = format!("postgres://{user}:{pass}@{host}:{port}/{name}");

    PgPoolOptions::new()
        .max_connections(30)
        .min_connections(5)
        .connect(&dsn)
        .await
}

pub async fn insert_order(pool: &PgPool, order: OrderRecord) -> Result<NaiveDateTime, sqlx::Error> {
    let mut tx = pool.begin().await?;

    // Cast explícito ::numeric para que Postgres acepte f64 directamente en NUMERIC(10,2)
    let created_at: NaiveDateTime = sqlx::query_scalar(
        r#"
        INSERT INTO orders (order_id, customer_id, total_amount, items_count)
        VALUES ($1, $2, $3::float8::numeric, $4)
        RETURNING created_at
        "#,
    )
    .bind(&order.order_id)
    .bind(&order.customer_id)
    .bind(order.total_amount)
    .bind(order.items_count)
    .fetch_one(&mut *tx)
    .await?;

    for item in &order.items {
        sqlx::query(
            r#"
            INSERT INTO order_items (order_id, product_id, quantity, price)
            VALUES ($1, $2, $3, $4::float8::numeric)
            "#,
        )
        .bind(&order.order_id)
        .bind(&item.product_id)
        .bind(item.quantity)
        .bind(item.price)
        .execute(&mut *tx)
        .await?;
    }

    tx.commit().await?;

    Ok(created_at)
}