package com.example.curebuddy_backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class CurebuddyBackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(CurebuddyBackendApplication.class, args);
	}

}
