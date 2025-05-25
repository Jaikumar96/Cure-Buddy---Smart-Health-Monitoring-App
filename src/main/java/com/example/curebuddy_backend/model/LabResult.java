package com.example.curebuddy_backend.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LabResult {
    private String id;          // OSM element ID (e.g., "node/12345")
    private String name;
    private String address;
    private double lat;
    private double lon;
    private String phone;       // Optional: from OSM tags
    private String website;     // Optional: from OSM tags
    private String queryState;  // The state used in the query for context
    private String queryDistrict; // The district used in the query for context
    private String type;        // Type of facility (e.g., "laboratory", "hospital" from OSM tags)
}