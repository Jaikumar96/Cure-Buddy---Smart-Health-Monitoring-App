package com.example.curebuddy_backend.service;

import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Map;

@Service
public class MedicineDiscountService {

    public List<Map<String, String>> getAvailableDiscounts() {
        return List.of(
                Map.of(
                        "offer", "Flat 10% off on all medicine orders above ₹500",
                        "code", "HEALTH10",
                        "validity", "Till 31-May-2025"
                ),
                Map.of(
                        "offer", "15% cashback on PayTM payments",
                        "code", "PAYTM15",
                        "validity", "Till 15-June-2025"
                ),
                Map.of(
                        "offer", "Free home delivery on orders above ₹999",
                        "code", "FREESHIP",
                        "validity", "No expiry"
                )
        );
    }
}
