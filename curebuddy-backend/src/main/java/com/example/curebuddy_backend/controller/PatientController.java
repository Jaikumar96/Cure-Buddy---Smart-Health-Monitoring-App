package com.example.curebuddy_backend.controller;

import com.example.curebuddy_backend.model.CheckupSchedule;
import com.example.curebuddy_backend.repository.CheckupRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@RequestMapping("/api/patient")
public class PatientController {

    @Autowired
    private CheckupRepository repo;

    @PostMapping("/schedule")
    public ResponseEntity<?> scheduleCheckup(@RequestBody CheckupSchedule schedule, Authentication auth) {
        String email = auth.getName();
        schedule.setPatientEmail(email);
        repo.save(schedule);
        return ResponseEntity.ok("Checkup scheduled successfully!");
    }

    @GetMapping("/my-schedules")
    public ResponseEntity<?> getMySchedules(Authentication auth) {
        String email = auth.getName();
        return ResponseEntity.ok(repo.findByPatientEmail(email));
    }

    @PutMapping("/update-schedule/{id}")
    public ResponseEntity<?> updateSchedule(@PathVariable String id, @RequestBody CheckupSchedule updated, Authentication auth) {
        Optional<CheckupSchedule> existing = repo.findById(id);
        if (existing.isEmpty()) return ResponseEntity.status(404).body("Schedule not found");

        CheckupSchedule schedule = existing.get();
        if (!schedule.getPatientEmail().equals(auth.getName())) {
            return ResponseEntity.status(403).body("Unauthorized access");
        }

        schedule.setVitalName(updated.getVitalName());
        schedule.setScheduledDateTime(updated.getScheduledDateTime());
        schedule.setFrequency(updated.getFrequency());

        repo.save(schedule);
        return ResponseEntity.ok("Schedule updated successfully!");
    }

    @DeleteMapping("/delete-schedule/{id}")
    public ResponseEntity<?> deleteSchedule(@PathVariable String id, Authentication auth) {
        Optional<CheckupSchedule> existing = repo.findById(id);
        if (existing.isEmpty()) return ResponseEntity.status(404).body("Schedule not found");

        CheckupSchedule schedule = existing.get();
        if (!schedule.getPatientEmail().equals(auth.getName())) {
            return ResponseEntity.status(403).body("Unauthorized access");
        }

        repo.deleteById(id);
        return ResponseEntity.ok("Schedule deleted successfully!");
    }


}
