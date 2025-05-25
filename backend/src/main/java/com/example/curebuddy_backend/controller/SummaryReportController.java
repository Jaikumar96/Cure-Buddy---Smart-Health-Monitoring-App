package com.example.curebuddy_backend.controller;

import com.example.curebuddy_backend.model.HealthReport;
import com.example.curebuddy_backend.repository.HealthReportRepository;
import com.example.curebuddy_backend.service.EmailService;
import com.itextpdf.io.font.constants.StandardFonts;
import com.itextpdf.kernel.font.PdfFont;
import com.itextpdf.kernel.font.PdfFontFactory;
import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfWriter;
import com.itextpdf.layout.Document;
import com.itextpdf.layout.element.Cell;
import com.itextpdf.layout.element.Paragraph;
import com.itextpdf.layout.element.Table;
import com.itextpdf.layout.properties.TextAlignment;
import com.itextpdf.layout.properties.UnitValue;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Objects; // <--- IMPORTANT IMPORT FOR NULL CHECKS
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/reports")
public class SummaryReportController {

    @Autowired
    private HealthReportRepository reportRepo;

    @Autowired
    private EmailService emailService;

    // Formatters for consistent date/time display
    private static final DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private static final DateTimeFormatter dateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final DateTimeFormatter timeFormatter = DateTimeFormatter.ofPattern("HH:mm:ss");


