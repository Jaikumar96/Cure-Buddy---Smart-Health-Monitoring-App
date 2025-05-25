# Cure Buddy – Smart Health Monitoring App 🩺📱

**Cure Buddy** is a smart health monitoring application built using Java (Spring Boot) for the backend and Flutter for the frontend. 
It enables users to schedule health checkups, analyze medical reports, receive personalized health tips, and find nearby healthcare
services with ease.

---

## 🔍 Overview

This application acts as a personal health assistant that:
- Schedules regular health checkups and sends reminders.
- Allows users to upload medical reports for analysis.
- Provides personalized health recommendations.
- Suggests local doctors, labs, and pharmacies using external APIs.
- Sends alerts based on abnormal health data.

---

## 🛠️ Tech Stack

| Component    | Technology              |
|--------------|-------------------------|
| Backend      | Java (Spring Boot)      |
| Frontend     | Flutter (Dart)          |
| Database     | PostgreSQL / MongoDB    |
| APIs Used    | Google Maps, WHO, CDC   |
| Notification | Twilio / Email Service  |
| AI/ML        | Weka / Deeplearning4j (for report analysis) |

---

## 📁 Project Structure

```

Cure-Buddy---Smart-Health-Monitoring-App/
├── backend/               # Spring Boot API backend
│   ├── src/
│   └── pom.xml
│
├── frontend/              # Flutter mobile frontend
│   ├── lib/
│   ├── android/
│   ├── ios/
│   ├── web/
│   ├── pubspec.yaml
│   └── .env               # For storing API keys (e.g., Google Maps)
│
└── README.md              # Project documentation

````
## 🎥 Demo

Watch a quick walkthrough of the Cure Buddy app:

[Click here to view the demo video]((https://drive.google.com/file/d/1hnP8SQmQVJn9lgajtoivbw4Y1mcHJ4rZ/view?usp=drive_link))



---

## 🔑 Core Features

- **User Authentication**
  - Sign up/login for patients and doctors
  - JWT-based secure session management

- **Health Checkup Scheduler**
  - Set reminders for regular checkups
  - Notifications via email or SMS

- **Medical Report Upload & Analysis**
  - Upload PDFs or images
  - Get AI-generated insights on uploaded data

- **Smart Health Tips**
  - Personalized suggestions from verified medical sources (WHO, CDC)

- **Nearby Services**
  - Locate pharmacies, labs, and doctors using Google Maps API

- **Doctor Panel**
  - Doctors can view and monitor patient records
  - Add observations or send alerts

- **Data Visualization**
  - Health trends over time via graphs (in Flutter UI)

---

## 🧪 API & AI Integration

- **Google Maps API** – Location and navigation to pharmacies/labs.
- **WHO & CDC APIs** – Dynamic health info and tips.
- **Weka/Deeplearning4j** – Health report classification and prediction (backend).

Ensure the `.env` file in the Flutter frontend includes:
```env
# Flutter .env file
GOOGLE_MAPS_API_KEY_ANDROID=<>
GOOGLE_MAPS_API_KEY_IOS=<>
# You can also put your backend API base URL here if you haven't already
API_BASE_URL=http://192.168.252.250:8080/api
````
Ensure the `frontend\android\local.properties` Flutter includes
```
sdk.dir=C:\\Users\\admin\\AppData\\Local\\Android\\sdk
flutter.sdk=C:\\flutter\\src\\flutter
flutter.buildMode=debug
flutter.versionName=1.0.0
flutter.versionCode=1

# Add your Google Maps API Key for Android here.
GOOGLE_MAPS_API_KEY_ANDROID=<>
```
Ensure the `.env` file in the Spring-boot backend includes:
```env
# Flutter .env file
 TWILIO_SID=<>
 TWILIO_AUTH_TOKEN=<>
 TWILIO_NUMBER=<>
````

---

## 🚀 How to Run the Project

### Backend (Spring Boot)

```bash
cd backend
mvn clean install
mvn spring-boot:run
```

### Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run
```

> Make sure Android Studio or a device emulator is set up for running the Flutter app.

---

## 📝 License

This project is open-source and available under the [MIT License](LICENSE).
