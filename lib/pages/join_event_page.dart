import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/events_service.dart';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'confirmation_page.dart';

class JoinEventPage extends StatefulWidget {
  final EventModel event;

  const JoinEventPage({Key? key, required this.event}) : super(key: key);

  @override
  _JoinEventPageState createState() => _JoinEventPageState();
}

class _JoinEventPageState extends State<JoinEventPage> {
  int _attendeeCount = 1;
  bool _isLoading = false;
  final EventsService _eventsService = EventsService();
  
  // Pricing and discount selection
  PricingOption? _selectedPricingOption;
  DiscountOption? _selectedDiscountOption;
  
  // Computed values
  double get _basePrice => _selectedPricingOption?.price ?? 0.0;
  double get _discountAmount => _selectedDiscountOption != null 
      ? (_basePrice * _attendeeCount * _selectedDiscountOption!.percentageDiscount / 100)
      : 0.0;
  double get _totalPrice => (_basePrice * _attendeeCount) - _discountAmount;
  
  // Available discounts based on attendee count
  List<DiscountOption> get _availableDiscounts {
    return widget.event.discountOptions.where((discount) {
      return _attendeeCount >= discount.totalMembersNeeded;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _checkSessionState();
    // Set default pricing option
    if (widget.event.pricing.isNotEmpty) {
      _selectedPricingOption = widget.event.pricing.first;
    }
  }

  Future<void> _checkSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    final userToken = prefs.getString('userToken');
    final currentUserId = prefs.getString('current_user_id');
    
    print('🔍 [JoinEventPage] Session check:');
    print('🔍 [JoinEventPage] User token: ${userToken != null ? "Present" : "Not present"}');
    print('🔍 [JoinEventPage] Current user ID: ${currentUserId ?? "Not present"}');
    
    if (userToken != null) {
      print('🔍 [JoinEventPage] Token preview: ${userToken.substring(0, 20)}...');
    } else {
      print('🔍 [JoinEventPage] No token found - user needs to log in again');
    }
  }

  Future<void> _clearSessionAndGoToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    await prefs.remove('userToken');
    print('🔍 [JoinEventPage] Cleared session, redirecting to login');
    
    // Navigate to login page
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[600]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Join ${widget.event.eventName}',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.grey[600]),
            onPressed: () {
              // Profile action
            },
          ),
          // Debug button for testing
          IconButton(
            icon: Icon(Icons.bug_report, color: Colors.orange),
            onPressed: _clearSessionAndGoToLogin,
            tooltip: 'Debug: Clear session and go to login',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Summary Card
            _buildEventSummaryCard(),
            const SizedBox(height: 24),
            
            // Number of Attendees Section
            _buildAttendeesSection(),
            const SizedBox(height: 24),
            
            // Pricing Tier Section
            _buildPricingSection(),
            const SizedBox(height: 24),
            
            // Discount Section
            _buildDiscountSection(),
            const SizedBox(height: 24),
            
            // Event Details Section
            _buildEventDetailsSection(),
            const SizedBox(height: 24),
            
            // Important Note
            _buildImportantNote(),
            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: _buildProceedButton(),
    );
  }

  Widget _buildEventSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.event.getDateStatus()}, ${widget.event.formattedTime}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.event.place,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.event.getDistance(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number of Attendees',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _attendeeCount > 1 ? () {
                  setState(() {
                    _attendeeCount--;
                    // Reset discount selection if it's no longer available
                    if (_selectedDiscountOption != null && 
                        _attendeeCount < _selectedDiscountOption!.totalMembersNeeded) {
                      _selectedDiscountOption = null;
                    }
                  });
                } : null,
                icon: Icon(
                  Icons.remove,
                  color: _attendeeCount > 1 ? Colors.grey[600] : Colors.grey[300],
                ),
              ),
              Text(
                '$_attendeeCount',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              IconButton(
                onPressed: _attendeeCount < widget.event.availableSlots ? () {
                  setState(() {
                    _attendeeCount++;
                    // Reset discount selection if it's no longer available
                    if (_selectedDiscountOption != null && 
                        _attendeeCount < _selectedDiscountOption!.totalMembersNeeded) {
                      _selectedDiscountOption = null;
                    }
                  });
                } : null,
                icon: Icon(
                  Icons.add,
                  color: _attendeeCount < widget.event.availableSlots ? Colors.grey[600] : Colors.grey[300],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select number of spots to reserve (you + guests).',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Pricing Tier',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.event.pricing.map((pricingOption) => _buildPricingOptionCard(pricingOption)),
      ],
    );
  }

  Widget _buildPricingOptionCard(PricingOption pricingOption) {
    final isSelected = _selectedPricingOption?.name == pricingOption.name;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPricingOption = pricingOption;
          // Reset discount selection when pricing changes
          _selectedDiscountOption = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.purple : Colors.grey[300],
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pricingOption.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.purple : Colors.black,
                    ),
                  ),
                  if (pricingOption.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      pricingOption.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '\$${pricingOption.price.toStringAsFixed(2)} per person',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.purple : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountSection() {
    if (widget.event.discountOptions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Discounts',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        if (_availableDiscounts.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No discounts available for $_attendeeCount attendee${_attendeeCount == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          )
        else
          ..._availableDiscounts.map((discount) => _buildDiscountOptionCard(discount)),
        const SizedBox(height: 16),
        _buildPriceSummary(),
      ],
    );
  }

  Widget _buildDiscountOptionCard(DiscountOption discount) {
    final isSelected = _selectedDiscountOption?.name == discount.name;
    final isAvailable = _attendeeCount >= discount.totalMembersNeeded;
    
    return GestureDetector(
      onTap: isAvailable ? () {
        setState(() {
          _selectedDiscountOption = isSelected ? null : discount;
        });
      } : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.green : Colors.grey[300],
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    discount.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.green : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${discount.percentageDiscount}% off for ${discount.totalMembersNeeded}+ people',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Save \$${_discountAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Base Price (${_attendeeCount}x)',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                '\$${(_basePrice * _attendeeCount).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          if (_selectedDiscountOption != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discount (${_selectedDiscountOption!.percentageDiscount}%)',
                  style: const TextStyle(fontSize: 14, color: Colors.green),
                ),
                Text(
                  '-\$${_discountAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14, color: Colors.green),
                ),
              ],
            ),
          ],
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${_totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Details',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        
        // Price badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'FREE',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Duration
        Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey[600], size: 16),
            const SizedBox(width: 8),
            Text(
              widget.event.duration,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Provided items
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 12,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Gloves provided',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Required items
        Row(
          children: [
            const SizedBox(width: 16),
            const SizedBox(width: 8),
            const Text(
              'Bring water & sun protection',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImportantNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Please arrive 10 minutes early for check-in and safety briefing.',
        style: TextStyle(
          fontSize: 14,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildProceedButton() {
    return Container(
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
          onPressed: _isLoading ? null : _proceedToRegistration,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Proceed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _proceedToRegistration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the selected pricing tier name
      final pricingTierName = _selectedPricingOption?.name ?? 'Standard';
      
      // First, register for the event
      final registrationSuccess = await _eventsService.registerForEvent(
        widget.event.id,
        pricingTierName: pricingTierName,
        attendeeCount: _attendeeCount,
      );
      
      if (registrationSuccess) {
        // Navigate to confirmation page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationPage(event: widget.event),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to register for event')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 