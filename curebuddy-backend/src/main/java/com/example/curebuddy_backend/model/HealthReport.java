package com.example.curebuddy_backend.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Document(collection = "health_reports")
public class HealthReport {

    @Id
    private String id;

    private String patientEmail;
    private String fileName;
    private String fileType;
    private LocalDateTime uploadedAt;
    private String extractedText;
    private String healthRiskPrediction;
    private String doctorRemarks;
    private String doctorAdvice;
    private String doctorEmail;
    private LocalDateTime doctorRespondedAt;
// (Later after parsing)

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getPatientEmail() {
        return patientEmail;
    }

    public void setPatientEmail(String patientEmail) {
        this.patientEmail = patientEmail;
    }

    public String getFileName() {
        return fileName;
    }

    public void setFileName(String fileName) {
        this.fileName = fileName;
    }

    public String getFileType() {
        return fileType;
    }

    public void setFileType(String fileType) {
        this.fileType = fileType;
    }

    public LocalDateTime getUploadedAt() {
        return uploadedAt;
    }

    public void setUploadedAt(LocalDateTime uploadedAt) {
        this.uploadedAt = uploadedAt;
    }

    public String getExtractedText() {
        return extractedText;
    }

    public void setExtractedText(String extractedText) {
        this.extractedText = extractedText;
    }

    public String getHealthRiskPrediction() {
        return healthRiskPrediction;
    }

    public void setHealthRiskPrediction(String healthRiskPrediction) {
        this.healthRiskPrediction = healthRiskPrediction;
    }

    public String getDoctorRemarks() {
        return doctorRemarks;
    }

    public void setDoctorRemarks(String doctorRemarks) {
        this.doctorRemarks = doctorRemarks;
    }

    public String getDoctorEmail() {
        return doctorEmail;
    }

    public void setDoctorEmail(String doctorEmail) {
        this.doctorEmail = doctorEmail;
    }

    public String getDoctorAdvice() {
        return doctorAdvice;
    }

    public void setDoctorAdvice(String doctorAdvice) {
        this.doctorAdvice = doctorAdvice;
    }

    public LocalDateTime getDoctorRespondedAt() {
        return doctorRespondedAt;
    }

    public void setDoctorRespondedAt(LocalDateTime doctorRespondedAt) {
        this.doctorRespondedAt = doctorRespondedAt;
    }

    // Getters and Setters
}
