/// Event detail page for the Saath app
///
/// This file contains the event detail interface with real API integration.
import 'package:flutter/material.dart';
import '../app_footer.dart';
import '../models/event_model.dart';
import '../services/events_service.dart';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'join_event_page.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;

  const EventDetailPage({Key? key, required this.eventId}) : super(key: key);

  @override
  _EventDetailPageState createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final EventsService _eventsService = EventsService();
  
  EventModel? _event;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEventDetails();
  }

  Future<void> _fetchEventDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🔍 [EventDetailPage] Fetching event details for ID: ${widget.eventId}');
      
      // Try public events first (no authentication required)
      EventModel? event;
      try {
        print('🔍 [EventDetailPage] Trying public events endpoint...');
        event = await _fetchEventFromPublicAPI();
        if (event != null) {
          print('🔍 [EventDetailPage] Successfully fetched from public events API');
        }
      } catch (e) {
        print('🔍 [EventDetailPage] Public events failed, trying user events: $e');
        // If public events fail, try user events
        try {
          event = await _eventsService.fetchEventById(widget.eventId);
          if (event != null) {
            print('🔍 [EventDetailPage] Successfully fetched from user events API');
          }
        } catch (userError) {
          print('🔍 [EventDetailPage] User events also failed: $userError');
        }
      }

      if (event != null) {
        setState(() {
          _event = event;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Event not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [EventDetailPage] Error fetching event details: $e');
      setState(() {
        _error = 'Failed to load event details: $e';
        _isLoading = false;
      });
    }
  }

  Future<EventModel?> _fetchEventFromPublicAPI() async {
    try {
      // Use the test endpoint that doesn't filter by status
      final uri = Uri.parse('${ApiConfig.eventsEndpoint}/test/${widget.eventId}');
      print('🔍 [EventDetailPage] Public API URL: ${uri.toString()}');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('🔍 [EventDetailPage] Response status: ${response.statusCode}');
      print('🔍 [EventDetailPage] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return EventModel.fromJson(data['data']);
        } else {
          print('❌ [EventDetailPage] API returned success: false or no data');
          print('❌ [EventDetailPage] Message: ${data['message']}');
        }
      } else if (response.statusCode == 404) {
        print('❌ [EventDetailPage] Event not found (404)');
        final data = jsonDecode(response.body);
        print('❌ [EventDetailPage] Error message: ${data['message']}');
      } else {
        print('❌ [EventDetailPage] HTTP error: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('❌ [EventDetailPage] Error in public API: $e');
      return null;
    }
  }

  Future<void> _joinEvent() async {
    if (_event == null) return;

    // Navigate to join event page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JoinEventPage(event: _event!),
      ),
    );
  }

  Widget _buildEventDetail() {
    final event = _event!;
    final dateStatus = event.getDateStatus();
    final dateStatusColor = event.getDateStatusColor();
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(int.parse(dateStatusColor.replaceAll('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    dateStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Profile icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'P',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Event cover image
          Container(
            width: double.infinity,
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: event.image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      event.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                    ),
                  )
                : _buildImagePlaceholder(),
          ),
          
          // Event information
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event title
                Text(
                  event.eventName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Date and time
                Text(
                  '${event.getDateStatus()} • ${event.formattedTime}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Location
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.place,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          event.getDistance(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Organizer
                Row(
                  children: [
                    Text(
                      'Organizer',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'E',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      event.organizer,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Attendees
                Text(
                  'Attendees (${event.attendeesCount})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Attendee profile circles
                    ...List.generate(
                      event.attendeesCount > 4 ? 4 : event.attendeesCount,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getAttendeeColor(index),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index), // A, B, C, D
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // More attendees indicator
                    if (event.attendeesCount > 4)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${event.attendeesCount - 4} more',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Description
                Text(
                  'Description',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Text(
        'Event Cover Image',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 16,
        ),
      ),
    );
  }

  Color _getAttendeeColor(int index) {
    final colors = [
      Colors.purple[100]!,
      Colors.red[100]!,
      Colors.green[100]!,
      Colors.pink[100]!,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchEventDetails,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _event == null
                  ? Center(child: Text('Event not found'))
                  : Stack(
                      children: [
                        _buildEventDetail(),
                        // Join Event button at bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _event!.isRegistered ? null : _joinEvent,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                        _event!.isRegistered ? 'Already Joined' : 'Join Event',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
      bottomNavigationBar: AppFooter(
        currentIndex: 1, // Events tab
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/welcome');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/events');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/forum');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/wellness');
          } else if (index == 4) {
            Navigator.pushReplacementNamed(context, '/chat');
          }
        },
      ),
    );
  }
} 