package com.example.curebuddy_backend.controller;

import com.example.curebuddy_backend.service.PharmacyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/pharmacy")
public class PharmacyLocatorController {

    @Autowired
    private PharmacyService pharmacyService;

    @GetMapping("/locator")
    public ResponseEntity<?> locatePharmacies(@RequestParam String city) {
        var pharmacies = pharmacyService.findByCity(city);
        return ResponseEntity.ok(pharmacies);
    }
}
