package com.example.curebuddy_backend.model;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Data
@Document(collection = "health_summaries")
public class HealthSummary {
    @Id
    private String id;
    private String userEmail;
    private String fileName;
    private String downloadLink;
    private LocalDateTime generatedAt;
}
