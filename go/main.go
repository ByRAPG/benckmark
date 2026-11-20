package main

import (
	"context"
	"encoding/json"
	"log"
	"math"
	"net/http"
	"time"

	"benchmark-go/database"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type CreateOrderRequest struct {
	CustomerID string               `json:"customerId"`
	Items      []database.OrderItem `json:"items"`
}

type CreateOrderResponse struct {
	OrderID     string    `json:"orderId"`
	CustomerID  string    `json:"customerId"`
	TotalAmount float64   `json:"totalAmount"`
	ItemsCount  int       `json:"itemsCount"`
	ProcessedAt time.Time `json:"processedAt"`
}

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := database.Connect(ctx)
	if err != nil {
		log.Fatalf("Error conectando a PostgreSQL: %v", err)
	}
	defer pool.Close()

	mux := http.NewServeMux()
	mux.HandleFunc("POST /api/orders", handleCreateOrder(pool))

	log.Println("Servidor Go listo en :8080")
	if err := http.ListenAndServe(":8080", mux); err != nil {
		log.Fatal(err)
	}
}

func handleCreateOrder(pool *pgxpool.Pool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		var req CreateOrderRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{"error": "JSON inválido"})
			return
		}

		if req.CustomerID == "" || len(req.Items) == 0 {
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{"error": "customerId e items son requeridos"})
			return
		}

		var totalAmount float64
		var itemsCount int
		for _, item := range req.Items {
			totalAmount += float64(item.Quantity) * item.Price
			itemsCount += item.Quantity
		}
		// Redondeo a 2 decimales para coincidir con NUMERIC(10,2)
		totalAmount = math.Round(totalAmount*100) / 100

		orderID := "ORD-" + uuid.NewString()

		createdAt, err := database.InsertOrder(r.Context(), pool, database.OrderRecord{
			OrderID:     orderID,
			CustomerID:  req.CustomerID,
			TotalAmount: totalAmount,
			ItemsCount:  itemsCount,
			Items:       req.Items,
		})
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
			return
		}

		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(CreateOrderResponse{
			OrderID:     orderID,
			CustomerID:  req.CustomerID,
			TotalAmount: totalAmount,
			ItemsCount:  itemsCount,
			ProcessedAt: createdAt,
		})
	}
}