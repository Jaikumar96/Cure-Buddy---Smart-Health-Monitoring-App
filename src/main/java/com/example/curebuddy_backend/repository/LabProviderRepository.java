package com.example.curebuddy_backend.repository;

import com.example.curebuddy_backend.model.LabProvider;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface LabProviderRepository extends MongoRepository<LabProvider, String> {
    List<LabProvider> findByCityIgnoreCase(String city); // Not directly used by the getLabProviders endpoint that uses NationalHealthApiClient
}