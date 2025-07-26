/// Event model for the Saath app
///
/// This file contains the Event model class that represents
/// event data from the backend API.

class EventModel {
  final String id;
  final String eventName;
  final DateTime date;
  final EventTime eventTime;
  final String place;
  final List<String> tags;
  final String? image;
  final List<PricingOption> pricing;
  final List<DiscountOption> discountOptions;
  final String organizer;
  final String description;
  final String duration;
  final int maxAttendees;
  final int availableSlots;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int attendeesCount;
  final PriceRange priceRange;
  final bool isRegistered;
  final String formattedDate;
  final String formattedTime;

  EventModel({
    required this.id,
    required this.eventName,
    required this.date,
    required this.eventTime,
    required this.place,
    required this.tags,
    this.image,
    required this.pricing,
    required this.discountOptions,
    required this.organizer,
    required this.description,
    required this.duration,
    required this.maxAttendees,
    required this.availableSlots,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.attendeesCount,
    required this.priceRange,
    required this.isRegistered,
    required this.formattedDate,
    required this.formattedTime,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['_id'] ?? '',
      eventName: json['eventName'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      eventTime: EventTime.fromJson(json['eventTime'] ?? {}),
      place: json['place'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      image: json['image'],
      pricing: (json['pricing'] as List<dynamic>? ?? [])
          .map((p) => PricingOption.fromJson(p))
          .toList(),
      discountOptions: (json['discountOptions'] as List<dynamic>? ?? [])
          .map((d) => DiscountOption.fromJson(d))
          .toList(),
      organizer: json['organizer'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? '',
      maxAttendees: json['maxAttendees'] ?? 0,
      availableSlots: json['availableSlots'] ?? 0,
      status: json['status'] ?? 'draft',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      attendeesCount: json['attendeesCount'] ?? 0,
      priceRange: PriceRange.fromJson(json['priceRange'] ?? {}),
      isRegistered: json['isRegistered'] ?? false,
      formattedDate: json['formattedDate'] ?? '',
      formattedTime: json['formattedTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'eventName': eventName,
      'date': date.toIso8601String(),
      'eventTime': eventTime.toJson(),
      'place': place,
      'tags': tags,
      'image': image,
      'pricing': pricing.map((p) => p.toJson()).toList(),
      'discountOptions': discountOptions.map((d) => d.toJson()).toList(),
      'organizer': organizer,
      'description': description,
      'duration': duration,
      'maxAttendees': maxAttendees,
      'availableSlots': availableSlots,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'attendeesCount': attendeesCount,
      'priceRange': priceRange.toJson(),
      'isRegistered': isRegistered,
      'formattedDate': formattedDate,
      'formattedTime': formattedTime,
    };
  }

  // Helper method to get date status (TODAY, TOM, SAT, etc.)
  String getDateStatus() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);
    final difference = eventDate.difference(today).inDays;

    if (difference == 0) return 'TODAY';
    if (difference == 1) return 'TOM';
    if (difference == 2) return 'SAT';
    if (difference == 3) return 'SUN';
    if (difference == 4) return 'MON';
    if (difference == 5) return 'TUE';
    if (difference == 6) return 'WED';
    if (difference == 7) return 'THU';
    if (difference == 8) return 'FRI';
    
    return date.day.toString();
  }

  // Helper method to get date status color
  String getDateStatusColor() {
    final status = getDateStatus();
    switch (status) {
      case 'TODAY':
        return '#3B82F6'; // Blue
      case 'TOM':
        return '#8B5CF6'; // Purple
      case 'SAT':
      case 'SUN':
        return '#10B981'; // Green
      default:
        return '#6B7280'; // Gray
    }
  }

  // Helper method to get distance (placeholder - would come from location API)
  String getDistance() {
    // This would be calculated based on user's location
    // For now, return a placeholder
    return '2.5 km away';
  }
}

class EventTime {
  final String from;
  final String to;

  EventTime({required this.from, required this.to});

  factory EventTime.fromJson(Map<String, dynamic> json) {
    return EventTime(
      from: json['from'] ?? '',
      to: json['to'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
    };
  }
}

class PricingOption {
  final String name;
  final String description;
  final double price;
  final List<String> tags;
  final int slotsAvailable;

  PricingOption({
    required this.name,
    required this.description,
    required this.price,
    required this.tags,
    required this.slotsAvailable,
  });

  factory PricingOption.fromJson(Map<String, dynamic> json) {
    return PricingOption(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      tags: List<String>.from(json['tags'] ?? []),
      slotsAvailable: json['slotsAvailable'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'tags': tags,
      'slotsAvailable': slotsAvailable,
    };
  }
}

class DiscountOption {
  final String name;
  final int totalMembersNeeded;
  final int percentageDiscount;

  DiscountOption({
    required this.name,
    required this.totalMembersNeeded,
    required this.percentageDiscount,
  });

  factory DiscountOption.fromJson(Map<String, dynamic> json) {
    return DiscountOption(
      name: json['name'] ?? '',
      totalMembersNeeded: json['totalMembersNeeded'] ?? 0,
      percentageDiscount: json['percentageDiscount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'totalMembersNeeded': totalMembersNeeded,
      'percentageDiscount': percentageDiscount,
    };
  }
}

class PriceRange {
  final double min;
  final double max;
  final String currency;

  PriceRange({
    required this.min,
    required this.max,
    required this.currency,
  });

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      min: (json['min'] ?? 0).toDouble(),
      max: (json['max'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
      'currency': currency,
    };
  }
} 