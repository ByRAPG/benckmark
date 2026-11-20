package com.benchmark.orders;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;

@Service
public class DatabaseService {

    private final JdbcTemplate jdbcTemplate;

    public DatabaseService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public record OrderItemDto(String productId, int quantity, double price) {}

    @Transactional
    public Instant insertOrder(
            String orderId,
            String customerId,
            BigDecimal totalAmount,
            int itemsCount,
            List<OrderItemDto> items
    ) {
        Timestamp createdAt = jdbcTemplate.queryForObject(
                """
                INSERT INTO orders (order_id, customer_id, total_amount, items_count)
                VALUES (?, ?, ?, ?)
                RETURNING created_at
                """,
                Timestamp.class,
                orderId, customerId, totalAmount, itemsCount
        );

        jdbcTemplate.batchUpdate(
                """
                INSERT INTO order_items (order_id, product_id, quantity, price)
                VALUES (?, ?, ?, ?)
                """,
                items,
                items.size(),
                (ps, item) -> {
                    ps.setString(1, orderId);
                    ps.setString(2, item.productId());
                    ps.setInt(3, item.quantity());
                    ps.setBigDecimal(4, BigDecimal.valueOf(item.price()));
                }
        );

        return createdAt != null ? createdAt.toInstant() : Instant.now();
    }
}