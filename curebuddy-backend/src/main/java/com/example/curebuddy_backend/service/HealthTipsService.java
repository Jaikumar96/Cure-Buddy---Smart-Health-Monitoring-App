package com.example.curebuddy_backend.service;

import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class HealthTipsService {

    public List<String> getTips(String riskLevel) {
        switch (riskLevel.toUpperCase()) {
            case "NORMAL":
                return List.of(
                        "Maintain a balanced diet rich in fruits and vegetables.",
                        "Exercise at least 30 minutes a day.",
                        "Regularly monitor your health parameters."
                );
            case "HIGH":
                return List.of(
                        "Monitor your blood pressure and sugar levels closely.",
                        "Reduce salt and sugar intake.",
                        "Consult a doctor if symptoms persist."
                );
            case "CRITICAL":
                return List.of(
                        "Seek immediate medical attention.",
                        "Do not ignore any critical symptoms like chest pain, dizziness.",
                        "Avoid stress and follow emergency medical advice."
                );
            default:
                return List.of("Stay healthy and regularly monitor your health.");
        }
    }
}
