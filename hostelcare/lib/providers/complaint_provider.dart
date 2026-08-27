import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/complaint_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

import 'package:image_picker/image_picker.dart' show XFile;

class ComplaintProvider extends ChangeNotifier {
  List<ComplaintModel> _complaints = [];
  ComplaintModel? _selectedComplaint;
  bool _isLoading = false;
  String? _error;
  int _totalPages = 1;
  int _currentPage = 1;

  List<ComplaintModel> get complaints => _complaints;
  ComplaintModel? get selectedComplaint => _selectedComplaint;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalPages => _totalPages;
  int get currentPage => _currentPage;

  Future<void> fetchComplaints({String? status, String? category, bool? isCommonArea, int page = 1}) async {
    _isLoading = true;
    notifyListeners();
    try {
      String url = '${ApiConstants.complaints}?page=$page&limit=20';
      if (status != null) url += '&status=$status';
      if (category != null) url += '&category=$category';
      if (isCommonArea == true) url += '&isCommonArea=true';
      final res = await ApiService.get(url);
      final list = (res['data'] as List).map((e) => ComplaintModel.fromJson(e)).toList();
      if (page == 1) { _complaints = list; } else { _complaints.addAll(list); }
      _totalPages = res['pagination']?['pages'] ?? 1;
      _currentPage = page;
      _error = null;
    } catch (e) { _error = e.toString(); }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchComplaintDetail(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.get('${ApiConstants.complaints}/$id');
      _selectedComplaint = ComplaintModel.fromJson(res['data']);
      _error = null;
    } catch (e) { _error = e.toString(); }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitComplaint({
    required String title,
    required String description,
    required String category,
    required String hostelBlock,
    required String roomNumber,
    String? floor,
    String priority = 'medium',
    List<XFile>? images,
    bool qrScanned = false,
    bool isCommonArea = false,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final fields = {
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        'qrScanned': qrScanned.toString(),
        'isCommonArea': isCommonArea.toString(),
        'location': jsonEncode({'hostelBlock': hostelBlock, 'roomNumber': roomNumber, 'floor': floor ?? ''}),
      };
      await ApiService.multipartPost(ApiConstants.complaints, fields: fields, files: images);
      await fetchComplaints();
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleUpvote(String complaintId) async {
    try {
      final res = await ApiService.put('${ApiConstants.complaints}/$complaintId/upvote', {});
      final updated = ComplaintModel.fromJson(res['data']);
      final index = _complaints.indexWhere((c) => c.id == complaintId);
      if (index > -1) {
        _complaints[index] = updated;
      }
      if (_selectedComplaint?.id == complaintId) {
        _selectedComplaint = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitFeedback(String complaintId, int rating, String comment) async {
    try {
      await ApiService.put('${ApiConstants.complaints}/$complaintId/feedback', {'rating': rating, 'comment': comment});
      await fetchComplaintDetail(complaintId);
      return true;
    } catch (e) { _error = e.toString(); notifyListeners(); return false; }
  }

  Future<bool> withdrawComplaint(String complaintId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await ApiService.put('${ApiConstants.complaints}/$complaintId/withdraw', {});
      await fetchComplaints();
      if (_selectedComplaint?.id == complaintId) {
        await fetchComplaintDetail(complaintId);
      }
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Offline support
  Future<void> saveOfflineComplaint(Map<String, dynamic> complaint) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(AppConstants.offlineComplaintsKey) ?? [];
    stored.add(jsonEncode(complaint));
    await prefs.setStringList(AppConstants.offlineComplaintsKey, stored);
  }

  Future<void> syncOfflineComplaints() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(AppConstants.offlineComplaintsKey) ?? [];
    if (stored.isEmpty) return;
    try {
      final complaints = stored.map((e) => jsonDecode(e)).toList();
      await ApiService.post('${ApiConstants.complaints}/sync', {'complaints': complaints});
      await prefs.remove(AppConstants.offlineComplaintsKey);
      await fetchComplaints();
    } catch (e) { _error = e.toString(); notifyListeners(); }
  }

  void clearError() { _error = null; notifyListeners(); }
}
