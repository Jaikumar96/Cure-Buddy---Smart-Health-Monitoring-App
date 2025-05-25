package com.example.curebuddy_backend.model.overpass; // Or your package

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.util.List;

@JsonIgnoreProperties(ignoreUnknown = true)
public class OverpassResponse {
    private List<OverpassElement> elements;

    public List<OverpassElement> getElements() { return elements; }
    public void setElements(List<OverpassElement> elements) { this.elements = elements; }
}