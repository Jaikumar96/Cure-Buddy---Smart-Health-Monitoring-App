package com.example.curebuddy_backend.service;

import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class PharmacyService {

    private final List<Map<String, String>> pharmacies = List.of(
            Map.of(
                    "name", "Apollo Pharmacy",
                    "address", "Greams Road, Chennai",
                    "phone", "044-2829-3333",
                    "city", "Chennai"
            ),
            Map.of(
                    "name", "MedPlus Pharmacy",
                    "address", "T Nagar, Chennai",
                    "phone", "044-2814-1234",
                    "city", "Chennai"
            ),
            Map.of(
                    "name", "1mg Health Store",
                    "address", "Koramangala, Bangalore",
                    "phone", "080-4372-5678",
                    "city", "Bangalore"
            )
            // Add more pharmacies for other cities too
    );

    public List<Map<String, String>> findByCity(String city) {
        return pharmacies.stream()
                .filter(pharmacy -> pharmacy.get("city").equalsIgnoreCase(city))
                .collect(Collectors.toList());
    }
}
