mod database;

use axum::{
    extract::State,
    http::StatusCode,
    routing::post,
    Json, Router,
};
use chrono::NaiveDateTime;
use database::{OrderItem, OrderRecord};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use sqlx::PgPool;
use uuid::Uuid;

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct CreateOrderRequest {
    customer_id: String,
    items: Vec<OrderItem>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct CreateOrderResponse {
    order_id: String,
    customer_id: String,
    total_amount: f64,
    items_count: i32,
    processed_at: NaiveDateTime,
}

#[tokio::main]
async fn main() {
    let pool = database::connect()
        .await
        .expect("Error conectando a PostgreSQL");

    println!("Conectado exitosamente a PostgreSQL");

    let app = Router::new()
        .route("/api/orders", post(create_order))
        .with_state(pool);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080")
        .await
        .unwrap();

    println!("Servidor Rust escuchando en :8080");
    axum::serve(listener, app).await.unwrap();
}

async fn create_order(
    State(pool): State<PgPool>,
    Json(req): Json<CreateOrderRequest>,
) -> Result<(StatusCode, Json<CreateOrderResponse>), (StatusCode, Json<Value>)> {
    if req.customer_id.trim().is_empty() || req.items.is_empty() {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(json!({ "error": "customerId e items son requeridos" })),
        ));
    }

    let mut total_amount: f64 = 0.0;
    let mut items_count: i32 = 0;

    for item in &req.items {
        total_amount += (item.quantity as f64) * item.price;
        items_count += item.quantity;
    }
    total_amount = (total_amount * 100.0).round() / 100.0;

    let order_id = format!("ORD-{}", Uuid::new_v4());

    let processed_at = database::insert_order(
        &pool,
        OrderRecord {
            order_id: order_id.clone(),
            customer_id: req.customer_id.clone(),
            total_amount,
            items_count,
            items: req.items,
        },
    )
    .await
    .map_err(|e| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({ "error": e.to_string() })),
        )
    })?;

    Ok((
        StatusCode::CREATED,
        Json(CreateOrderResponse {
            order_id,
            customer_id: req.customer_id,
            total_amount,
            items_count,
            processed_at,
        }),
    ))
}