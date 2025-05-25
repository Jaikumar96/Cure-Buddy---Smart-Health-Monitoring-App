package com.example.curebuddy_backend.service;

import com.example.curebuddy_backend.model.LabResult;
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

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class LabLocatorService {

    private static final Logger logger = LoggerFactory.getLogger(LabLocatorService.class);
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    private static final String OVERPASS_API_URL = "https://overpass-api.de/api/interpreter";
    private static final String NOMINATIM_API_URL = "https://nominatim.openstreetmap.org/search";

    // IMPORTANT: Use a descriptive User-Agent with valid contact info for your project
    private static final String APP_USER_AGENT = "CureBuddyApp/1.0 (LabLookup; https://github.com/Jaikumar96/Cure-Buddy---Smart-Health-Monitoring-App)";


    public LabLocatorService(RestTemplate restTemplate, ObjectMapper objectMapper) {
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
    }

    public List<LabResult> findLabsByLocation(String state, String district) {
        // For Nominatim, we'll try to geocode the district first, then fall back to state if district is not provided or fails.
        String locationToGeocode = district != null && !district.isEmpty() ? district : state;
        String country = "India"; // Assuming labs are in India

        logger.info("Attempting to find labs. Geocoding location: '{}', State: '{}', Country: '{}'", locationToGeocode, state, country);

        List<NominatimResult> geoResultsList = geocodeOsmLocation(locationToGeocode, state, country);

        if (geoResultsList == null || geoResultsList.isEmpty()) {
            logger.warn("Could not geocode location: '{}', State: '{}'. No coordinates found.", locationToGeocode, state);
            return Collections.emptyList();
        }

        NominatimResult firstGeoResult = geoResultsList.get(0); // Take the first, most relevant result
        double lat;
        double lon;
        try {
            lat = Double.parseDouble(firstGeoResult.getLat());
            lon = Double.parseDouble(firstGeoResult.getLon());
        } catch (NumberFormatException e) {
            logger.error("Could not parse lat/lon from Nominatim result for {}: lat='{}', lon='{}'",
                    firstGeoResult.getDisplay_name(), firstGeoResult.getLat(), firstGeoResult.getLon(), e);
            return Collections.emptyList();
        }

        logger.info("Geocoded '{}' (from query for state '{}', district '{}') to lat: {}, lon: {}. DisplayName: {}",
                locationToGeocode, state, district, lat, lon, firstGeoResult.getDisplay_name());

        // Query Overpass API for labs around these coordinates
        int searchRadius = 15000; // 15km radius, adjust if needed

        String overpassQuery = String.format(
                "[out:json][timeout:30];" +
                        "(" +
                        "  node[amenity~\"^(hospital|clinic|doctors)$\"](around:%d,%.6f,%.6f);" +
                        "  way[amenity~\"^(hospital|clinic|doctors)$\"](around:%d,%.6f,%.6f);" +
                        "  relation[amenity~\"^(hospital|clinic|doctors)$\"](around:%d,%.6f,%.6f);" +
                        "  node[amenity=laboratory](around:%d,%.6f,%.6f);" +
                        "  way[amenity=laboratory](around:%d,%.6f,%.6f);" +
                        "  relation[amenity=laboratory](around:%d,%.6f,%.6f);" +
                        ");" +
                        "out center;",
                searchRadius, lat, lon, searchRadius, lat, lon, searchRadius, lat, lon,
                searchRadius, lat, lon, searchRadius, lat, lon, searchRadius, lat, lon
        );

        UriComponentsBuilder uriBuilder = UriComponentsBuilder.fromHttpUrl(OVERPASS_API_URL)
                .queryParam("data", "{overpassQueryData}"); // Placeholder for URI encoding
        String fullUrl = uriBuilder.buildAndExpand(Map.of("overpassQueryData", overpassQuery)).toUriString();

        logger.info("Querying Overpass API: {}", fullUrl);

        try {
            HttpHeaders overpassHeaders = new HttpHeaders();
            overpassHeaders.set("User-Agent", APP_USER_AGENT);
            overpassHeaders.setAccept(List.of(MediaType.APPLICATION_JSON));
            HttpEntity<String> overpassEntity = new HttpEntity<>(overpassHeaders);

            ResponseEntity<OverpassResponse> response = restTemplate.exchange(
                    fullUrl, HttpMethod.GET, overpassEntity, OverpassResponse.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                List<LabResult> labs = response.getBody().getElements().stream()
                        .map(element -> convertToLabResult(element, state, district))
                        .filter(java.util.Objects::nonNull)
                        .filter(lab -> lab.getName() != null && !lab.getName().equalsIgnoreCase("Unknown Lab") && lab.getLat() != 0.0 && lab.getLon() != 0.0)
                        .collect(Collectors.toList());
                logger.info("Found {} potential labs near {} (State: {}, District: {}) using Overpass.", labs.size(), locationToGeocode, state, district);
                return labs;
            } else {
                logger.error("Error from Overpass API: {} - Body: {}", response.getStatusCode(), response.getBody() != null ? response.getBody().toString() : "null");
                return Collections.emptyList();
            }
        } catch (Exception e) {
            logger.error("Exception while calling Overpass API: {}", e.getMessage(), e);
            return Collections.emptyList();
        }
    }

    private List<NominatimResult> geocodeOsmLocation(String placeName, String stateContext, String countryContext) {
        HttpHeaders headers = new HttpHeaders();
        headers.set("User-Agent", APP_USER_AGENT); // Consistent User-Agent
        headers.setAccept(List.of(MediaType.APPLICATION_JSON));
        HttpEntity<String> entity = new HttpEntity<>(headers);

        UriComponentsBuilder builder = UriComponentsBuilder.fromHttpUrl(NOMINATIM_API_URL);

        // **** MODIFICATION IS HERE ****
        // We use 'placeName' for the 'city' parameter, similar to how PharmacyService does.
        // The 'stateContext' parameter in the Nominatim query is commented out/removed
        // as it seems to be causing issues with Nominatim's lookup for "Chennai".
        if (placeName != null && !placeName.isEmpty()) {
            builder.queryParam("city", placeName); // Using 'city' like in PharmacyService
        }
        // builder.queryParam("state", stateContext); // <<-- THIS LINE IS COMMENTED OUT / REMOVED
        builder.queryParam("country", countryContext);
        builder.queryParam("format", "json");
        builder.queryParam("limit", 1); // Get the top result (PharmacyService uses 5, 1 is fine for specific geocoding)
        // **** END OF MODIFICATION ****


        String urlToCall = builder.toUriString();
        // Added stateContext to the log for better debugging if issues persist
        logger.info("Querying Nominatim API (Attempt for place: '{}', in context of state: '{}') with URL: {}", placeName, stateContext, urlToCall);

        try {
            ResponseEntity<String> responseEntity = restTemplate.exchange(
                    urlToCall, HttpMethod.GET, entity, String.class);

            String responseBody = responseEntity.getBody();
            logger.info("Nominatim raw response for \"{}\": {}", placeName, responseBody);

            if (responseEntity.getStatusCode().is2xxSuccessful() && responseBody != null && !responseBody.trim().isEmpty() && !responseBody.trim().equals("[]")) {
                List<NominatimResult> results = objectMapper.readValue(responseBody, new TypeReference<List<NominatimResult>>() {});
                if (results.isEmpty()) {
                    logger.warn("Nominatim returned 200 OK but an empty JSON array for: {}", placeName);
                    return Collections.emptyList();
                }
                logger.info("Nominatim successfully geocoded \"{}\". Found {} result(s). Top result display_name: {}", placeName, results.size(), results.get(0).getDisplay_name());
                return results;
            } else {
                logger.error("Error from Nominatim API or empty/unexpected response for \"{}\": Status {}, Body: {}", placeName, responseEntity.getStatusCode(), responseBody);
                return Collections.emptyList();
            }
        } catch (HttpClientErrorException e) {
            logger.error("HttpClientErrorException (Nominatim) for \"{}\": Status {}, Body: {}", placeName, e.getStatusCode(), e.getResponseBodyAsString(), e);
            return Collections.emptyList();
        } catch (Exception e) {
            logger.error("Generic Exception during Nominatim call for \"{}\": ", placeName, e);
            return Collections.emptyList();
        }
    }

    private LabResult convertToLabResult(OverpassElement element, String state, String district) {
        Map<String, String> tags = element.getTags();
        if (tags == null) {
            logger.trace("Overpass element {} has null tags, skipping.", element.getId());
            return null;
        }

        String name = tags.getOrDefault("name", tags.getOrDefault("official_name", "Unknown Lab"));
        String healthcareTag = tags.getOrDefault("healthcare", "").toLowerCase();
        String amenityTag = tags.getOrDefault("amenity", "").toLowerCase();
        String nameLower = name.toLowerCase();

        boolean isExplicitLab = healthcareTag.equals("laboratory") || healthcareTag.equals("diagnostic_laboratory") || amenityTag.equals("laboratory");
        boolean nameSuggestsLab = nameLower.contains("lab") || nameLower.contains("diagnostic") ||
                nameLower.contains("pathology") || nameLower.contains("scan") ||
                nameLower.contains("test") || nameLower.contains("imaging") || nameLower.contains("radiology");

        if (!isExplicitLab && !( (amenityTag.equals("hospital") || amenityTag.equals("clinic") || amenityTag.equals("doctors")) && nameSuggestsLab) ) {
            logger.trace("Element '{}' (amenity: '{}', healthcare: '{}') does not meet lab criteria, skipping.", name, amenityTag, healthcareTag);
            return null;
        }

        double lat = element.getLat();
        double lon = element.getLon();
        if ((lat == 0.0 || lon == 0.0) && element.getCenter() != null) {
            lat = element.getCenter().getLat();
            lon = element.getCenter().getLon();
        }
        if (lat == 0.0 || lon == 0.0) {
            logger.warn("Element '{}' has zero/invalid coordinates after checking center, skipping.", name);
            return null;
        }

        String street = tags.getOrDefault("addr:street", "");
        String housenumber = tags.getOrDefault("addr:housenumber", "");
        String postcode = tags.getOrDefault("addr:postcode", "");
        String cityTag = tags.getOrDefault("addr:city", "");
        String subUrbTag = tags.getOrDefault("addr:suburb", "");

        StringBuilder addressBuilder = new StringBuilder();
        if (!housenumber.isEmpty()) addressBuilder.append(housenumber).append(" ");
        if (!street.isEmpty()) addressBuilder.append(street);

        String finalCityForAddress = !cityTag.isEmpty() ? cityTag : (district != null && !district.isEmpty() ? district : state);

        if (addressBuilder.length() > 0) addressBuilder.append(", ");
        if (!subUrbTag.isEmpty()) addressBuilder.append(subUrbTag).append(", ");
        addressBuilder.append(finalCityForAddress);

        if (!postcode.isEmpty()) addressBuilder.append(" - ").append(postcode);

        String address = addressBuilder.toString().trim();
        if (address.startsWith(",")) address = address.substring(1).trim();
        if (address.endsWith(",")) address = address.substring(0, address.length() - 1).trim();
        if (address.isEmpty()) address = finalCityForAddress;


        return new LabResult(
                String.valueOf(element.getId()),
                name,
                address,
                lat,
                lon,
                tags.get("phone"),
                tags.get("website"),
                state, // queryState
                district, // queryDistrict
                healthcareTag.isEmpty() ? amenityTag : healthcareTag
        );
    }
}