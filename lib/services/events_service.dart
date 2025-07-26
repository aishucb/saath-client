/// Events service for the Saath app
///
/// This file contains the service class for handling events API calls.
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/event_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventsService {
  static final EventsService _instance = EventsService._internal();
  factory EventsService() => _instance;
  EventsService._internal();

  /// Filter out past events from a list
  List<Map<String, dynamic>> _filterFutureEvents(List<dynamic> eventsList) {
    final now = DateTime.now();
    final futureEvents = eventsList.where((event) {
      final eventDate = DateTime.parse(event['date']);
      return eventDate.isAfter(now);
    }).toList();
    
    print('🔍 [EventsService] Filtered ${eventsList.length} events to ${futureEvents.length} future events');
    return futureEvents.cast<Map<String, dynamic>>();
  }

  /// Fetch all published events (filtered to show only future events)
  Future<List<EventModel>> fetchEvents({
    int page = 1,
    int limit = 10,
    String? search,
    String? sortBy,
    String? sortOrder,
    double? minPrice,
    double? maxPrice,
    String? dateFrom,
    String? dateTo,
    List<String>? tags,
  }) async {
    try {
      print('🔍 [EventsService] Starting fetchEvents...');
      
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (sortBy != null) {
        queryParams['sortBy'] = sortBy;
      }
      if (sortOrder != null) {
        queryParams['sortOrder'] = sortOrder;
      }
      if (minPrice != null) {
        queryParams['minPrice'] = minPrice.toString();
      }
      if (maxPrice != null) {
        queryParams['maxPrice'] = maxPrice.toString();
      }
      if (dateFrom != null) {
        queryParams['dateFrom'] = dateFrom;
      }
      if (dateTo != null) {
        queryParams['dateTo'] = dateTo;
      }
      if (tags != null && tags.isNotEmpty) {
        queryParams['tags'] = tags.join(',');
      }

      final uri = Uri.parse('${ApiConfig.eventsEndpoint}/test').replace(queryParameters: queryParams);
      print('🔍 [EventsService] API URL: ${uri.toString()}');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('🔍 [EventsService] Response status: ${response.statusCode}');
      print('🔍 [EventsService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔍 [EventsService] Parsed data: $data');
        
        if (data['success'] == true && data['data'] != null) {
          final eventsList = data['data'] as List;
          print('🔍 [EventsService] Found ${eventsList.length} events');
          return eventsList.map((event) => EventModel.fromJson(event)).toList();
        } else {
          print('❌ [EventsService] API returned success: false or no data');
          throw Exception(data['message'] ?? 'Failed to fetch events');
        }
      } else {
        print('❌ [EventsService] HTTP error: ${response.statusCode}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [EventsService] Error in fetchEvents: $e');
      rethrow;
    }
  }

  /// Fetch events for authenticated users
  Future<List<EventModel>> fetchUserEvents({
    int page = 1,
    int limit = 10,
    String? search,
    String? sortBy,
    String? sortOrder,
    double? minPrice,
    double? maxPrice,
    String? dateFrom,
    String? dateTo,
    List<String>? tags,
    String? organizer,
    String? place,
    String? userToken,
  }) async {
    try {
      print('🔍 [EventsService] Starting fetchUserEvents...');
      
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (sortBy != null) {
        queryParams['sortBy'] = sortBy;
      }
      if (sortOrder != null) {
        queryParams['sortOrder'] = sortOrder;
      }
      if (minPrice != null) {
        queryParams['minPrice'] = minPrice.toString();
      }
      if (maxPrice != null) {
        queryParams['maxPrice'] = maxPrice.toString();
      }
      if (dateFrom != null) {
        queryParams['dateFrom'] = dateFrom;
      }
      if (dateTo != null) {
        queryParams['dateTo'] = dateTo;
      }
      if (tags != null && tags.isNotEmpty) {
        queryParams['tags'] = tags.join(',');
      }
      if (organizer != null) {
        queryParams['organizer'] = organizer;
      }
      if (place != null) {
        queryParams['place'] = place;
      }

      final uri = Uri.parse(ApiConfig.eventsUsersEndpoint).replace(queryParameters: queryParams);
      print('🔍 [EventsService] API URL: ${uri.toString()}');

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (userToken != null) {
        headers['Authorization'] = 'Bearer $userToken';
        print('🔍 [EventsService] Using authentication token');
      } else {
        print('🔍 [EventsService] No authentication token provided');
      }

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      print('🔍 [EventsService] Response status: ${response.statusCode}');
      print('🔍 [EventsService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔍 [EventsService] Parsed data: $data');
        
        if (data['success'] == true && data['data'] != null) {
          final eventsList = data['data'] as List;
          print('🔍 [EventsService] Found ${eventsList.length} events');
          return eventsList.map((event) => EventModel.fromJson(event)).toList();
        } else {
          print('❌ [EventsService] API returned success: false or no data');
          throw Exception(data['message'] ?? 'Failed to fetch events');
        }
      } else {
        print('❌ [EventsService] HTTP error: ${response.statusCode}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [EventsService] Error in fetchUserEvents: $e');
      rethrow;
    }
  }

  /// Fetch a single event by ID
  Future<EventModel?> fetchEventById(String eventId) async {
    try {
      print('🔍 [EventsService] Fetching event by ID: $eventId');
      
      final uri = Uri.parse('${ApiConfig.eventsUsersEndpoint}/$eventId');
      print('🔍 [EventsService] API URL: ${uri.toString()}');

      // Get user token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken');
      
      print('🔍 [EventsService] User token: ${userToken != null ? "Present" : "Not present"}');

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (userToken != null) {
        headers['Authorization'] = 'Bearer $userToken';
      }

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      print('🔍 [EventsService] Response status: ${response.statusCode}');
      print('🔍 [EventsService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return EventModel.fromJson(data['data']);
        } else {
          print('❌ [EventsService] API returned success: false or no data');
          print('❌ [EventsService] Message: ${data['message']}');
          throw Exception(data['message'] ?? 'Failed to fetch event');
        }
      } else if (response.statusCode == 401) {
        print('❌ [EventsService] Unauthorized (401) - No token or invalid token');
        final data = jsonDecode(response.body);
        print('❌ [EventsService] Error message: ${data['message']}');
        throw Exception('Authentication required: ${data['message']}');
      } else if (response.statusCode == 404) {
        print('❌ [EventsService] Event not found (404)');
        final data = jsonDecode(response.body);
        print('❌ [EventsService] Error message: ${data['message']}');
        return null;
      } else {
        print('❌ [EventsService] HTTP error: ${response.statusCode}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [EventsService] Error in fetchEventById: $e');
      rethrow;
    }
  }

  /// Register for an event
  Future<bool> registerForEvent(String eventId, {
    String? pricingTierName,
    int attendeeCount = 1,
  }) async {
    try {
      print('🔍 [EventsService] Registering for event: $eventId');
      
      final uri = Uri.parse(ApiConfig.eventRegistrationEndpoint);
      print('🔍 [EventsService] API URL: ${uri.toString()}');

      // Get user token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken');
      final currentUserId = prefs.getString('current_user_id');
      
      print('🔍 [EventsService] User token: ${userToken != null ? "Present" : "Not present"}');
      print('🔍 [EventsService] Current user ID: ${currentUserId ?? "Not present"}');
      
      if (userToken != null) {
        print('🔍 [EventsService] Token preview: ${userToken.substring(0, 20)}...');
      }

      if (userToken == null) {
        print('❌ [EventsService] No user token available for event registration');
        throw Exception('Authentication required to register for event');
      }

      final body = <String, dynamic>{
        'eventId': eventId,
        'attendeeCount': attendeeCount,
      };

      if (pricingTierName != null) {
        body['pricingTierName'] = pricingTierName;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $userToken',
      };

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      print('🔍 [EventsService] Response status: ${response.statusCode}');
      print('🔍 [EventsService] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ [EventsService] Successfully registered for event');
          return true;
        } else {
          print('❌ [EventsService] API returned success: false');
          print('❌ [EventsService] Message: ${data['message']}');
          return false;
        }
      } else {
        print('❌ [EventsService] HTTP error: ${response.statusCode}');
        final data = jsonDecode(response.body);
        print('❌ [EventsService] Error message: ${data['message']}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [EventsService] Error registering for event: $e');
      rethrow;
    }
  }

  /// Update available slots for an event based on registration count
  Future<bool> updateEventSlots(String eventId, int registrationsCount) async {
    try {
      print('🔍 [EventsService] Updating slots for event: $eventId with $registrationsCount registrations');
      
      final uri = Uri.parse('${ApiConfig.eventUpdateSlotsEndpoint}$eventId/update-slots');
      print('🔍 [EventsService] API URL: ${uri.toString()}');

      // Get user token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken');
      
      print('🔍 [EventsService] User token: ${userToken != null ? "Present" : "Not present"}');

      if (userToken == null) {
        print('❌ [EventsService] No user token available for updating slots');
        throw Exception('Authentication required to update event slots');
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $userToken',
      };

      final body = jsonEncode({
        'registrationsCount': registrationsCount,
      });

      final response = await http.put(
        uri,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));

      print('🔍 [EventsService] Response status: ${response.statusCode}');
      print('🔍 [EventsService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ [EventsService] Successfully updated event slots');
          return true;
        } else {
          print('❌ [EventsService] API returned success: false');
          print('❌ [EventsService] Message: ${data['message']}');
          return false;
        }
      } else {
        print('❌ [EventsService] HTTP error: ${response.statusCode}');
        final data = jsonDecode(response.body);
        print('❌ [EventsService] Error message: ${data['message']}');
        return false;
      }
    } catch (e) {
      print('❌ [EventsService] Error updating event slots: $e');
      return false;
    }
  }
} 