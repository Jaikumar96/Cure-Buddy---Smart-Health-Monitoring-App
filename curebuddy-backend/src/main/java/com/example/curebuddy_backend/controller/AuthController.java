package com.example.curebuddy_backend.controller;

import com.example.curebuddy_backend.auth.*;
import com.example.curebuddy_backend.model.User;
import com.example.curebuddy_backend.repository.UserRepository;
import com.example.curebuddy_backend.service.JwtService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.*;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

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
    public String register(@RequestBody RegisterRequest req) {
        if (repo.existsByEmail(req.email)) return "Email already exists!";

        User user = new User();
        user.setEmail(req.email);
        user.setName(req.name);
        user.setPassword(passwordEncoder.encode(req.password));
        user.setRole(req.role.toUpperCase());

        repo.save(user);
        return "User registered successfully!";
    }

    @PostMapping("/login")
    public AuthResponse login(@RequestBody LoginRequest req) {
        authManager.authenticate(
                new UsernamePasswordAuthenticationToken(req.email, req.password)
        );

        String token = jwtService.generateToken(req.email);
        return new AuthResponse(token);
    }
}
