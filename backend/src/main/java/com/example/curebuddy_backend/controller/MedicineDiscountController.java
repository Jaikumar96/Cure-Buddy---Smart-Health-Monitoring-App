package com.example.curebuddy_backend.controller;

import com.example.curebuddy_backend.service.MedicineDiscountService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/medicine")
public class MedicineDiscountController {

    @Autowired
    private MedicineDiscountService discountService;

    @GetMapping("/discounts")
    public ResponseEntity<?> getDiscounts() {
        var discounts = discountService.getAvailableDiscounts();
        return ResponseEntity.ok(discounts);
    }
}