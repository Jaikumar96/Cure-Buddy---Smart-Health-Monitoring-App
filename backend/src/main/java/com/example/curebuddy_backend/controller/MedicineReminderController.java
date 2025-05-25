package com.example.curebuddy_backend.controller;

import com.example.curebuddy_backend.model.MedicineReminder;
import com.example.curebuddy_backend.repository.MedicineReminderRepository;
import com.example.curebuddy_backend.service.EmailService;
import com.example.curebuddy_backend.service.TwilioService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.web.bind.annotation.*;

import java.time.LocalTime;
import java.util.List;

@RestController
@RequestMapping("/api/medicine")
public class MedicineReminderController {

    @Autowired
    private MedicineReminderRepository reminderRepo;

    @Autowired
    private EmailService emailService;

    @Autowired
    private TwilioService twilioService;

    @PostMapping("/reminders")
    public ResponseEntity<?> setReminder(Authentication auth, @RequestBody MedicineReminder reminder) {
        reminder.setPatientEmail(auth.getName());
        reminderRepo.save(reminder);
        return ResponseEntity.ok("Reminder set successfully!");
    }

    @GetMapping("/my-reminders")
    public ResponseEntity<?> getMyReminders(Authentication auth) {
        var reminders = reminderRepo.findAll()
                .stream()
                .filter(r -> r.getPatientEmail().equals(auth.getName()))
                .toList();
        return ResponseEntity.ok(reminders);
    }

    @Scheduled(cron = "0 * * * * *")  // Check every minute (for testing)
    public void sendReminders() {
        LocalTime now = LocalTime.now().withSecond(0).withNano(0);
        List<MedicineReminder> reminders = reminderRepo.findByReminderTime(now);

        for (MedicineReminder reminder : reminders) {
            // Send Email
            emailService.sendEmail(
                    reminder.getPatientEmail(),
                    "Medicine Reminder 💊",
                    "Dear Patient,\n\nPlease take your medicine: " + reminder.getMedicineName() + ".\n\nStay Healthy, Cure Buddy."
            );

            // Send SMS (dummy for now)
            twilioService.sendSms(
                    "+917339202176",  // Replace with real phone if stored
                    "Medicine Reminder: Take " + reminder.getMedicineName() + " - Cure Buddy"
            );
        }
    }
}
