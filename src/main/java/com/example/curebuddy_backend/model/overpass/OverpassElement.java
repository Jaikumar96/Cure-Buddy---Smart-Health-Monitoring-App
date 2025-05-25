package com.example.curebuddy_backend.model.overpass; // Or your package

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.util.Map;

@JsonIgnoreProperties(ignoreUnknown = true)
public class OverpassElement {
    private String type;
    private long id;
    private double lat; // For nodes or center of ways/relations
    private double lon; // For nodes or center of ways/relations
    private Map<String, String> tags;
    private OverpassCenter center; // For ways and relations if using 'out center;'

    // Getters and setters
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public long getId() { return id; }
    public void setId(long id) { this.id = id; }
    public double getLat() { return lat; }
    public void setLat(double lat) { this.lat = lat; }
    public double getLon() { return lon; }
    public void setLon(double lon) { this.lon = lon; }
    public Map<String, String> getTags() { return tags; }
    public void setTags(Map<String, String> tags) { this.tags = tags; }
    public OverpassCenter getCenter() { return center; }
    public void setCenter(OverpassCenter center) { this.center = center; }
}