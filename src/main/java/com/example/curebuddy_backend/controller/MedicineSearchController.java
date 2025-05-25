package com.example.curebuddy_backend.controller;

import com.example.curebuddy_backend.service.MedicineCatalogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/medicine")
public class MedicineSearchController {

    @Autowired
    private MedicineCatalogService catalogService;

    @GetMapping("/search")
    public ResponseEntity<?> searchMedicines(@RequestParam String name) {
        var medicines = catalogService.searchByName(name);
        return ResponseEntity.ok(medicines);
    }
}
