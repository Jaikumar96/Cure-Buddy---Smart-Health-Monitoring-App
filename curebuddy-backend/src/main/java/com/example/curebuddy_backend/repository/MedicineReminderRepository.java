package com.example.curebuddy_backend.repository;

import com.example.curebuddy_backend.model.MedicineReminder;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.time.LocalTime;
import java.util.List;

public interface MedicineReminderRepository extends MongoRepository<MedicineReminder, String> {
    List<MedicineReminder> findByReminderTime(LocalTime time);
}
