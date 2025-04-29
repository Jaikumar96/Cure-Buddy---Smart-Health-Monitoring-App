package com.example.curebuddy_backend.controller;

import com.example.curebuddy_backend.service.EmailService;
import com.example.curebuddy_backend.service.TwilioService;
import com.example.curebuddy_backend.model.HealthReport;
import com.example.curebuddy_backend.repository.HealthReportRepository;
import com.example.curebuddy_backend.service.WekaAnalysisService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@RestController
@RequestMapping("/api/patient")
public class ReportAnalysisController {

    @Autowired
    private HealthReportRepository repo;

    @Autowired
    private WekaAnalysisService wekaService;

    @Autowired
    private EmailService emailService;

    @Autowired
    private TwilioService twilioService;

    @GetMapping("/report-analysis/{id}")
    public ResponseEntity<?> analyzeReport(@PathVariable String id) throws Exception {
        Optional<HealthReport> reportOpt = repo.findById(id);
        if (reportOpt.isEmpty()) return ResponseEntity.status(404).body("Report not found");

        HealthReport report = reportOpt.get();
        String text = report.getExtractedText();

// After extraction
        double bloodSugar = extractBloodSugar(text);
        double bloodPressure = extractBloodPressure(text);
        double pulseRate = extractPulseRate(text);
        double cholesterol = extractCholesterol(text);
        double ecgScore = extractEcgScore(text);

// MANUALLY SIMULATE CRITICAL CASE for testing
        bloodSugar = 250;
        bloodPressure = 170;
        pulseRate = 100;
        cholesterol = 300;
        ecgScore = 5.0;


        // Predict with improved Weka model
        String risk = wekaService.predictHealthRisk(bloodSugar, bloodPressure, pulseRate, cholesterol, ecgScore);

        // Save back prediction
        report.setHealthRiskPrediction(risk);
        repo.save(report);

        // SMART ALERT: Email & SMS if HIGH or CRITICAL
        if (risk.equalsIgnoreCase("HIGH") || risk.equalsIgnoreCase("CRITICAL")) {
            String patientEmail = report.getPatientEmail();
            String patientPhoneNumber = "+917339202176";  // replace with real if stored in DB

            // Send Email
            emailService.sendEmail(
                    patientEmail,
                    "Urgent Health Alert from Cure Buddy 🚨",
                    "Dear Patient,\n\nYour health risk level is detected as " + risk +
                            ".\nPlease consult a doctor immediately.\n\nStay safe,\nCure Buddy Team."
            );

            // Send SMS
            twilioService.sendSms(
                    patientPhoneNumber,
                    "🚨 Urgent: Your health risk is " + risk + ". Please consult doctor. - Cure Buddy"
            );
        }

        return ResponseEntity.ok("Report analyzed successfully! Health Risk: " + risk);
    }


    private double extractBloodSugar(String text) {
        Pattern pattern = Pattern.compile("(\\d+)\\s*mg/dL");
        Matcher matcher = pattern.matcher(text);
        if (matcher.find()) {
            return Double.parseDouble(matcher.group(1));
        }
        return -1;
    }

    private double extractBloodPressure(String text) {
        Pattern pattern = Pattern.compile("(\\d{2,3})/(\\d{2,3})");
        Matcher matcher = pattern.matcher(text);
        if (matcher.find()) {
            return Double.parseDouble(matcher.group(1));
        }
        return -1;
    }

    private double extractPulseRate(String text) {
        // For now, simulate pulse rate, unless you want to parse properly later
        return 80;
    }
    private double extractCholesterol(String text) {
        // For now, simulate 190 mg/dL
        return 190;
    }

    private double extractEcgScore(String text) {
        // For now, simulate 1.5
        return 1.5;
    }

}
