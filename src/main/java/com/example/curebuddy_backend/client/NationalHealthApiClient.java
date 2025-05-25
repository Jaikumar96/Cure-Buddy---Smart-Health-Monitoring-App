package com.example.curebuddy_backend.client;

import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import java.util.List;
import java.util.Map;

@Component
public class NationalHealthApiClient {

    private static final String BASE_URL = "https://api.data.gov.in/resource/98fa254e-c5f8-4910-a19b-4828939b477d";
    private static final String API_KEY = "579b464db66ec23bdd000001cdd3946e44ce4aad7209ff7b23ac571b";

    public List<Map<String, Object>> fetchHospitals() {
        RestTemplate restTemplate = new RestTemplate();
        String url = BASE_URL + "?api-key=" + API_KEY + "&format=json&limit=100";  // no city filter here


        Map response = restTemplate.getForObject(url, Map.class);
        List<Map<String, Object>> records = (List<Map<String, Object>>) response.get("records");

        return records;
    }
}