/// Events page for the Saath app
///
/// This file contains the events interface with real API integration.
import 'package:flutter/material.dart';
import 'app_footer.dart';
import 'models/event_model.dart';
import 'services/events_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'config/api_config.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({Key? key}) : super(key: key);

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final EventsService _eventsService = EventsService();
  final TextEditingController _searchController = TextEditingController();
  
  List<EventModel> _events = [];
  List<EventModel> _filteredEvents = [];
  bool _isLoading = true;
  String? _error;
  String? _userToken;
  
  // Tab state
  int _selectedTabIndex = 0;
  
  // Filter state
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Social', 'Sports', 'Music', 'Food', 'Tech'];

  @override
  void initState() {
    super.initState();
    _loadUserToken();
    _fetchEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userToken = prefs.getString('userToken') ?? prefs.getString('user_token') ?? prefs.getString('adminToken');
    } catch (e) {
      print('Error loading user token: $e');
    }
  }

  Future<void> _fetchEvents() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🔍 [EventsPage] Starting to fetch events...');
      print('🔍 [EventsPage] User token: ${_userToken != null ? "Present" : "Not present"}');

      List<EventModel> events;
      
      // Try public events first (no authentication required)
      try {
        print('🔍 [EventsPage] Trying public events endpoint...');
        events = await _eventsService.fetchEvents(limit: 20);
        print('🔍 [EventsPage] Public events fetched successfully: ${events.length} events');
      } catch (e) {
        print('🔍 [EventsPage] Public events failed, trying user events: $e');
        // If public events fail, try user events
        events = await _eventsService.fetchUserEvents(
          userToken: _userToken,
          limit: 20,
        );
        print('🔍 [EventsPage] User events fetched successfully: ${events.length} events');
      }

      setState(() {
        _events = events;
        _filteredEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [EventsPage] Error fetching events: $e');
      setState(() {
        _error = 'Failed to load events: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEvents = _events;
      } else {
        _filteredEvents = _events.where((event) {
          return event.eventName.toLowerCase().contains(query.toLowerCase()) ||
                 event.organizer.toLowerCase().contains(query.toLowerCase()) ||
                 event.place.toLowerCase().contains(query.toLowerCase()) ||
                 event.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All') {
        _filteredEvents = _events;
      } else {
        _filteredEvents = _events.where((event) {
          return event.tags.any((tag) => 
            tag.toLowerCase().contains(category.toLowerCase()));
        }).toList();
      }
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
    // TODO: Implement circles functionality
  }

  void _onFilterPressed() {
    // TODO: Implement filter modal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Events'),
        content: Text('Filter functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onEventTap(EventModel event) {
    // Navigate to event details page
    Navigator.pushNamed(context, '/event/${event.id}');
  }

  Future<void> _registerForEvent(EventModel event) async {
    try {
      final success = await _eventsService.registerForEvent(
        event.id,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully registered for ${event.eventName}!')),
        );
        _fetchEvents(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register for event')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Events', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 54,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTab('Events', 0),
                ),
                Expanded(
                  child: _buildTab('Circles', 1),
                ),
              ],
            ),
          ),
          
          // Section title and filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Events',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                GestureDetector(
                  onTap: _onFilterPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Filter',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Blue separator line
          Container(
            height: 2,
            color: Colors.blue,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search events...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _categories.map((category) => 
                _buildCategoryChip(category, _selectedCategory == category)
              ).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Events list
          Expanded(
            child: _isLoading
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
                              onPressed: _fetchEvents,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredEvents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event, size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  _events.isEmpty ? 'No events available yet' : 'No events found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _events.isEmpty 
                                    ? 'Check back later for exciting events!'
                                    : 'Try adjusting your search or filters',
                                  style: TextStyle(color: Colors.grey[500]),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                if (_events.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Text(
                                      'Coming Soon!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredEvents.length,
                            itemBuilder: (context, index) {
                              return _buildEventCard(_filteredEvents[index]);
                            },
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
            // Already on events
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

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _onCategoryChanged(label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final dateStatus = event.getDateStatus();
    final dateStatusColor = event.getDateStatusColor();
    
    return GestureDetector(
      onTap: () => _onEventTap(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left indicator dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getEventColor(event),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            
            // Event details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(int.parse(dateStatusColor.replaceAll('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      dateStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Event title
                  Text(
                    event.eventName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Event details
                  Row(
                    children: [
                      Icon(Icons.circle, size: 4, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text(
                        event.getDistance(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        event.formattedTime,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Participant count
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Text(
                  event.attendeesCount.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEventColor(EventModel event) {
    // Generate a consistent color based on event tags or name
    final colors = [
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.blue,
      Colors.red,
      Colors.teal,
    ];
    
    final index = event.eventName.hashCode % colors.length;
    return colors[index];
  }
} 