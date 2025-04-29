package com.example.curebuddy_backend.controller;

import com.example.curebuddy_backend.auth.UpdateRequest;
import com.example.curebuddy_backend.model.User;
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

}
