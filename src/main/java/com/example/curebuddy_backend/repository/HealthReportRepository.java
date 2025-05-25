package com.example.curebuddy_backend.repository;

import com.example.curebuddy_backend.model.HealthReport;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface HealthReportRepository extends MongoRepository<HealthReport, String> {
    List<HealthReport> findByPatientEmail(String email);
}
