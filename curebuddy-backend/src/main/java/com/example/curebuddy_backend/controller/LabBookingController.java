package com.example.curebuddy_backend.controller;

import com.example.curebuddy_backend.client.NationalHealthApiClient;
import com.example.curebuddy_backend.model.Booking;
import com.example.curebuddy_backend.model.LabProvider;
import com.example.curebuddy_backend.repository.BookingRepository;
import com.example.curebuddy_backend.repository.LabProviderRepository;
import com.example.curebuddy_backend.service.EmailService;
import com.example.curebuddy_backend.service.TwilioService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/labs")
public class LabBookingController {

    @Autowired
    private LabProviderRepository labRepo;

    @Autowired
    private BookingRepository bookingRepo;

    @Autowired
    private EmailService emailService;

    @Autowired
    private TwilioService twilioService;

    @Autowired
    private NationalHealthApiClient healthApiClient;
    
    @GetMapping("/providers")
    public ResponseEntity<?> getLabProviders(
            @RequestParam String state,
            @RequestParam(required = false) String district) {

        List<Map<String, Object>> providers = healthApiClient.fetchHospitals(); // No city passed

        List<Map<String, Object>> filteredProviders = providers.stream()
                .filter(provider -> {
                    String providerState = (String) provider.get("state");
                    String providerDistrict = (String) provider.get("district");
                    String careType = (String) provider.get("_hospital_care_type");

                    boolean stateMatches = providerState != null && providerState.equalsIgnoreCase(state);
                    boolean districtMatches = (district == null || (providerDistrict != null && providerDistrict.equalsIgnoreCase(district)));
                    boolean isLab = careType != null && (careType.contains("Hospital") || careType.contains("Diagnostic"));

                    return stateMatches && districtMatches && isLab;
                })
                .map(provider -> Map.of(
                        "name", provider.get("hospital_name"),
                        "address", provider.get("_address_original_first_line"),
                        "phone", provider.get("telephone"),
                        "ownership", provider.get("hospital_category"),  // You can map ownership better if needed
                        "state", provider.get("state"),
                        "district", provider.get("district"),
                        "specialties", provider.get("specialties")
                ))
                .toList();

        return ResponseEntity.ok(filteredProviders);
    }





    @PostMapping("/book")
    public ResponseEntity<?> bookTest(
            Authentication auth,
            @RequestBody Booking bookingRequest) {

        String email = auth.getName();
        bookingRequest.setPatientEmail(email);
        bookingRequest.setBookingDate(LocalDateTime.now());
        bookingRepo.save(bookingRequest);

        // Send confirmation email and SMS
        emailService.sendEmail(
                email,
                "Cure Buddy Booking Confirmation",
                "Dear Patient,\n\nYour test " + bookingRequest.getSelectedTest() +
                        " with " + bookingRequest.getProviderName() +
                        " has been successfully booked.\n\nStay Healthy!"
        );

        String patientPhone = "+917339202176";  // (store/fetch real phone number later)

        twilioService.sendSms(
                patientPhone,
                "Booking Confirmed: " + bookingRequest.getSelectedTest() +
                        " with " + bookingRequest.getProviderName() +
                        " - Cure Buddy"
        );

        return ResponseEntity.ok("Booking successful! Confirmation sent via Email/SMS.");
    }

    @GetMapping("/my-bookings")
    public ResponseEntity<?> getMyBookings(Authentication auth) {
        String email = auth.getName();
        List<Booking> bookings = bookingRepo.findByPatientEmail(email);
        return ResponseEntity.ok(bookings);
    }
}
