package com.example.curebuddy_backend.service;

import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class MedicineCatalogService {

    private final List<Map<String, Object>> medicines = List.of(
            Map.of(
                    "name", "Paracetamol",
                    "brand", "Calpol",
                    "price", 30,
                    "strength", "500mg",
                    "discount", "10% off"
            ),
            Map.of(
                    "name", "Paracetamol",
                    "brand", "Dolo 650",
                    "price", 35,
                    "strength", "650mg",
                    "discount", "12% off"
            ),
            Map.of(
                    "name", "Azithromycin",
                    "brand", "Azithral",
                    "price", 80,
                    "strength", "500mg",
                    "discount", "5% off"
            ),
            Map.of(
                    "name", "Azithromycin",
                    "brand", "Zithrocin",
                    "price", 75,
                    "strength", "500mg",
                    "discount", "8% off"
            )
            // Add more medicines
    );

    public List<Map<String, Object>> searchByName(String medicineName) {
        return medicines.stream()
                .filter(med -> ((String) med.get("name")).equalsIgnoreCase(medicineName))
                .collect(Collectors.toList());
    }
}
