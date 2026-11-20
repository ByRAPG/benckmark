package database

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type OrderItem struct {
	ProductID string  `json:"productId"`
	Quantity  int     `json:"quantity"`
	Price     float64 `json:"price"`
}

type OrderRecord struct {
	OrderID     string
	CustomerID  string
	TotalAmount float64
	ItemsCount  int
	Items       []OrderItem
}

func Connect(ctx context.Context) (*pgxpool.Pool, error) {
	dsn := fmt.Sprintf(
		"postgres://%s:%s@%s:%s/%s?sslmode=disable",
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_HOST"),
		os.Getenv("DB_PORT"),
		os.Getenv("DB_NAME"),
	)

	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, err
	}

	config.MaxConns = 30
	config.MinConns = 5
	config.MaxConnLifetime = 30 * time.Minute

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, err
	}

	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, err
	}

	return pool, nil
}

func InsertOrder(ctx context.Context, pool *pgxpool.Pool, order OrderRecord) (time.Time, error) {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return time.Time{}, err
	}
	defer tx.Rollback(ctx)

	var createdAt time.Time
	err = tx.QueryRow(
		ctx,
		`INSERT INTO orders (order_id, customer_id, total_amount, items_count)
		 VALUES ($1, $2, $3, $4)
		 RETURNING created_at`,
		order.OrderID, order.CustomerID, order.TotalAmount, order.ItemsCount,
	).Scan(&createdAt)
	if err != nil {
		return time.Time{}, err
	}

	// Usamos pgx.Batch dentro de la transacción para reducir round-trips a Postgres
	batch := &pgx.Batch{}
	for _, item := range order.Items {
		batch.Queue(
			`INSERT INTO order_items (order_id, product_id, quantity, price)
			 VALUES ($1, $2, $3, $4)`,
			order.OrderID, item.ProductID, item.Quantity, item.Price,
		)
	}

	br := tx.SendBatch(ctx, batch)
	for range order.Items {
		if _, err := br.Exec(); err != nil {
			br.Close()
			return time.Time{}, err
		}
	}
	if err := br.Close(); err != nil {
		return time.Time{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return time.Time{}, err
	}

	return createdAt, nil
}