package com.example.curebuddy_backend.model;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.LocalDateTime;

@Data
@Document(collection = "bookings")
public class Booking {

    @Id
    private String id;

    private String patientEmail;
    private String providerName;
    private String selectedTest;
    private double price;
    private LocalDateTime bookingDate;
}