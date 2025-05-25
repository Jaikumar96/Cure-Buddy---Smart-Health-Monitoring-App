package com.example.curebuddy_backend.service;

import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Map;

@Service
public class MedicineDiscountService {

    // This data will remain static/dummy as there are no free live APIs for this.
    // You can make this list more extensive or representative of typical offers.
    public List<Map<String, String>> getAvailableDiscounts() {
        return List.of(
                Map.of(
                        "offer", "Flat 15% off on your first medicine order (App Exclusive)",
                        "code", "NEWUSER15",
                        "validity", "Till end of month",
                        "source", "Platform Offer (Example)"
                ),
                Map.of(
                        "offer", "Get 10% cashback using SpecificBank Credit Card",
                        "code", "BANKCARD10",
                        "validity", "Limited Period",
                        "source", "Bank Offer (Example)"
                ),
                Map.of(
                        "offer", "Seasonal discounts on wellness products - Check in-app banners!",
                        "code", "N/A",
                        "validity", "Seasonal",
                        "source", "General Promotion (Example)"
                )
        );
    }
}