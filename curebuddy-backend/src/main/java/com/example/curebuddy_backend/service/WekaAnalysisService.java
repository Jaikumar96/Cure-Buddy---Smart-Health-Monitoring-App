package com.example.curebuddy_backend.service;

import weka.classifiers.Classifier;
import weka.core.converters.ConverterUtils.DataSource;
import weka.core.Instance;
import weka.core.Instances;
import org.springframework.stereotype.Service;

import java.io.FileInputStream;
import java.io.ObjectInputStream;

@Service
public class WekaAnalysisService {

    private Instances trainingStructure;
    private Classifier model;

    public WekaAnalysisService() throws Exception {
        // Load the trained RandomForest model from the .model file
        ObjectInputStream ois = new ObjectInputStream(new FileInputStream("src/main/resources/health_risk_pro.model"));
        model = (Classifier) ois.readObject();
        ois.close();

        // Load only the structure (no data needed) from health_train_pro.arff
        DataSource source = new DataSource("src/main/resources/health_train_pro.arff");
        trainingStructure = source.getStructure();
        trainingStructure.setClassIndex(trainingStructure.numAttributes() - 1);
    }

    public String predictHealthRisk(double bloodSugar, double bloodPressure, double pulseRate, double cholesterol, double ecgScore) throws Exception {
        // Create new instance for prediction
        Instance instance = new weka.core.DenseInstance(6);
        instance.setDataset(trainingStructure);
        instance.setValue(0, bloodSugar);
        instance.setValue(1, bloodPressure);
        instance.setValue(2, pulseRate);
        instance.setValue(3, cholesterol);
        instance.setValue(4, ecgScore);

        // Predict using loaded model
        double result = model.classifyInstance(instance);

        // Return the predicted class label (NORMAL / HIGH / CRITICAL)
        return trainingStructure.classAttribute().value((int) result);
    }
}
