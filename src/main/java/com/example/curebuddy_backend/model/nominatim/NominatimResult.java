package com.example.curebuddy_backend.model.nominatim; // Or your package

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
public class NominatimResult {
    @JsonProperty("place_id")
    private long placeId;
    private String licence;
    @JsonProperty("osm_type")
    private String osmType;
    @JsonProperty("osm_id")
    private long osmId;
    private String lat;
    private String lon;
    @JsonProperty("display_name")
    private String displayName;
    // Add boundingbox if needed: private List<String> boundingbox;
    // Add address object if needed and map its fields

    // Getters and setters
    public long getPlaceId() { return placeId; }
    public void setPlaceId(long placeId) { this.placeId = placeId; }
    public String getLicence() { return licence; }
    public void setLicence(String licence) { this.licence = licence; }
    public String getOsmType() { return osmType; }
    public void setOsmType(String osmType) { this.osmType = osmType; }
    public long getOsmId() { return osmId; }
    public void setOsmId(long osmId) { this.osmId = osmId; }
    public String getLat() { return lat; }
    public void setLat(String lat) { this.lat = lat; }
    public String getLon() { return lon; }
    public void setLon(String lon) { this.lon = lon; }
    public String getDisplay_name() { return displayName; } // Keep consistent with JSON
    public void setDisplay_name(String displayName) { this.displayName = displayName; }

    @Override
    public String toString() {
        return "NominatimResult{" + "displayName='" + displayName + '\'' + ", lat='" + lat + '\'' + ", lon='" + lon + '\'' + '}';
    }
}