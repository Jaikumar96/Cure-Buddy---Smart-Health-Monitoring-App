package com.example.curebuddy_backend.controller;

import com.example.curebuddy_backend.auth.UpdateRequest;
import com.example.curebuddy_backend.model.User;
import com.example.curebuddy_backend.repository.HealthReportRepository;
import com.example.curebuddy_backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api")
public class UserController {

    private final UserRepository repo;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private HealthReportRepository reportRepo;


    @Autowired
    public UserController(UserRepository repo) {
        this.repo = repo;
    }

    @GetMapping("/user/profile")
    public String profile() {
        return "This is a secured profile endpoint";
    }

    @GetMapping("/user/me")
    public ResponseEntity<?> getMyInfo(Authentication auth) {
        String email = auth.getName();
        Optional<User> userOpt = repo.findByEmail(email);

        if (userOpt.isEmpty()) return ResponseEntity.status(404).body("User not found");

        User user = userOpt.get();
        Map<String, String> info = new HashMap<>();
        info.put("name", user.getName());
        info.put("email", user.getEmail());
        info.put("role", user.getRole());

        return ResponseEntity.ok(info);
    }

    @GetMapping("/admin/users")
    public ResponseEntity<?> listAllUsers(Authentication auth) {
        String email = auth.getName();
        Optional<User> userOpt = repo.findByEmail(email);
        if (userOpt.isEmpty() || !userOpt.get().getRole().equalsIgnoreCase("ADMIN")) {
            return ResponseEntity.status(403).body("Access denied. Only admin allowed.");
        }

        return ResponseEntity.ok(repo.findAll());
    }

    @PutMapping("/user/update")
    public ResponseEntity<?> updateProfile(@RequestBody UpdateRequest req, Authentication auth) {
        String email = auth.getName();
        Optional<User> userOpt = repo.findByEmail(email);
        if (userOpt.isEmpty()) return ResponseEntity.status(404).body("User not found");

        User user = userOpt.get();
        if (req.name != null) user.setName(req.name);
        if (req.password != null) user.setPassword(passwordEncoder.encode(req.password));
        repo.save(user);

        return ResponseEntity.ok("Profile updated successfully!");
    }
    @GetMapping("/admin/reports")
    public ResponseEntity<?> allReports(Authentication auth) {
        Optional<User> admin = repo.findByEmail(auth.getName());
        if (admin.isEmpty() || !admin.get().getRole().equalsIgnoreCase("ADMIN"))
            return ResponseEntity.status(403).body("Access denied.");

        var reports = reportRepo.findAll();

        var reportDtos = reports.stream().map(report -> {
            Map<String, Object> map = new HashMap<>();
            map.put("fileName", report.getFileName());
            map.put("fileType", report.getFileType());
            map.put("uploadedAt", report.getUploadedAt());
            map.put("healthRiskPrediction", report.getHealthRiskPrediction());
            map.put("downloadLink", "/uploads/" + report.getFileName());
            return map;
        }).toList();


        return ResponseEntity.ok(reportDtos);
    }


    @DeleteMapping("/admin/delete-user/{id}")
    public ResponseEntity<?> deleteUser(@PathVariable String id, Authentication auth) {
        Optional<User> admin = repo.findByEmail(auth.getName());
        if (admin.isEmpty() || !admin.get().getRole().equalsIgnoreCase("ADMIN"))
            return ResponseEntity.status(403).body("Access denied.");
        repo.deleteById(id);
        return ResponseEntity.ok("User deleted successfully.");
    }

    @GetMapping("/admin/dashboard")
    public ResponseEntity<?> dashboardStats(Authentication auth) {
        Optional<User> admin = repo.findByEmail(auth.getName());
        if (admin.isEmpty() || !admin.get().getRole().equalsIgnoreCase("ADMIN"))
            return ResponseEntity.status(403).body("Access denied.");

        long userCount = repo.count();
        long reportCount = reportRepo.count();
        return ResponseEntity.ok(Map.of(
                "totalUsers", userCount,
                "totalReports", reportCount
        ));
    }


}
