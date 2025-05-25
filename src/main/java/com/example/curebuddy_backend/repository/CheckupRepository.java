package com.example.curebuddy_backend.repository;

import com.example.curebuddy_backend.model.CheckupSchedule;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface CheckupRepository extends MongoRepository<CheckupSchedule, String> {
    List<CheckupSchedule> findByPatientEmail(String email);
}
