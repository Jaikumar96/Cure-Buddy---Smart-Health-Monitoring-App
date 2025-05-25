package com.example.curebuddy_backend.service;

import jakarta.mail.MessagingException; // For Jakarta Mail (Spring Boot 3+)
// import javax.mail.MessagingException; // For javax.mail (Spring Boot 2.x)
import jakarta.mail.internet.MimeMessage;
// import javax.mail.internet.MimeMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value; // To read from application.properties
import org.springframework.core.io.FileSystemResource;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import java.io.File;

@Service
public class EmailService {

    @Autowired
    private JavaMailSender mailSender;

    @Value("${spring.mail.username}") // Inject the configured username
    private String fromEmailAddress;

    /**
     * Sends a simple text email.
     * @param to Recipient's email address.
     * @param subject Subject of the email.
     * @param body Text content of the email.
     */
    public void sendEmail(String to, String subject, String body) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmailAddress); // Use the configured sender email
            message.setTo(to);
            message.setSubject(subject);
            message.setText(body);

            mailSender.send(message);
            System.out.println("Simple email sent successfully to " + to);
        } catch (Exception e) {
            System.err.println("Error sending simple email to " + to + ": " + e.getMessage());
            // In a real application, you'd likely use a logger (e.g., SLF4J)
            // and might rethrow a custom application exception or handle it based on policy.
            throw new RuntimeException("Failed to send simple email: " + e.getMessage(), e);
        }
    }

    /**
     * Sends an email with an attachment.
     * @param to Recipient's email address.
     * @param subject Subject of the email.
     * @param body Text content of the email (can be HTML if setText is used with html=true).
     * @param attachmentPath Absolute path to the file to be attached.
     * @param attachmentName The name that the attachment should have in the email.
     */
    public void sendEmailWithAttachment(String to, String subject, String body, String attachmentPath, String attachmentName) {
        MimeMessage message = mailSender.createMimeMessage();
        try {
            // true indicates multipart message (needed for attachments)
            // The third argument is optional and sets the character encoding (e.g., "UTF-8")
            MimeMessageHelper helper = new MimeMessageHelper(message, true);

            helper.setFrom(fromEmailAddress); // Use the configured sender email
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(body); // For plain text. Use helper.setText(body, true) for HTML content.

            File fileToAttach = new File(attachmentPath);
            if (!fileToAttach.exists() || !fileToAttach.canRead()) {
                System.err.println("Attachment file not found or not readable: " + attachmentPath);
                // Option 1: Send email without attachment and notify
                // helper.setText(body + "\n\n[Attachment " + attachmentName + " could not be included.]");
                // mailSender.send(message);
                // return;

                // Option 2: Throw an exception
                throw new RuntimeException("Attachment file not found or not readable: " + attachmentPath);
            }

            FileSystemResource fileResource = new FileSystemResource(fileToAttach);
            helper.addAttachment(attachmentName, fileResource);

            mailSender.send(message);
            System.out.println("Email with attachment sent successfully to " + to);

        } catch (MessagingException e) {
            System.err.println("Error sending email with attachment to " + to + ": " + e.getMessage());
            throw new RuntimeException("Failed to send email with attachment: " + e.getMessage(), e);
        } catch (Exception e) { // Catch other potential runtime exceptions, e.g., file not found
            System.err.println("Unexpected error preparing email with attachment for " + to + ": " + e.getMessage());
            throw new RuntimeException("Unexpected error preparing email with attachment: " + e.getMessage(), e);
        }
    }
}