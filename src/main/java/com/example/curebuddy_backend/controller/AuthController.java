package com.example.curebuddy_backend.controller;

import com.example.curebuddy_backend.auth.*;
import com.example.curebuddy_backend.model.User;
import com.example.curebuddy_backend.repository.UserRepository;
import com.example.curebuddy_backend.service.JwtService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.authentication.*;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    UserRepository repo;

    @Autowired
    AuthenticationManager authManager;

    @Autowired
    JwtService jwtService;

    BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    @PostMapping("/register")
    public ResponseEntity<String> register(@RequestBody RegisterRequest request) {
        if (repo.existsByEmail(request.email)) {
            return ResponseEntity.badRequest().body("Email already exists!");
        }

        User user = new User();
        user.setEmail(request.email);
        user.setName(request.name);
        user.setPassword(passwordEncoder.encode(request.password));
        user.setRole(request.role.toUpperCase());

        // Validate doctor registration number
        if (request.role.equalsIgnoreCase("DOCTOR")) {
            if (request.registrationNumber == null || !request.registrationNumber.matches("\\d{12}")) {
                return ResponseEntity.badRequest().body("Invalid registration number. Must be 12 digits.");
            }

            user.setRegistrationNumber(request.registrationNumber);
            user.setLicenseVerified(false); // Pending admin verification
        }

        repo.save(user);
        return ResponseEntity.ok("User registered successfully!");
    }


    @PostMapping("/login")
    public AuthResponse login(@RequestBody LoginRequest req) {
        Authentication authentication = authManager.authenticate(
                new UsernamePasswordAuthenticationToken(req.email, req.password)
        );

        User user = repo.findByEmail(req.email).orElseThrow(() -> new RuntimeException("User not found"));

        // Block unverified doctor login
        if (user.getRole().equalsIgnoreCase("DOCTOR") && !user.isLicenseVerified()) {
            // Returning an AuthResponse with a failure message (instead of ResponseEntity)
            return new AuthResponse("Doctor registration not verified. Please contact support.");
        }

        // Generate JWT token
        String token = jwtService.generateToken(user.getEmail(), user.getRole());
        return new AuthResponse(token);  // return token in AuthResponse
    }



    @PutMapping("/admin/verify-doctor/{email}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> verifyDoctor(@PathVariable String email) {
        Optional<User> doctor = repo.findByEmail(email);
        if (doctor.isEmpty() || !doctor.get().getRole().equalsIgnoreCase("DOCTOR")) {
            return ResponseEntity.badRequest().body("Doctor not found.");
        }

        User user = doctor.get();
        user.setLicenseVerified(true); // Set to true once verified by admin
        repo.save(user);

        return ResponseEntity.ok("Doctor verified successfully.");
    }



}