    @PostMapping("/generate")
    public ResponseEntity<?> generateReport(Authentication auth, @RequestBody Map<String, String> request) throws IOException {
        String patientEmail = auth.getName(); // Using email as the patient identifier
        LocalDate startDate = LocalDate.parse(request.get("startDate"));
        LocalDate endDate = LocalDate.parse(request.get("endDate"));
        String format = request.getOrDefault("format", "txt").toLowerCase(); // Default to txt, ensure lowercase

        List<HealthReport> reports = reportRepo.findByPatientEmail(patientEmail).stream()
                .filter(r -> {
                    if (r.getUploadedAt() == null) return false; // Guard against null upload dates
                    LocalDate date = r.getUploadedAt().toLocalDate();
                    // Inclusive date range check
                    return !(date.isBefore(startDate) || date.isAfter(endDate));
                })
                .sorted(Comparator.comparing(HealthReport::getUploadedAt)) // Sort reports by date
                .collect(Collectors.toList());

        if (reports.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "No health reports found for the selected dates."));
        }

        // Determine file extension
        String fileExtension;
        if ("pdf".equalsIgnoreCase(format)) {
            fileExtension = "pdf";
        } else if ("csv".equalsIgnoreCase(format)) {
            fileExtension = "csv";
        } else {
            fileExtension = "txt"; // Default to txt
        }

        String fileName = "health_summary_" + patientEmail.split("@")[0] + "_" + System.currentTimeMillis() + "." + fileExtension;
        String filePath = "reports/" + fileName;

        File reportDir = new File("reports/");
        if (!reportDir.exists()) {
            reportDir.mkdirs(); // Ensure the directory exists
        }

        if ("pdf".equalsIgnoreCase(fileExtension)) {
            generatePdfReport(filePath, reports, patientEmail, startDate, endDate);
        } else {
            // Use try-with-resources and specify UTF-8 encoding for the writer for TXT/CSV
            try (Writer writer = new OutputStreamWriter(new FileOutputStream(filePath), StandardCharsets.UTF_8)) {
                if ("csv".equalsIgnoreCase(fileExtension)) {
                    writer.write("Date,Time,Risk Level\n");
                    for (HealthReport r : reports) {
                        writer.write(
                                Objects.toString(r.getUploadedAt().toLocalDate().format(dateFormatter), "") + "," +
                                        Objects.toString(r.getUploadedAt().toLocalTime().format(timeFormatter), "") + "," +
                                        Objects.toString(r.getHealthRiskPrediction(), "N/A") + "\n"
                        );
                    }
                } else { // Generate enhanced TXT report (existing logic)
                    StringBuilder sb = new StringBuilder();
                    appendTxtReportContent(sb, reports, patientEmail, startDate, endDate); // Refactored to a helper
                    writer.write(sb.toString());
                }
            }
        }

        return ResponseEntity.ok(Map.of(
                "message", "Report generated successfully.",
                "reportId", fileName,
                "downloadLink", "/files/" + fileName // Assuming you have an endpoint at /files/{fileName}
        ));
    }

    private void generatePdfReport(String filePath, List<HealthReport> reports, String patientEmail, LocalDate startDate, LocalDate endDate) throws IOException {
        try (PdfWriter writer = new PdfWriter(filePath);
             PdfDocument pdfDocument = new PdfDocument(writer);
             Document document = new Document(pdfDocument)) {

            PdfFont font = PdfFontFactory.createFont(StandardFonts.HELVETICA);
            PdfFont boldFont = PdfFontFactory.createFont(StandardFonts.HELVETICA_BOLD);

            // Report Header
            document.add(new Paragraph("CURE BUDDY - CONFIDENTIAL HEALTH SUMMARY")
                    .setFont(boldFont).setFontSize(18).setTextAlignment(TextAlignment.CENTER));
            document.add(new Paragraph("\n")); // Spacing

            // Patient and Report Information
            document.add(new Paragraph("PATIENT IDENTIFIER:").setFont(boldFont));
            document.add(new Paragraph("  Email: " + Objects.toString(patientEmail, "N/A")).setFont(font));
            document.add(new Paragraph("\n"));

            document.add(new Paragraph("REPORT METADATA:").setFont(boldFont));
            document.add(new Paragraph("  Reporting Period: " + startDate.format(dateFormatter) + " to " + endDate.format(dateFormatter)).setFont(font));
            document.add(new Paragraph("  Report Generated On: " + LocalDateTime.now().format(dateTimeFormatter)).setFont(font));
            document.add(new Paragraph("  Total Entries Reviewed: " + reports.size()).setFont(font));
            document.add(new Paragraph("\n"));

            // Summary of Findings
            document.add(new Paragraph("SUMMARY OF FINDINGS:").setFont(boldFont));
            long criticalCount = reports.stream().filter(r -> "CRITICAL".equalsIgnoreCase(r.getHealthRiskPrediction())).count();
            long highCount = reports.stream().filter(r -> "HIGH".equalsIgnoreCase(r.getHealthRiskPrediction())).count();
            long moderateCount = reports.stream().filter(r -> "MODERATE".equalsIgnoreCase(r.getHealthRiskPrediction())).count();

            String overallAssessment;
            if (criticalCount > 0) {
                overallAssessment = "  Overall Assessment: URGENT ATTENTION REQUIRED\n" +
                        "  - " + criticalCount + " CRITICAL risk entries detected.";
            } else if (highCount > 0) {
                overallAssessment = "  Overall Assessment: ATTENTION ADVISED\n" +
                        "  - " + highCount + " HIGH risk entries detected.";
            } else if (moderateCount > 0) {
                overallAssessment = "  Overall Assessment: MONITORING RECOMMENDED\n" +
                        "  - " + moderateCount + " MODERATE risk entries detected.";
            } else {
                overallAssessment = "  Overall Assessment: STABLE / LOW RISK\n" +
                        "  - Health entries for this period are generally within acceptable limits.";
            }
            document.add(new Paragraph(Objects.toString(overallAssessment, "Assessment not available.")).setFont(font));
            document.add(new Paragraph("\n"));

            // Detailed Log
            document.add(new Paragraph("DETAILED HEALTH ENTRIES LOG:").setFont(boldFont));
            Table table = new Table(UnitValue.createPercentArray(new float[]{3, 3, 4})); // 3 columns
            table.setWidth(UnitValue.createPercentValue(100));
            table.addHeaderCell(new Cell().add(new Paragraph("Entry Date").setFont(boldFont)));
            table.addHeaderCell(new Cell().add(new Paragraph("Time").setFont(boldFont)));
            table.addHeaderCell(new Cell().add(new Paragraph("Risk Level").setFont(boldFont)));

            for (HealthReport r : reports) {
                // Assuming r.getUploadedAt() is non-null due to prior filtering
                String entryDateStr = r.getUploadedAt().toLocalDate().format(dateFormatter);
                String entryTimeStr = r.getUploadedAt().toLocalTime().format(timeFormatter);

                table.addCell(new Cell().add(new Paragraph(Objects.toString(entryDateStr, "")).setFont(font)));
                table.addCell(new Cell().add(new Paragraph(Objects.toString(entryTimeStr, "")).setFont(font)));
                table.addCell(new Cell().add(new Paragraph(
                        Objects.toString(r.getHealthRiskPrediction(), "N/A") // Use "N/A" or "" for an empty cell
                ).setFont(font)));
            }
            document.add(table);
            document.add(new Paragraph("\n"));

            // Recommendations
            document.add(new Paragraph("RECOMMENDATIONS & GUIDANCE:").setFont(boldFont));
            String recommendations;
            if (criticalCount > 0) {
                recommendations = "  ⚠️ URGENT: One or more CRITICAL health risk entries detected. \n" +
                        "     Please consult your healthcare provider IMMEDIATELY to discuss these findings.\n" +
                        "     Bring a copy of this summary to your appointment.";
            } else if (highCount > 0) {
                recommendations = "  ❗ ATTENTION: HIGH risk entries were noted. \n" +
                        "     It is strongly recommended to schedule an appointment with your doctor for further evaluation.";
            } else if (moderateCount > 0) {
                recommendations = "  🔸 MONITOR: MODERATE risk entries suggest a need for continued observation.\n" +
                        "     Discuss these at your next routine check-up or if symptoms worsen.";
            } else {
                recommendations = "  ✅ Your health entries for this period are within normal or low-risk limits.\n" +
                        "     Continue to maintain healthy lifestyle habits and follow routine medical advice.";
            }
            document.add(new Paragraph(Objects.toString(recommendations, "No specific recommendations at this time.")).setFont(font));
            document.add(new Paragraph("  - Always follow the specific advice given by your personal physician or healthcare provider.\n").setFont(font));
            document.add(new Paragraph("\n"));

            // Disclaimer
            document.add(new Paragraph("IMPORTANT DISCLAIMER:").setFont(boldFont));
            document.add(new Paragraph(
                    "This summary is generated based on data provided to Cure Buddy and is for " +
                            "informational purposes only. It DOES NOT constitute medical advice, diagnosis, " +
                            "or treatment. Always seek the advice of your physician or other qualified " +
                            "health provider with any questions you may have regarding a medical condition. " +
                            "Never disregard professional medical advice or delay in seeking it because " +
                            "of something you have read in this summary."
            ).setFont(font).setFontSize(10));
            document.add(new Paragraph("\n"));

            document.add(new Paragraph("Sincerely,\nThe Cure Buddy Team").setFont(font));
        }
    }

    // Helper method to keep the TXT generation logic separate
    private void appendTxtReportContent(StringBuilder sb, List<HealthReport> reports, String patientEmail, LocalDate startDate, LocalDate endDate) {
        // Report Header
        sb.append("============================================================\n");
        sb.append("            CURE BUDDY - CONFIDENTIAL HEALTH SUMMARY\n");
        sb.append("============================================================\n\n");

        // Patient and Report Information
        sb.append("PATIENT IDENTIFIER:\n");
        sb.append("  Email: ").append(Objects.toString(patientEmail, "N/A")).append("\n\n");

        sb.append("REPORT METADATA:\n");
        sb.append("  Reporting Period: ").append(startDate.format(dateFormatter)).append(" to ").append(endDate.format(dateFormatter)).append("\n");
        sb.append("  Report Generated On: ").append(LocalDateTime.now().format(dateTimeFormatter)).append("\n");
        sb.append("  Total Entries Reviewed: ").append(reports.size()).append("\n\n");

        // Summary of Findings
        sb.append("SUMMARY OF FINDINGS:\n");
        long criticalCount = reports.stream().filter(r -> "CRITICAL".equalsIgnoreCase(r.getHealthRiskPrediction())).count();
        long highCount = reports.stream().filter(r -> "HIGH".equalsIgnoreCase(r.getHealthRiskPrediction())).count();
        long moderateCount = reports.stream().filter(r -> "MODERATE".equalsIgnoreCase(r.getHealthRiskPrediction())).count();

        if (criticalCount > 0) {
            sb.append("  Overall Assessment: URGENT ATTENTION REQUIRED\n");
            sb.append("  - ").append(criticalCount).append(" CRITICAL risk entries detected.\n");
        } else if (highCount > 0) {
            sb.append("  Overall Assessment: ATTENTION ADVISED\n");
            sb.append("  - ").append(highCount).append(" HIGH risk entries detected.\n");
        } else if (moderateCount > 0) {
            sb.append("  Overall Assessment: MONITORING RECOMMENDED\n");
            sb.append("  - ").append(moderateCount).append(" MODERATE risk entries detected.\n");
        }
        else {
            sb.append("  Overall Assessment: STABLE / LOW RISK\n");
            sb.append("  - Health entries for this period are generally within acceptable limits.\n");
        }
        sb.append("\n");

        // Detailed Log
        sb.append("DETAILED HEALTH ENTRIES LOG:\n");
        sb.append("-------------------------------------------------\n");
        sb.append(String.format("| %-12s | %-10s | %-15s |\n", "Entry Date", "Time", "Risk Level"));
        sb.append("|--------------|------------|-----------------|\n");
        for (HealthReport r : reports) {
            // Assuming r.getUploadedAt() is non-null due to prior filtering
            String entryDateStr = r.getUploadedAt().toLocalDate().format(dateFormatter);
            String entryTimeStr = r.getUploadedAt().toLocalTime().format(timeFormatter);

            sb.append(String.format("| %-12s | %-10s | %-15s |\n",
                    Objects.toString(entryDateStr, ""),
                    Objects.toString(entryTimeStr, ""),
                    Objects.toString(r.getHealthRiskPrediction(), "N/A")
            ));
        }
        sb.append("-------------------------------------------------\n\n");

        // Recommendations
        sb.append("RECOMMENDATIONS & GUIDANCE:\n");
        if (criticalCount > 0) {
            sb.append("  ⚠️ URGENT: One or more CRITICAL health risk entries detected. \n");
            sb.append("     Please consult your healthcare provider IMMEDIATELY to discuss these findings.\n");
            sb.append("     Bring a copy of this summary to your appointment.\n");
        } else if (highCount > 0) {
            sb.append("  ❗ ATTENTION: HIGH risk entries were noted. \n");
            sb.append("     It is strongly recommended to schedule an appointment with your doctor for further evaluation.\n");
        } else if (moderateCount > 0) {
            sb.append("  🔸 MONITOR: MODERATE risk entries suggest a need for continued observation.\n");
            sb.append("     Discuss these at your next routine check-up or if symptoms worsen.\n");
        }
        else {
            sb.append("  ✅ Your health entries for this period are within normal or low-risk limits.\n");
            sb.append("     Continue to maintain healthy lifestyle habits and follow routine medical advice.\n");
        }
        sb.append("  - Always follow the specific advice given by your personal physician or healthcare provider.\n\n");

        // Disclaimer
        sb.append("------------------------------------------------------------\n");
        sb.append("IMPORTANT DISCLAIMER:\n");
        sb.append("This summary is generated based on data provided to Cure Buddy and is for\n");
        sb.append("informational purposes only. It DOES NOT constitute medical advice, diagnosis,\n");
        sb.append("or treatment. Always seek the advice of your physician or other qualified\n");
        sb.append("health provider with any questions you may have regarding a medical condition.\n");
        sb.append("Never disregard professional medical advice or delay in seeking it because\n");
        sb.append("of something you have read in this summary.\n");
        sb.append("------------------------------------------------------------\n\n");

        sb.append("Sincerely,\n");
        sb.append("The Cure Buddy Team\n");
    }


    @PostMapping("/share")
    public ResponseEntity<?> shareReport(@RequestBody Map<String, String> req) {
        String reportId = req.get("reportId");
        String recipientEmail = req.get("recipientEmail");
        String requesterName = req.getOrDefault("requesterName", "A Cure Buddy user");

        if (reportId == null || reportId.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("status", "failed", "error", "Report ID is required."));
        }
        if (recipientEmail == null || recipientEmail.isBlank() || !recipientEmail.contains("@")) {
            return ResponseEntity.badRequest().body(Map.of("status", "failed", "error", "A valid recipient email is required."));
        }

        // Optional: Verify file existence (good practice)
        File reportFile = new File("reports/" + reportId);
        if (!reportFile.exists()) {
            return ResponseEntity.status(404).body(Map.of("status", "failed", "error", "Report file not found. Make sure it was generated."));
        }

        String link = "http://localhost:8080/files/" + reportId; // Adjust if your domain/port differs. Ensure you have a file serving endpoint

        String subject = "Health Report Shared via Cure Buddy";
        String body = String.format(
                "Hello,\n\n" +
                        "%s has shared a health summary report with you using Cure Buddy.\n\n" +
                        "You can access the report here:\n%s\n\n" +
                        "Report ID: %s\n\n" +
                        "If you were not expecting this, please disregard this email.\n\n" +
                        "Best regards,\nThe Cure Buddy Team",
                Objects.toString(requesterName, "A Cure Buddy user"),
                link,
                Objects.toString(reportId, "N/A")
        );

        try {
            emailService.sendEmail(recipientEmail, subject, body);
            return ResponseEntity.ok(Map.of(
                    "shareId", UUID.randomUUID().toString(),
                    "status", "sent",
                    "message", "Report shared successfully with " + recipientEmail
            ));
        } catch (Exception e) {
            // Consider using a logger here instead of System.err
            System.err.println("Email sending failed: " + e.getMessage());
            return ResponseEntity.status(500).body(Map.of(
                    "status", "failed",
                    "error", "Could not send email: " + e.getMessage()
            ));
        }
    }
}