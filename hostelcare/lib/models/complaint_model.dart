class ComplaintModel {
  final String id;
  final String? complaintId;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final Map<String, dynamic>? submittedBy;
  final Map<String, dynamic>? assignedTo;
  final Map<String, dynamic> location;
  final List<Map<String, dynamic>> images;
  final List<Map<String, dynamic>> completionImages;
  final String? resolutionNotes;
  final Map<String, dynamic>? feedback;
  final List<Map<String, dynamic>> statusHistory;
  final String? createdAt;
  final String? resolvedAt;
  final bool isOfflineSubmission;
  final bool qrScanned;

  ComplaintModel({
    required this.id,
    this.complaintId,
    required this.title,
    required this.description,
    required this.category,
    this.priority = 'medium',
    this.status = 'pending',
    this.submittedBy,
    this.assignedTo,
    required this.location,
    this.images = const [],
    this.completionImages = const [],
    this.resolutionNotes,
    this.feedback,
    this.statusHistory = const [],
    this.createdAt,
    this.resolvedAt,
    this.isOfflineSubmission = false,
    this.qrScanned = false,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['_id'] ?? json['id'] ?? '',
      complaintId: json['complaintId'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'other',
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'pending',
      submittedBy: json['submittedBy'] is Map ? json['submittedBy'] : null,
      assignedTo: json['assignedTo'] is Map ? json['assignedTo'] : null,
      location: Map<String, dynamic>.from(json['location'] ?? {}),
      images: (json['images'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      completionImages: (json['completionImages'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      resolutionNotes: json['resolutionNotes'],
      feedback: json['feedback'] is Map ? Map<String, dynamic>.from(json['feedback']) : null,
      statusHistory: (json['statusHistory'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      createdAt: json['createdAt'],
      resolvedAt: json['resolvedAt'],
      isOfflineSubmission: json['isOfflineSubmission'] ?? false,
      qrScanned: json['qrScanned'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title, 'description': description, 'category': category,
    'priority': priority, 'location': location,
    'isOfflineSubmission': isOfflineSubmission, 'qrScanned': qrScanned,
  };

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Pending';
      case 'assigned': return 'Assigned';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'closed': return 'Closed';
      default: return status;
    }
  }

  String get categoryIcon {
    switch (category) {
      case 'electrical': return '⚡';
      case 'water': return '💧';
      case 'internet': return '🌐';
      case 'cleaning': return '🧹';
      case 'furniture': return '🪑';
      case 'security': return '🔒';
      default: return '📋';
    }
  }
}
