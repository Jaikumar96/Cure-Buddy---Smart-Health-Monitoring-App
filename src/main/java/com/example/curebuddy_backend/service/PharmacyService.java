package com.example.curebuddy_backend.service;

import com.example.curebuddy_backend.model.Pharmacy;
import com.example.curebuddy_backend.model.nominatim.NominatimResult;
import com.example.curebuddy_backend.model.overpass.OverpassElement;
import com.example.curebuddy_backend.model.overpass.OverpassResponse;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.Arrays;

@Service
public class PharmacyService {

    private static final Logger logger = LoggerFactory.getLogger(PharmacyService.class);
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper; // For more flexible JSON parsing
    private static final String OVERPASS_API_URL = "https://overpass-api.de/api/interpreter";
    private static final String NOMINATIM_API_URL = "https://nominatim.openstreetmap.org/search";

    public PharmacyService(RestTemplate restTemplate, ObjectMapper objectMapper) {
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper; // Inject ObjectMapper
    }

    public List<Pharmacy> findByCity(String city) {
        if (city == null || city.trim().isEmpty()) {
            logger.warn("City name is empty or null.");
            return Collections.emptyList();
        }
        logger.info("Attempting to find pharmacies in city: {}", city);

        // 1. Geocode city to get latitude and longitude using Nominatim
        List<NominatimResult> geoResultsList = geocodeCity(city);
        if (geoResultsList == null || geoResultsList.isEmpty()) {
            logger.warn("Could not geocode city: {}. No coordinates found.", city);
            return Collections.emptyList();
        }

        // Use the first result (most relevant)
        NominatimResult firstGeoResult = geoResultsList.get(0);
        double lat;
        double lon;
        try {
            lat = Double.parseDouble(firstGeoResult.getLat());
            lon = Double.parseDouble(firstGeoResult.getLon());
        } catch (NumberFormatException e) {
            logger.error("Could not parse lat/lon from Nominatim result for {}: lat='{}', lon='{}'",
                    city, firstGeoResult.getLat(), firstGeoResult.getLon(), e);
            return Collections.emptyList();
        }

        logger.info("Geocoded {} to lat: {}, lon: {}", city, lat, lon);

        // 2. Query Overpass API for pharmacies around these coordinates
        int searchRadius = 10000; // 10km radius

        String overpassQuery = String.format(
                "[out:json][timeout:25];" +
                        "(" +
                        "  node[amenity=pharmacy](around:%d,%.6f,%.6f);" +
                        "  way[amenity=pharmacy](around:%d,%.6f,%.6f);" +
                        "  relation[amenity=pharmacy](around:%d,%.6f,%.6f);" +
                        ");" +
                        "out center;",
                searchRadius, lat, lon,
                searchRadius, lat, lon,
                searchRadius, lat, lon
        );

        // Inside findByCity method in PharmacyService.java

// ... (after geocoding and getting lat, lon)


        // Option 1: Build and encode the full URI (more robust)
        UriComponentsBuilder uriBuilder = UriComponentsBuilder.fromHttpUrl(OVERPASS_API_URL)
                .queryParam("data", "{overpassQueryData}"); // Use a placeholder

        // The RestTemplate will URI-encode the 'overpassQuery' when substituting it into the placeholder.
        // This is generally the correct way if the API expects standard URL encoding for query param values.
        String fullUrl = uriBuilder.buildAndExpand(Map.of("overpassQueryData", overpassQuery)).toUriString();
        // URI fullUri = uriBuilder.buildAndExpand(Map.of("overpassQueryData", overpassQuery)).toUri(); // Alternative

        logger.info("Querying Overpass API with pre-built URL: {}", fullUrl);

        try {
            HttpHeaders overpassHeaders = new HttpHeaders();
            overpassHeaders.set("User-Agent", "CureBuddyApp/1.0 (BackendPharmacyLookup; https://github.com/Jaikumar96/Cure-Buddy---Smart-Health-Monitoring-App)");
            // Overpass generally doesn't need Accept for JSON with [out:json] but doesn't hurt
            overpassHeaders.setAccept(List.of(MediaType.APPLICATION_JSON));
            HttpEntity<String> overpassEntity = new HttpEntity<>(overpassHeaders);

            // Use the String URL directly
            ResponseEntity<OverpassResponse> response = restTemplate.exchange(
                    fullUrl, // Use the fully constructed and encoded URL string
                    HttpMethod.GET,
                    overpassEntity,
                    OverpassResponse.class
            );
            // ... rest of the try-catch block

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                List<Pharmacy> pharmacies = response.getBody().getElements().stream()
                        .map(element -> convertToPharmacy(element, city))
                        .filter(pharmacy -> pharmacy.getName() != null && !pharmacy.getName().equalsIgnoreCase("Unknown Pharmacy"))
                        .collect(Collectors.toList());
                logger.info("Found {} pharmacies in {}", pharmacies.size(), city);
                return pharmacies;
            } else {
                logger.error("Error from Overpass API: {} - Body: {}", response.getStatusCode(), response.getBody() != null ? response.getBody().toString() : "null");
                return Collections.emptyList();
            }
        } catch (Exception e) {
            logger.error("Exception while calling Overpass API: ", e);
            return Collections.emptyList();
        }
    }

    private List<NominatimResult> geocodeCity(String city) {
        HttpHeaders headers = new HttpHeaders();
        headers.set("User-Agent", "CureBuddyApp/1.0 (BackendGeocoding; https://github.com/Jaikumar96/Cure-Buddy---Smart-Health-Monitoring-App)");
        headers.setAccept(List.of(MediaType.APPLICATION_JSON)); // Use List.of
        HttpEntity<String> entity = new HttpEntity<>(headers);

        // Try a more specific query for Nominatim
        UriComponentsBuilder builder = UriComponentsBuilder.fromHttpUrl(NOMINATIM_API_URL)
                .queryParam("city", city) // Using 'city' parameter instead of 'q' sometimes helps
                .queryParam("country", "India") // Be more specific
                .queryParam("format", "json")
                .queryParam("limit", 5); // Get a few results to see what Nominatim thinks

        logger.info("Querying Nominatim API with URL: {}", builder.toUriString());

        try {
            ResponseEntity<String> responseEntity = restTemplate.exchange(
                    builder.toUriString(),
                    HttpMethod.GET,
                    entity,
                    String.class // Get raw string response first
            );

            String responseBody = responseEntity.getBody();
            logger.info("Nominatim raw response string for {}: {}", city, responseBody);

            if (responseEntity.getStatusCode().is2xxSuccessful() && responseBody != null && !responseBody.trim().isEmpty() && !responseBody.trim().equals("[]")) {
                // Manually parse using ObjectMapper for more control
                List<NominatimResult> results = objectMapper.readValue(responseBody, new TypeReference<List<NominatimResult>>() {});
                if (results.isEmpty()) {
                    logger.warn("Nominatim returned 200 OK but an empty JSON array for city: {}", city);
                    return Collections.emptyList();
                }
                logger.info("Nominatim successfully geocoded {}. Found {} results. First result: {}", city, results.size(), results.get(0).getDisplay_name());
                return results;
            } else {
                logger.error("Error from Nominatim API or empty/unexpected response: Status {}, Body: {}", responseEntity.getStatusCode(), responseBody);
                return Collections.emptyList();
            }
        } catch (HttpClientErrorException e) {
            logger.error("HttpClientErrorException while calling Nominatim API for city {}: Status {}, Body: {}", city, e.getStatusCode(), e.getResponseBodyAsString(), e);
            return Collections.emptyList();
        }
        catch (Exception e) {
            logger.error("Generic Exception while calling Nominatim API for city {}: ", city, e);
            return Collections.emptyList();
        }
    }


    private Pharmacy convertToPharmacy(OverpassElement element, String queryCity) {
        Map<String, String> tags = element.getTags();
        if (tags == null) {
            logger.warn("Overpass element {} has null tags.", element.getId());
            return new Pharmacy(null, queryCity, null, null, 0,0, queryCity, String.valueOf(element.getId())); // Include ID
        }

        String name = tags.getOrDefault("name", "Unknown Pharmacy");
        // If name is still "Unknown Pharmacy", try "official_name" or skip if too generic
        if (name.equalsIgnoreCase("Unknown Pharmacy")) {
            name = tags.getOrDefault("official_name", "Unknown Pharmacy");
        }
        // Optional: skip if name is still "Unknown Pharmacy" after trying alternatives
        // if (name.equalsIgnoreCase("Unknown Pharmacy")) {
        //     return new Pharmacy(null, queryCity, null, null, 0,0, queryCity, String.valueOf(element.getId()));
        // }


        String street = tags.getOrDefault("addr:street", "");
        String housenumber = tags.getOrDefault("addr:housenumber", "");
        String postcode = tags.getOrDefault("addr:postcode", "");
        String cityTag = tags.getOrDefault("addr:city", queryCity);
        String districtTag = tags.getOrDefault("addr:district", "");
        String subUrbTag = tags.getOrDefault("addr:suburb", "");


        StringBuilder addressBuilder = new StringBuilder();
        if (!housenumber.isEmpty()) addressBuilder.append(housenumber).append(" ");
        if (!street.isEmpty()) addressBuilder.append(street);

        if (!subUrbTag.isEmpty()) {
            if (addressBuilder.length() > 0) addressBuilder.append(", ");
            addressBuilder.append(subUrbTag);
        }
        if (!districtTag.isEmpty()) {
            if (addressBuilder.length() > 0) addressBuilder.append(", ");
            addressBuilder.append(districtTag);
        }

        if (addressBuilder.length() > 0) addressBuilder.append(", ");
        addressBuilder.append(cityTag); // Use resolved city

        if (!postcode.isEmpty()) addressBuilder.append(" - ").append(postcode);

        String address = addressBuilder.toString().trim();
        if (address.endsWith(",")) {
            address = address.substring(0, address.length() -1).trim();
        }


        double lat = element.getLat();
        double lon = element.getLon();

        // If element is a way/relation, Overpass `out center;` should provide center lat/lon.
        // If lat/lon are 0.0 and a 'center' object exists, use that (though modern Overpass should handle this).
        if ((lat == 0.0 || lon == 0.0) && element.getCenter() != null) {
            lat = element.getCenter().getLat();
            lon = element.getCenter().getLon();
            logger.debug("Using center coordinates for element {} (type {})", element.getId(), element.getType());
        }


        return new Pharmacy(
                name,
                address.isEmpty() ? cityTag : address,
                tags.get("phone"),
                tags.get("website"),
                lat,
                lon,
                cityTag,
                String.valueOf(element.getId()) // Add ID
        );
    }
}