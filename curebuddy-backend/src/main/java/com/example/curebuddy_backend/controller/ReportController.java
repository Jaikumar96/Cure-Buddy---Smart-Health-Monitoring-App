package com.example.curebuddy_backend.controller;

import com.example.curebuddy_backend.model.HealthReport;
import com.example.curebuddy_backend.repository.HealthReportRepository;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.util.StringUtils;

import java.io.File;
import java.io.IOException;
import java.nio.file.*;
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

        String fileName = StringUtils.cleanPath(file.getOriginalFilename());
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
        if (fileType.equalsIgnoreCase("application/pdf")) {
            extractedText = extractTextFromPdf(filePath.toString());
        }

        // Save metadata and extracted text in MongoDB
        HealthReport report = new HealthReport();
        report.setPatientEmail(email);
        report.setFileName(fileName);
        report.setFileType(fileType);
        report.setUploadedAt(LocalDateTime.now());
        report.setExtractedText(extractedText);

        repo.save(report);

        return ResponseEntity.ok("Report uploaded and analyzed successfully!");
    }

    private String extractTextFromPdf(String path) {
        try (PDDocument document = PDDocument.load(new File(path))) {
            return new PDFTextStripper().getText(document);
        } catch (IOException e) {
            e.printStackTrace();
            return "";
        }
    }
    @GetMapping("/my-reports")
    public ResponseEntity<?> getMyReports(Authentication auth) {
        String email = auth.getName();
        List<HealthReport> reports = repo.findByPatientEmail(email);

        List<Map<String, Object>> response = new ArrayList<>();

        for (HealthReport report : reports) {
            Map<String, Object> map = new HashMap<>();
            map.put("fileName", report.getFileName());
            map.put("uploadedAt", report.getUploadedAt());
            map.put("healthRiskPrediction", report.getHealthRiskPrediction());
            response.add(map);
        }

        return ResponseEntity.ok(response);
    }

    @GetMapping("/insights")
    public ResponseEntity<?> getHealthInsights(Authentication auth) {
        String email = auth.getName();
        List<HealthReport> reports = repo.findByPatientEmail(email);

        if (reports.isEmpty()) {
            return ResponseEntity.status(404).body("No reports found for patient.");
        }

        // Sort reports by uploadedAt
        reports.sort(Comparator.comparing(HealthReport::getUploadedAt));

        // Extract all predictions ignoring null
        List<String> predictions = reports.stream()
                .map(HealthReport::getHealthRiskPrediction)
                .filter(Objects::nonNull)
                .toList();

        if (predictions.size() < 2) {
            return ResponseEntity.ok("Not enough analyzed reports to detect trend.");
        }

        String first = predictions.get(0);
        String last = predictions.get(predictions.size() - 1);

        String trend;
        String details;

        if (first.equals(last)) {
            trend = "Stable";
            details = "Health risk remained " + first + " over time.";
        } else if (isWorsening(first, last)) {
            trend = "Health Worsening";
            details = "Previous risk was " + first + ", now it is " + last + ".";
        } else {
            trend = "Health Improving";
            details = "Previous risk was " + first + ", now it is " + last + ".";
        }

        Map<String, String> response = new HashMap<>();
        response.put("trend", trend);
        response.put("details", details);

        return ResponseEntity.ok(response);
    }

    private boolean isWorsening(String first, String last) {
        // Ranking: NORMAL < HIGH < CRITICAL
        Map<String, Integer> riskLevels = Map.of(
                "NORMAL", 1,
                "HIGH", 2,
                "CRITICAL", 3
        );

        return riskLevels.get(last) > riskLevels.get(first);
    }


}
