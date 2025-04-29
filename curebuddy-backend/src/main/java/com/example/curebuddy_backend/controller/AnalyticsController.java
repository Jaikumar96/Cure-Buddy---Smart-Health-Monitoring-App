package com.example.curebuddy_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.IntStream;

@RestController
@RequestMapping("/api/analytics")
public class AnalyticsController {

    @GetMapping("/vitals")
    public ResponseEntity<?> getVitalsData(Authentication auth) {
        List<Map<String, Object>> vitals = IntStream.rangeClosed(1, 7)
                .mapToObj(i -> {
                    Map<String, Object> map = new HashMap<>();
                    map.put("date", LocalDate.now().minusDays(7 - i).toString());
                    map.put("heartRate", 70 + (int)(Math.random() * 10));
                    map.put("bloodPressure", 120 + (int)(Math.random() * 10));
                    return map;
                })
                .toList();

        return ResponseEntity.ok(vitals);
    }

    @GetMapping("/reports")
    public ResponseEntity<?> getHealthReportTrends(Authentication auth) {
        List<Map<String, Object>> reports = List.of(
                new HashMap<>(Map.of("date", LocalDate.now().minusDays(20).toString(), "risk", "NORMAL")),
                new HashMap<>(Map.of("date", LocalDate.now().minusDays(15).toString(), "risk", "MODERATE")),
                new HashMap<>(Map.of("date", LocalDate.now().minusDays(10).toString(), "risk", "NORMAL")),
                new HashMap<>(Map.of("date", LocalDate.now().minusDays(5).toString(), "risk", "CRITICAL")),
                new HashMap<>(Map.of("date", LocalDate.now().toString(), "risk", "NORMAL"))
        );

        return ResponseEntity.ok(reports);
    }


}
