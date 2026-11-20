package com.benchmark.orders;

import com.benchmark.orders.DatabaseService.OrderItemDto;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    private final DatabaseService databaseService;

    public OrderController(DatabaseService databaseService) {
        this.databaseService = databaseService;
    }

    public record CreateOrderRequest(String customerId, List<OrderItemDto> items) {}

    public record CreateOrderResponse(
            String orderId,
            String customerId,
            BigDecimal totalAmount,
            int itemsCount,
            Instant processedAt
    ) {}

    @PostMapping
    public ResponseEntity<?> createOrder(@RequestBody CreateOrderRequest req) {
        if (req.customerId() == null || req.customerId().isBlank() || req.items() == null || req.items().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "customerId e items son requeridos"));
        }

        BigDecimal totalAmount = BigDecimal.ZERO;
        int itemsCount = 0;

        for (OrderItemDto item : req.items()) {
            BigDecimal lineTotal = BigDecimal.valueOf(item.price())
                    .multiply(BigDecimal.valueOf(item.quantity()));
            totalAmount = totalAmount.add(lineTotal);
            itemsCount += item.quantity();
        }
        totalAmount = totalAmount.setScale(2, RoundingMode.HALF_UP);

        String orderId = "ORD-" + UUID.randomUUID();
        Instant processedAt = databaseService.insertOrder(
                orderId,
                req.customerId(),
                totalAmount,
                itemsCount,
                req.items()
        );

        return ResponseEntity.status(HttpStatus.CREATED).body(
                new CreateOrderResponse(orderId, req.customerId(), totalAmount, itemsCount, processedAt)
        );
    }
}