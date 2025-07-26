/// API Configuration for the Saath App
///
/// This file contains all the API endpoints and configuration
/// used throughout the application.

class ApiConfig {
  // Base URL for all API requests - use your PC's local IP for real device access
  static const String baseUrl = 'http://192.168.1.7:5000';
  
  // API Endpoints
  static String get homeEndpoint => '$baseUrl/';
  static String get otpEndpoint => '$baseUrl/api/otp';
  static String get verifyOtpEndpoint => '$baseUrl/api/verify-otp';
  static String get networkCheckIp => 'google.com';
  
  // Forum Endpoints
  static String get forumEndpoint => '$baseUrl/api/forum';
  
  // Auth Endpoints
  static String get googleSignInEndpoint => '$baseUrl/auth/google-signin';
  
  // User Endpoints
  static String get customerEndpoint => '$baseUrl/api/customer';

  // Event Endpoints
  static String get eventsEndpoint => '$baseUrl/api/events';
  static String get eventsUsersEndpoint => '$baseUrl/api/events-users';
  static String get eventDetailsEndpoint => '$baseUrl/api/events/'; // Append event ID
  static String get eventRegistrationEndpoint => '$baseUrl/api/event-registrations';
  static String get eventUpdateSlotsEndpoint => '$baseUrl/api/events-users/'; // Append event ID + /update-slots
}
