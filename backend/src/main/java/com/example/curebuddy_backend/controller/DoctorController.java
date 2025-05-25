package com.example.curebuddy_backend.controller;


import com.example.curebuddy_backend.model.HealthReport;
import com.example.curebuddy_backend.repository.HealthReportRepository;
import com.example.curebuddy_backend.service.EmailService;
import com.example.curebuddy_backend.service.TwilioService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/doctor")
@PreAuthorize("hasRole('DOCTOR')") // Only Doctors allowed
public class DoctorController {

    @Autowired
    private HealthReportRepository repo;

    @Autowired
    private EmailService emailService;

    @Autowired
    private TwilioService twilioService;

    @GetMapping("/patient-reports")
    public ResponseEntity<?> getAllPatientReports() {
        List<HealthReport> reports = repo.findAll();
        List<Map<String, Object>> response = new ArrayList<>();

        for (HealthReport report : reports) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", report.getId()); // <<< --- ADD THIS LINE
            map.put("patientEmail", report.getPatientEmail());
            map.put("fileName", report.getFileName());
            map.put("healthRiskPrediction", report.getHealthRiskPrediction());
            map.put("doctorRemarks", report.getDoctorRemarks());
            map.put("doctorAdvice", report.getDoctorAdvice());
            // You might also want to send uploadedAt if useful for doctors
            map.put("uploadedAt", report.getUploadedAt());
            response.add(map);
        }
        return ResponseEntity.ok(response);
    }


    @PostMapping("/respond/{reportId}")
    public ResponseEntity<?> addDoctorRemarks(
            @PathVariable String reportId,
            @RequestBody Map<String, String> request,
            @RequestHeader("Authorization") String authHeader) {

        Optional<HealthReport> reportOpt = repo.findById(reportId);
        if (reportOpt.isEmpty()) return ResponseEntity.status(404).body("Report not found");

        HealthReport report = reportOpt.get();

        String doctorEmail = extractEmailFromToken(authHeader);
        String remarks = request.get("remarks");
        String advice = request.get("advice");

        report.setDoctorEmail(doctorEmail);
        report.setDoctorRemarks(remarks);
        report.setDoctorAdvice(advice);
        report.setDoctorRespondedAt(LocalDateTime.now());
        repo.save(report);

        // Notify patient via Email and SMS
        String patientEmail = report.getPatientEmail();
        String patientPhoneNumber = "+917339202176"; // use real if stored, else dummy

        // Email
        emailService.sendEmail(
                patientEmail,
                "Your Health Report Reviewed - Cure Buddy",
                "Dear Patient,\n\nYour health report was reviewed.\n\nRemarks: " + remarks +
                        "\nAdvice: " + advice + "\n\nStay healthy!"
        );

        // SMS
        twilioService.sendSms(
                patientPhoneNumber,
                "Your health report has been reviewed by Cure Buddy Doctor. Please check app for advice."
        );

        return ResponseEntity.ok("Doctor remarks added and patient notified!");
    }


    private String extractEmailFromToken(String authHeader) {
        // Assuming JWT token: "Bearer eyJhbGciOiJIUzI1NiIsIn..."
        if (authHeader.startsWith("Bearer ")) {
            return "";  // you can extract real email if you want or send via Authentication param
        }
        return "doctor@example.com";
    }

    @GetMapping("/patient-history/{email}")
    public ResponseEntity<?> getPatientHistory(@PathVariable String email) {
        List<HealthReport> reports = repo.findByPatientEmail(email);

        if (reports.isEmpty()) {
            return ResponseEntity.status(404).body("No reports found for this patient.");
        }

        List<Map<String, Object>> response = new ArrayList<>();

        for (HealthReport report : reports) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", report.getId()); // <<< --- ADD THIS LINE
            map.put("fileName", report.getFileName());
            map.put("uploadedAt", report.getUploadedAt());
            map.put("healthRiskPrediction", report.getHealthRiskPrediction());
            map.put("doctorRemarks", report.getDoctorRemarks());
            map.put("doctorAdvice", report.getDoctorAdvice());
            response.add(map);
        }

        return ResponseEntity.ok(response);
    }
    @PostMapping("/respond-all")
    public ResponseEntity<?> addRemarksToMultipleReports(
            @RequestBody Map<String, Object> request,
            @RequestHeader("Authorization") String authHeader) {

        List<String> reportIds = (List<String>) request.get("reportIds");
        String remarks = (String) request.get("remarks");
        String advice = (String) request.get("advice");

        if (reportIds == null || reportIds.isEmpty()) {
            return ResponseEntity.badRequest().body("No report IDs provided.");
        }

        String doctorEmail = extractEmailFromToken(authHeader);

        for (String id : reportIds) {
            Optional<HealthReport> reportOpt = repo.findById(id);
            if (reportOpt.isPresent()) {
                HealthReport report = reportOpt.get();
                report.setDoctorRemarks(remarks);
                report.setDoctorAdvice(advice);
                report.setDoctorEmail(doctorEmail);
                report.setDoctorRespondedAt(LocalDateTime.now());
                repo.save(report);
            }
        }

        return ResponseEntity.ok("Doctor remarks added to multiple reports successfully!");
    }


}
