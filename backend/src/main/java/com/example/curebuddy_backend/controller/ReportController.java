package com.example.curebuddy_backend.controller;

import com.example.curebuddy_backend.model.HealthReport;
import com.example.curebuddy_backend.repository.HealthReportRepository;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus; // Added for explicit status codes
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/patient")
public class ReportController {

    @Autowired
    private HealthReportRepository repo;

    private final String uploadDir = "uploads/";

    @PostMapping("/upload-report")
    public ResponseEntity<?> uploadReport(@RequestParam("file") MultipartFile file, Authentication auth) throws IOException {
        String email = auth.getName();

        if (file.isEmpty()) {
            return ResponseEntity.badRequest().body("No file uploaded");
        }

        String fileName = StringUtils.cleanPath(Objects.requireNonNull(file.getOriginalFilename()));
        String fileType = file.getContentType();

        // Create uploads directory if not exist
        File directory = new File(uploadDir);
        if (!directory.exists()) {
            directory.mkdirs();
        }

        // Save file
        Path filePath = Paths.get(uploadDir + fileName);
        Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

        // Extract text if PDF
        String extractedText = "";
        if (fileType != null && fileType.equalsIgnoreCase("application/pdf")) {
            extractedText = extractTextFromPdf(filePath.toString());
        }

        // Save metadata and extracted text in MongoDB
        HealthReport report = new HealthReport();
        report.setPatientEmail(email);
        report.setFileName(fileName);
        report.setFileType(fileType);
        report.setUploadedAt(LocalDateTime.now());
        report.setExtractedText(extractedText);

        HealthReport savedReport = repo.save(report);

        Map<String, Object> successResponse = new HashMap<>();
        successResponse.put("message", "Report uploaded and analyzed successfully!");
        successResponse.put("reportId", savedReport.getId());
        successResponse.put("fileName", savedReport.getFileName());

        return ResponseEntity.ok(successResponse);
    }

    private String extractTextFromPdf(String path) {
        try (PDDocument document = Loader.loadPDF(new File(path))) {
            if (document.isEncrypted()) {
                System.err.println("PDF is encrypted, cannot extract text without decryption: " + path);
                return "";
            }
            return new PDFTextStripper().getText(document);
        } catch (IOException e) {
            e.printStackTrace();
            return "Error extracting text from PDF: " + e.getMessage();
        }
    }

    @GetMapping("/my-reports")
    public ResponseEntity<?> getMyReports(Authentication auth) {
        String email = auth.getName();
        List<HealthReport> reports = repo.findByPatientEmail(email);

        List<Map<String, Object>> response = new ArrayList<>();

        for (HealthReport report : reports) {
            Map<String, Object> map = new HashMap<>();
            map.put("_id", report.getId());
            map.put("fileName", report.getFileName());
            map.put("uploadedAt", report.getUploadedAt());
            map.put("healthRiskPrediction", report.getHealthRiskPrediction());
            // Adding doctor's remarks and advice here as well for the list view,
            // so the app can display a summary or indicator if remarks are present.
            // Values will be null if doctor hasn't responded.
            map.put("doctorRemarks", report.getDoctorRemarks());
            map.put("doctorAdvice", report.getDoctorAdvice());
            map.put("doctorRespondedAt", report.getDoctorRespondedAt());
            response.add(map);
        }

        return ResponseEntity.ok(response);
    }

    // --- NEW API ENDPOINT FOR PATIENT TO VIEW SPECIFIC REPORT DETAILS ---
    // --- INCLUDING DOCTOR'S REMARKS AND ADVICE ---
    @GetMapping("/reports/{reportId}")
    public ResponseEntity<?> getReportDetailsById(@PathVariable String reportId, Authentication auth) {
        String patientEmail = auth.getName(); // Get authenticated patient's email

        Optional<HealthReport> reportOpt = repo.findById(reportId);

        if (reportOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", "Report not found with ID: " + reportId));
        }

        HealthReport report = reportOpt.get();

        // Security Check: Ensure the authenticated patient is the owner of the report
        if (!report.getPatientEmail().equals(patientEmail)) {
            // Obfuscate: do not reveal that the report exists but belongs to someone else.
            // Treat it as "not found" for this user.
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", "Report not found with ID: " + reportId));
            // Or use HttpStatus.FORBIDDEN with a generic "Access Denied" message
            // return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("message", "Access Denied"));
        }

        // Prepare the response.
        Map<String, Object> reportDetails = new HashMap<>();
        reportDetails.put("_id", report.getId()); // Consistent with _id from /my-reports
        reportDetails.put("fileName", report.getFileName());
        reportDetails.put("uploadedAt", report.getUploadedAt());
        reportDetails.put("healthRiskPrediction", report.getHealthRiskPrediction());
        reportDetails.put("fileType", report.getFileType()); // Might be useful for client
        // reportDetails.put("extractedText", report.getExtractedText()); // Usually not sent to client unless specifically needed due to size

        // Doctor's response details
        reportDetails.put("doctorRemarks", report.getDoctorRemarks()); // Will be null if not set
        reportDetails.put("doctorAdvice", report.getDoctorAdvice());   // Will be null if not set
        reportDetails.put("doctorRespondedAt", report.getDoctorRespondedAt()); // Will be null if not set
        reportDetails.put("doctorEmail", report.getDoctorEmail()); // Optional: patient might want to know which doctor (email) responded

        return ResponseEntity.ok(reportDetails);
    }
    // --- END OF NEW API ENDPOINT ---

    @GetMapping("/insights")
    public ResponseEntity<?> getHealthInsights(Authentication auth) {
        String email = auth.getName();
        List<HealthReport> reports = repo.findByPatientEmail(email);

        if (reports.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("message", "No reports found for patient."));
        }

        reports.sort(Comparator.comparing(HealthReport::getUploadedAt, Comparator.nullsLast(Comparator.naturalOrder())));

        List<String> predictions = reports.stream()
                .map(HealthReport::getHealthRiskPrediction)
                .filter(Objects::nonNull)
                .toList();

        if (predictions.size() < 2) {
            Map<String, String> response = new HashMap<>();
            response.put("trend", "Not enough data");
            response.put("details", "Not enough analyzed reports to detect trend. At least two analyzed reports are needed.");
            return ResponseEntity.ok(response);
        }

        String first = predictions.get(0);
        String last = predictions.get(predictions.size() - 1);

        String trend;
        String details;

        Map<String, Integer> riskLevels = Map.of(
                "NORMAL", 1,
                "MODERATE", 2,
                "CRITICAL", 3
        );

        Integer firstLevel = riskLevels.get(first.toUpperCase());
        Integer lastLevel = riskLevels.get(last.toUpperCase());

        if (firstLevel == null || lastLevel == null) {
            trend = "Indeterminate";
            details = "Could not determine trend due to unrecognized risk level(s): " + first + ", " + last;
        } else if (firstLevel.equals(lastLevel)) {
            trend = "Stable";
            details = "Health risk remained " + last + " over time.";
        } else if (lastLevel > firstLevel) {
            trend = "Health Worsening";
            details = "Health risk changed from " + first + " to " + last + ".";
        } else {
            trend = "Health Improving";
            details = "Health risk changed from " + first + " to " + last + ".";
        }

        Map<String, String> response = new HashMap<>();
        response.put("trend", trend);
        response.put("details", details);

        return ResponseEntity.ok(response);
    }
}