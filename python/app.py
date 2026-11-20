import uuid
from flask import Flask, jsonify, request
from database import insert_order

app = Flask(__name__)

@app.post("/api/orders")
def create_order():
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "JSON inválido"}), 400

    customer_id = data.get("customerId", "").strip()
    items = data.get("items")

    if not customer_id or not items or not isinstance(items, list):
        return jsonify({"error": "customerId e items son requeridos"}), 400

    try:
        total_amount = round(
            sum(int(item["quantity"]) * float(item["price"]) for item in items), 2
        )
        items_count = sum(int(item["quantity"]) for item in items)
    except (KeyError, TypeError, ValueError):
        return jsonify({"error": "Formato inválido en items"}), 400

    order_id = f"ORD-{uuid.uuid4()}"

    try:
        processed_at = insert_order(
            order_id=order_id,
            customer_id=customer_id,
            total_amount=total_amount,
            items_count=items_count,
            items=items,
        )
    except Exception as e:
        return jsonify({"error": str(e)}), 500

    return jsonify(
        {
            "orderId": order_id,
            "customerId": customer_id,
            "totalAmount": total_amount,
            "itemsCount": items_count,
            "processedAt": processed_at.isoformat() + "Z",
        }
    ), 201


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)