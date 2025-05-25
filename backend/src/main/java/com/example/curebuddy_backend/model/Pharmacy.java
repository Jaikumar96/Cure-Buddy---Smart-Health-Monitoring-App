package com.example.curebuddy_backend.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Pharmacy {
    private String name;
    private String address;
    private String phone;
    private String website;
    private double lat;
    private double lon;
    private String city;
    private String id; // Add this field
}