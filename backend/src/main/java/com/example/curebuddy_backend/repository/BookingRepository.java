package com.example.curebuddy_backend.repository;

import com.example.curebuddy_backend.model.Booking;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface BookingRepository extends MongoRepository<Booking, String> {
    List<Booking> findByPatientEmail(String email);
}
