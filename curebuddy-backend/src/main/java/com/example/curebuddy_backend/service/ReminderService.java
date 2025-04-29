package com.example.curebuddy_backend.service;

import com.example.curebuddy_backend.model.CheckupSchedule;
import com.example.curebuddy_backend.repository.CheckupRepository;
import com.example.curebuddy_backend.service.EmailService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
public class ReminderService {

    @Autowired
    private CheckupRepository repo;

    @Autowired
    private EmailService emailService;

    @Autowired
    private TwilioService twilioService;


    @Scheduled(cron = "0 0 9 * * *") // Every day 9 AM // every 30 seconds
    public void sendReminders() {
        LocalDate today = LocalDate.now();

        List<CheckupSchedule> checkups = repo.findAll();

        for (CheckupSchedule checkup : checkups) {
            if (checkup.getScheduledDateTime().toLocalDate().equals(today)) {

                // Send Email
                emailService.sendEmail(
                        checkup.getPatientEmail(),
                        "Cure Buddy Checkup Reminder",
                        "Dear Patient,\nYour " + checkup.getVitalName() +
                                " checkup is scheduled today at " + checkup.getScheduledDateTime().toLocalTime() + ".\n\nStay Healthy!"
                );

                System.out.println("[Reminder] Email sent to " + checkup.getPatientEmail());
            }
            // Simulate patient phone number (in real, store it properly in User model)
            String fakePhoneNumber = "+917339202176"; // Your verified test number

            twilioService.sendSms(
                    fakePhoneNumber,
                    "Reminder: Your " + checkup.getVitalName() +
                            " checkup is scheduled today at " + checkup.getScheduledDateTime().toLocalTime()
            );

        }

    }
}
