package com.example.curebuddy_backend.controller; // Ensure this package matches your project structure

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;
// import org.springframework.web.util.UriComponentsBuilder; // Not needed for POST with fixed URL

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Component
public class GooglePlacesApiClient {

    private static final Logger logger = LoggerFactory.getLogger(GooglePlacesApiClient.class);
    // Use the new Places API (v1) endpoint for Text Search
    private static final String PLACES_API_V1_TEXT_SEARCH_URL = "https://places.googleapis.com/v1/places:searchText";

    @Value("${google.places.api.key}")
    private String apiKey;

    private final RestTemplate restTemplate;

    public GooglePlacesApiClient() {
        this.restTemplate = new RestTemplate();
    }

    public List<Map<String, Object>> findLabsNearby(String state, String district) {
        String searchText = "diagnostic labs in " + (district != null && !district.isEmpty() ? district + ", " : "") + state;
        logger.info("Preparing to query Google Places API (New) with searchText: \"{}\"", searchText);

        if (apiKey == null || apiKey.trim().isEmpty()) {
            logger.error("Google Places API Key is missing or empty. Please check application properties.");
            return Collections.emptyList();
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("X-Goog-Api-Key", apiKey);
        // FieldMask specifies which fields to return. Crucial for Places API (New)
        headers.set("X-Goog-FieldMask", "places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.types,places.businessStatus,places.primaryTypeDisplayName");

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("textQuery", searchText);
        // You can add more parameters like language, region, locationBias, etc. if needed
        // requestBody.put("languageCode", "en");
        // requestBody.put("maxResultCount", 10); // Default is 20 for new API
        // requestBody.put("includedType", "diagnostic_laboratory"); // Be very specific if Google supports it well for your region
        // requestBody.put("includedType", "hospital"); // Or broader

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        logger.info("Querying Google Places API (New): URL: {}, Body: {}", PLACES_API_V1_TEXT_SEARCH_URL, requestBody);

        try {
            ResponseEntity<Map> responseEntity = restTemplate.exchange(
                    PLACES_API_V1_TEXT_SEARCH_URL,
                    HttpMethod.POST,
                    entity,
                    Map.class);

            if (!responseEntity.getStatusCode().is2xxSuccessful() || responseEntity.getBody() == null) {
                logger.error("Google Places API (New) request failed. Status Code: {}, Body: {}", responseEntity.getStatusCode(), responseEntity.getBody());
                return Collections.emptyList();
            }

            Map<String, Object> responseBody = responseEntity.getBody();
            // The new API nests results under a "places" key
            List<Map<String, Object>> places = (List<Map<String, Object>>) responseBody.get("places");

            if (places == null || places.isEmpty()) {
                logger.info("Google Places API (New) returned no 'places' for searchText: \"{}\". Full response: {}", searchText, responseBody);
                return Collections.emptyList();
            }

            logger.info("Google Places API (New) returned {} places for searchText: \"{}\"", places.size(), searchText);

            return places.stream()
                    .map(place -> {
                        Map<String, Object> labData = new HashMap<>();
                        // Adapt to the new response structure
                        labData.put("id", place.get("id")); // Usually "places/ChIJ..." format
                        // The new API uses "displayName" which is an object with "text" and "languageCode"
                        Map<String, String> displayNameMap = (Map<String, String>) place.get("displayName");
                        if (displayNameMap != null && displayNameMap.containsKey("text")) {
                            labData.put("name", displayNameMap.get("text"));
                        } else {
                            labData.put("name", "Unknown Lab Name");
                        }
                        labData.put("address", place.get("formattedAddress"));

                        Map<String, Object> location = (Map<String, Object>) place.get("location");
                        if (location != null) {
                            labData.put("lat", location.get("latitude"));  // Note: it's "latitude", not "lat"
                            labData.put("lon", location.get("longitude")); // Note: it's "longitude", not "lng"
                        }

                        labData.put("phone", "N/A"); // Requires Place Details with field mask "places.nationalPhoneNumber"
                        labData.put("rating", place.get("rating")); // double
                        labData.put("user_ratings_total", place.get("userRatingCount")); // integer, note camelCase
                        labData.put("api_source", "GooglePlacesV1");
                        labData.put("google_place_types", place.get("types")); // Array of strings like "hospital", "health", "laboratory"
                        labData.put("business_status", place.get("businessStatus")); // e.g., "OPERATIONAL"

                        Map<String, String> primaryTypeDisplayNameMap = (Map<String, String>) place.get("primaryTypeDisplayName");
                        if (primaryTypeDisplayNameMap != null && primaryTypeDisplayNameMap.containsKey("text")) {
                            labData.put("primary_type", primaryTypeDisplayNameMap.get("text"));
                        }


                        // Further filter if needed based on types.
                        // The "types" array in Places API (New) might be more reliable for filtering.
                        List<String> types = (List<String>) place.getOrDefault("types", Collections.emptyList());
                        boolean isRelevantType = types.stream().anyMatch(type ->
                                type.equalsIgnoreCase("laboratory") ||
                                        type.equalsIgnoreCase("diagnostic_laboratory") || // More specific
                                        type.equalsIgnoreCase("medical_laboratory") ||
                                        type.equalsIgnoreCase("hospital") || // Hospitals often have labs
                                        type.equalsIgnoreCase("health") // Generic health category
                        );

                        if (!isRelevantType) {
                            logger.info("Place '{}' (Types: {}) filtered out because it's not a relevant lab type.", labData.get("name"), types);
                            // return null; // Uncomment to strictly filter
                        }


                        if (labData.containsKey("lat") && labData.containsKey("lon")) {
                            return labData;
                        }
                        logger.warn("Place '{}' from Google Places API (New) missing lat/lon. Location data: {}", labData.get("name"), location);
                        return null;
                    })
                    .filter(java.util.Objects::nonNull)
                    .collect(Collectors.toList());

        } catch (HttpClientErrorException e) {
            logger.error("HttpClientErrorException calling Google Places API (New): {} - Response: {}", e.getStatusCode(), e.getResponseBodyAsString(), e);
            return Collections.emptyList();
        } catch (Exception e) {
            logger.error("Generic Exception calling Google Places API (New): {}", e.getMessage(), e);
            return Collections.emptyList();
        }
    }
}