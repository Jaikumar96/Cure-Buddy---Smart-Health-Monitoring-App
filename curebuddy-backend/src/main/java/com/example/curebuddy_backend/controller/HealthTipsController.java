package com.example.curebuddy_backend.controller;

import com.example.curebuddy_backend.service.HealthTipsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/patient")
public class HealthTipsController {

    @Autowired
    private HealthTipsService healthTipsService;

    @GetMapping("/health-tips/{riskLevel}")
    public ResponseEntity<?> getHealthTips(@PathVariable String riskLevel) {
        var tips = healthTipsService.getTips(riskLevel);
        return ResponseEntity.ok(tips);
    }
}
