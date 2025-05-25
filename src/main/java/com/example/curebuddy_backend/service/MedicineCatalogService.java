package com.example.curebuddy_backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class MedicineCatalogService {

    private static final Logger logger = LoggerFactory.getLogger(MedicineCatalogService.class);
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${openfda.api.url}")
    private String openFdaApiUrl;

    // Your original dummy data, can be used as a fallback or if API fails
    private final List<Map<String, Object>> dummyMedicines = List.of(
            Map.of("name", "Paracetamol (Dummy)", "brand", "Calpol (Dummy)", "price", 30, "strength", "500mg", "discount", "10% off", "source", "Dummy Data"),
            Map.of("name", "Azithromycin (Dummy)", "brand", "Azithral (Dummy)", "price", 80, "strength", "500mg", "discount", "5% off", "source", "Dummy Data")
    );

    public MedicineCatalogService(RestTemplate restTemplate, ObjectMapper objectMapper) {
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
    }

    public List<Map<String, Object>> searchByName(String medicineName) {
        List<Map<String, Object>> medicines = new ArrayList<>();
        try {
            // OpenFDA API search query. We can search by generic_name or brand_name.
            // Example: search for "ibuprofen" in generic name OR brand name.
            String query = String.format("openfda.generic_name:\"%s\"+OR+openfda.brand_name:\"%s\"",
                    medicineName.toLowerCase(), medicineName.toLowerCase());

            UriComponentsBuilder builder = UriComponentsBuilder.fromHttpUrl(openFdaApiUrl)
                    .queryParam("search", URLEncoder.encode(query, StandardCharsets.UTF_8.toString()))
                    .queryParam("limit", 10); // Get up to 10 results

            logger.info("OpenFDA Request URL: {}", builder.toUriString());
            String responseString = restTemplate.getForObject(builder.toUriString(), String.class);
            JsonNode rootNode = objectMapper.readTree(responseString);

            if (rootNode.has("results")) {
                for (JsonNode result : rootNode.get("results")) {
                    Map<String, Object> med = new HashMap<>();

                    // Extract generic name (active ingredient)
                    if (result.has("openfda") && result.get("openfda").has("generic_name") && result.get("openfda").get("generic_name").isArray() && !result.get("openfda").get("generic_name").isEmpty()) {
                        med.put("name", result.get("openfda").get("generic_name").get(0).asText());
                    } else {
                        // If generic_name is not found directly, try to use the original search term or another field
                        med.put("name", medicineName); // Fallback
                    }

                    // Extract brand name
                    if (result.has("openfda") && result.get("openfda").has("brand_name") && result.get("openfda").get("brand_name").isArray() && !result.get("openfda").get("brand_name").isEmpty()) {
                        med.put("brand", result.get("openfda").get("brand_name").get(0).asText());
                    } else {
                        med.put("brand", "N/A (US API)");
                    }

                    // Extract strength (can be complex, often in active_ingredients part)
                    // This is a simplified extraction. Real data can be more varied.
                    if (result.has("active_ingredient") && result.get("active_ingredient").isArray() && !result.get("active_ingredient").isEmpty()) {
                        JsonNode firstIngredient = result.get("active_ingredient").get(0);
                        med.put("strength", firstIngredient.has("strength") ? firstIngredient.get("strength").asText("N/A") : "N/A");
                    } else {
                        med.put("strength", "N/A");
                    }

                    // Price and discount are NOT available from OpenFDA
                    med.put("price", "N/A (Info API)"); // Indicate data source
                    med.put("discount", "Check with local pharmacy");
                    med.put("source", "OpenFDA (US Drug Info)");

                    medicines.add(med);
                }
            }

            if (medicines.isEmpty()) {
                logger.warn("No results from OpenFDA for: {}. You might want to return a specific message or dummy data.", medicineName);
                // Optionally, add some dummy data if API returns nothing, so the user sees something
                // medicines.addAll(getDummyMedicinesByName(medicineName));
            }

        } catch (Exception e) {
            logger.error("Error fetching medicines from OpenFDA for '{}': {}", medicineName, e.getMessage(), e);
            // Fallback to your original dummy data if API call fails
            logger.info("Falling back to dummy data for medicine search: {}", medicineName);
            medicines.addAll(getDummyMedicinesByName(medicineName)); // Use a helper to filter dummy data
        }
        return medicines;
    }

    // Helper method to filter your original dummy data
    private List<Map<String, Object>> getDummyMedicinesByName(String medicineName) {
        List<Map<String, Object>> filteredDummy = new ArrayList<>();
        for (Map<String, Object> dummyMed : this.dummyMedicines) {
            if (dummyMed.get("name") instanceof String &&
                    ((String) dummyMed.get("name")).toLowerCase().contains(medicineName.toLowerCase())) {
                filteredDummy.add(dummyMed);
            }
        }
        return filteredDummy;
    }
}