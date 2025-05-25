// auth/AuthResponse.java
package com.example.curebuddy_backend.auth;

import lombok.Getter;
import lombok.Setter;

public class AuthResponse {
    public String token;

    // Getter and Setter
    @Setter
    @Getter
    private String message;

    public AuthResponse(String token) {
        this.token = token;
    }
}
