package com.example.curebuddy_backend.model;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.util.List;

@Data
@Document(collection = "lab_providers")
public class LabProvider {

    @Id
    private String id;

    private String name;
    private String city;
    private double rating;
    private String priceRange;  // e.g., "500-1500 INR"
    private List<String> availableTests;
}
