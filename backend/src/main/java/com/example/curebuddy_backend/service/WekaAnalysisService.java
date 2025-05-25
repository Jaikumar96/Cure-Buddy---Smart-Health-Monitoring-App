package com.example.curebuddy_backend.service;

import weka.classifiers.Classifier;
import weka.core.converters.ConverterUtils.DataSource;
import weka.core.Instance;
import weka.core.Instances;
import weka.core.DenseInstance; // Explicit import
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.io.ObjectInputStream;

@Service
public class WekaAnalysisService {

    private Instances trainingStructure;
    private Classifier model;

    public WekaAnalysisService(@Value("${weka.model.path}") String modelPath,
                               @Value("${weka.structure.path}") String structurePath) throws Exception {
        // Load the trained model from the .model file
        try (InputStream modelIs = new ClassPathResource(modelPath.startsWith("classpath:") ? modelPath.substring(10) : modelPath).getInputStream();
             ObjectInputStream ois = new ObjectInputStream(modelIs)) {
            model = (Classifier) ois.readObject();
        } catch (Exception e) {
            System.err.println("Error loading Weka model from path: " + modelPath);
            e.printStackTrace(); // Print stack trace for better debugging
            throw e;
        }

        // Load only the structure (no data needed) from the ARFF file
        try (InputStream structureIs = new ClassPathResource(structurePath.startsWith("classpath:") ? structurePath.substring(10) : structurePath).getInputStream()) {
            DataSource source = new DataSource(structureIs);
            trainingStructure = source.getStructure();
            if (trainingStructure.classIndex() == -1) {
                trainingStructure.setClassIndex(trainingStructure.numAttributes() - 1);
            }
        } catch (Exception e) {
            System.err.println("Error loading Weka structure from path: " + structurePath);
            e.printStackTrace(); // Print stack trace
            throw e;
        }

        System.out.println("Weka model and structure loaded successfully.");
        System.out.println("Model file: " + modelPath);
        System.out.println("Structure file: " + structurePath);
        System.out.println("Number of attributes in loaded structure: " + trainingStructure.numAttributes());
        if (trainingStructure.classIndex() >= 0) {
            System.out.println("Class attribute: " + trainingStructure.classAttribute().name() + " at index " + trainingStructure.classIndex());
        } else {
            System.err.println("CRITICAL: Class attribute not set or found in training structure!");
        }
    }

    public String predictHealthRisk(double bloodSugar, double bloodPressure, double pulseRate, double cholesterol, double ecgScore) throws Exception {
        if (trainingStructure == null || model == null) {
            throw new IllegalStateException("WekaAnalysisService not properly initialized. Model or structure is null.");
        }

        // Create new instance for prediction
        // The number of attributes for DenseInstance should match the number of attributes in your trainingStructure.
        Instance instance = new DenseInstance(trainingStructure.numAttributes());
        instance.setDataset(trainingStructure); // Link instance to the structure

        // Attribute indices are 0-based.
        // Assumed order from ARFF: blood_sugar, blood_pressure, pulse_rate, cholesterol, ecg_score, health_risk (class)
        // Your structure has 6 attributes. Indices 0-4 for features, index 5 for class.

        try {
            if (Double.isNaN(bloodSugar)) {
                instance.setMissing(0); // blood_sugar at index 0
            } else {
                instance.setValue(0, bloodSugar);
            }

            if (Double.isNaN(bloodPressure)) {
                instance.setMissing(1); // blood_pressure at index 1
            } else {
                instance.setValue(1, bloodPressure);
            }

            if (Double.isNaN(pulseRate)) {
                instance.setMissing(2); // pulse_rate at index 2
            } else {
                instance.setValue(2, pulseRate);
            }

            if (Double.isNaN(cholesterol)) {
                instance.setMissing(3); // cholesterol at index 3
            } else {
                instance.setValue(3, cholesterol);
            }

            if (Double.isNaN(ecgScore)) {
                instance.setMissing(4); // ecg_score at index 4
            } else {
                instance.setValue(4, ecgScore);
            }

            // The class attribute (index 5, or trainingStructure.classIndex()) is what we want to predict.
            // Weka expects the class attribute to be missing for classification.
            if (trainingStructure.classIndex() >= 0) {
                instance.setMissing(trainingStructure.classIndex());
            } else {
                System.err.println("Class index not set, cannot set class attribute to missing for prediction.");
                // Optionally throw an error here or handle it based on your application's needs.
            }

        } catch (Exception e) {
            System.err.println("Error setting instance values. Check attribute indices and ARFF structure.");
            System.err.println("Expected features: blood_sugar (0), blood_pressure (1), pulse_rate (2), cholesterol (3), ecg_score (4)");
            System.err.println("Class attribute: " + (trainingStructure.classIndex() >= 0 ? trainingStructure.classAttribute().name() + " (index " + trainingStructure.classIndex() + ")" : "NOT SET"));
            System.err.println("Number of attributes in loaded structure: " + trainingStructure.numAttributes());
            e.printStackTrace(); // Print stack trace
            throw e;
        }

        // Predict using loaded model
        double result = model.classifyInstance(instance);

        // Return the predicted class label (NORMAL / HIGH / CRITICAL)
        return trainingStructure.classAttribute().value((int) result);
    }
}