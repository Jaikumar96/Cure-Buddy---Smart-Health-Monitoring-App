package com.example.curebuddy_backend.controller;

// import com.example.curebuddy_backend.client.GooglePlacesApiClient; // REMOVE THIS - ALREADY DONE
import com.example.curebuddy_backend.service.LabLocatorService;   // ADD THIS - ALREADY DONE
import com.example.curebuddy_backend.model.Booking;
import com.example.curebuddy_backend.model.LabResult; // ENSURE THIS IMPORT IS CORRECT
import com.example.curebuddy_backend.repository.BookingRepository;
import com.example.curebuddy_backend.service.EmailService;
import com.example.curebuddy_backend.service.TwilioService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Random;
// import java.util.Map; // Only if needed for other methods

@RestController
@RequestMapping("/api/labs")
public class LabBookingController {

    private static final Logger logger = LoggerFactory.getLogger(LabBookingController.class);

    @Autowired
    private LabLocatorService labLocatorService; // USE THE NEW SERVICE - ALREADY DONE

    @Autowired
    private BookingRepository bookingRepo;
    @Autowired
    private EmailService emailService;
    @Autowired
    private TwilioService twilioService;

    @GetMapping("/providers")
    public ResponseEntity<?> getLabProviders(
            @RequestParam String state,
            @RequestParam(required = false) String district) {

        logger.info("======================================================================");
        logger.info("=== Lab Providers Request Start (Using OSM/Overpass) ===");
        logger.info("State: [{}], District: [{}]", state, district);
        logger.info("======================================================================");

        List<LabResult> labs; // Use the new LabResult model
        try {
            labs = labLocatorService.findLabsByLocation(state, district);
        } catch (Exception e) {
            logger.error("Error fetching labs from LabLocatorService: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().body("Error fetching lab providers.");
        }

        if (labs == null || labs.isEmpty()) {
            logger.warn("!!! LabLocatorService returned NULL or EMPTY list for State: {}, District: {}.", state, district);
            return ResponseEntity.ok(List.of()); // Return empty list, client handles this
        }

        logger.info(">>> Total labs found by LabLocatorService: {}", labs.size());
        if(!labs.isEmpty()){
            // Assuming LabResult has a meaningful toString() due to @Data
            logger.info("Sample Lab Data from OSM/Overpass: {}", labs.get(0).toString());
        }
        logger.info("======================================================================");
        logger.info("=== Lab Providers Request End (Using OSM/Overpass) ===");
        logger.info("Returning {} labs.", labs.size());
        logger.info("======================================================================");

        return ResponseEntity.ok(labs);
    }

    // ... Booking endpoints remain the same ...
    @PostMapping("/book")
    public ResponseEntity<?> bookTest(Authentication auth, @RequestBody Booking bookingRequest) {
        String email = auth.getName();
        logger.info("Booking request for test '{}' at '{}' by user '{}'", bookingRequest.getSelectedTest(), bookingRequest.getProviderName(), email);
        bookingRequest.setPatientEmail(email);
        bookingRequest.setBookingDate(LocalDateTime.now());
        bookingRepo.save(bookingRequest);

        Random random = new Random();
        // Generate a price between, say, 200 and 1500
        double dummyPrice = 200 + (1500 - 200) * random.nextDouble();
        try {
            emailService.sendEmail(email, "Cure Buddy Booking Confirmation", "Dear Patient,\n\nYour test " + bookingRequest.getSelectedTest() + " with " + bookingRequest.getProviderName() + " has been successfully booked.\n\nStay Healthy!");
        } catch (Exception e) {
            logger.error("Failed to send booking confirmation email to {}: {}", email, e.getMessage());
        }
        String patientPhone = "+917339202176"; // Placeholder - Consider fetching actual user phone
        if (patientPhone != null && !patientPhone.trim().isEmpty()) {
            try {
                twilioService.sendSms(patientPhone, "Booking Confirmed: " + bookingRequest.getSelectedTest() + " with " + bookingRequest.getProviderName() + " - Cure Buddy");
            } catch (Exception e) {
                logger.error("Failed to send booking confirmation SMS to {}: {}", patientPhone, e.getMessage());
            }
        } else {
            logger.warn("Patient phone number not available for user {}. SMS not sent.", email);
        }
        bookingRequest.setPrice(dummyPrice);
        bookingRepo.save(bookingRequest);
        return ResponseEntity.ok("Booking successful! Confirmation sent via Email/SMS.");
    }

    @GetMapping("/my-bookings")
    public ResponseEntity<?> getMyBookings(Authentication auth) {
        String email = auth.getName();
        logger.info("Fetching bookings for user: {}", email);
        List<Booking> bookings = bookingRepo.findByPatientEmail(email);
        logger.info("Found {} bookings for user: {}", bookings.size(), email);
        return ResponseEntity.ok(bookings);
    }
}