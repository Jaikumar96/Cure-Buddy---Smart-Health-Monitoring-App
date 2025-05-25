package com.example.curebuddy_backend.service;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys; // Import Keys
import jakarta.annotation.PostConstruct; // For Spring Boot 3.x, or javax.annotation.PostConstruct for older
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets; // Not strictly needed for Base64 decoded key, but good to be aware of
import java.security.Key; // Import Key
import java.util.Base64; // Import Base64
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Service
public class JwtService {

    @Value("${jwt.secret}")
    private String base64Secret; // Store the Base64 encoded string

    private Key signingKey; // Use java.security.Key

    @PostConstruct // This method will be called after the bean is initialized
    public void init() {
        byte[] keyBytes = Base64.getDecoder().decode(base64Secret);
        this.signingKey = Keys.hmacShaKeyFor(keyBytes);
    }

    public String generateToken(String email, String role) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("role", role);

        return Jwts.builder()
                .setClaims(claims)
                .setSubject(email)
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + 1000 * 60 * 60 * 10)) // 10 hours
                .signWith(signingKey, SignatureAlgorithm.HS256) // Use the Key object
                .compact();
    }

    private Claims extractAllClaims(String token) {
        return Jwts.parserBuilder() // Use parserBuilder for modern jjwt
                .setSigningKey(signingKey) // Use the Key object
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    public String extractEmail(String token) {
        return extractAllClaims(token).getSubject();
    }

    public String extractRole(String token) {
        return (String) extractAllClaims(token).get("role");
    }

    public boolean validateToken(String token) {
        try {
            Jwts.parserBuilder().setSigningKey(signingKey).build().parseClaimsJws(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            // Log the exception e.g., log.warn("Invalid JWT token: {}", e.getMessage());
            return false;
        }
    }
}