import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Invitation data model
class Invitation {
  final String id;
  final String email;
  final String organizationId;
  final String organizationName;
  final String invitedBy;
  final String invitedByName;
  final String token;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  Invitation({
    required this.id,
    required this.email,
    required this.organizationId,
    required this.organizationName,
    required this.invitedBy,
    required this.invitedByName,
    required this.token,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    this.acceptedAt,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'] as String,
      email: json['email'] as String,
      organizationId: json['organizationId'] as String,
      organizationName: json['organization']?['name'] as String? ?? '',
      invitedBy: json['invitedBy'] as String,
      invitedByName: json['invitedByUser']?['name'] as String? ?? '',
      token: json['token'] as String,
      status: json['status'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : null,
    );
  }

  /// Check if invitation is expired
  bool get isExpired => expiresAt.isBefore(DateTime.now());

  /// Check if invitation is pending
  bool get isPending => status == 'pending' && !isExpired;
}

/// Invitation info for display before login/register
class InvitationInfo {
  final String id;
  final String email;
  final String organizationId;
  final String organizationName;
  final String invitedByName;
  final DateTime expiresAt;

  InvitationInfo({
    required this.id,
    required this.email,
    required this.organizationId,
    required this.organizationName,
    required this.invitedByName,
    required this.expiresAt,
  });

  factory InvitationInfo.fromJson(Map<String, dynamic> json) {
    return InvitationInfo(
      id: json['id'] as String,
      email: json['email'] as String,
      organizationId: json['organization']['id'] as String,
      organizationName: json['organization']['name'] as String,
      invitedByName: json['invitedBy']?['name'] as String? ?? '',
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  bool get isExpired => expiresAt.isBefore(DateTime.now());
}

/// Service for managing organization invitations
class InvitationService {
  static final InvitationService _instance = InvitationService._internal();
  factory InvitationService() => _instance;
  InvitationService._internal();

  final ApiService _api = ApiService();

  /// Create an invitation to join an organization
  Future<Invitation> createInvitation({
    required String organizationId,
    required String email,
  }) async {
    try {
      final response = await _api.dio.post(
        '/organizations/$organizationId/invitations',
        data: {'email': email},
      );

      if (response.data['success'] == true) {
        return Invitation.fromJson(response.data['data']);
      }
      throw Exception(response.data['error'] ?? 'Failed to create invitation');
    } catch (e) {
      debugPrint('InvitationService: Error creating invitation: $e');
      rethrow;
    }
  }

  /// Get invitation info by token (public, no auth required)
  Future<InvitationInfo> getInvitationInfo(String token) async {
    try {
      final response = await _api.dio.get('/invitations/$token/info');

      if (response.data['success'] == true) {
        return InvitationInfo.fromJson(response.data['data']);
      }
      throw Exception(response.data['error'] ?? 'Invitation not found');
    } catch (e) {
      debugPrint('InvitationService: Error getting invitation info: $e');
      rethrow;
    }
  }

  /// Accept an invitation and join organization
  Future<Map<String, dynamic>> acceptInvitation(String token) async {
    try {
      final response = await _api.dio.post('/organizations/join/$token');

      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['error'] ?? 'Failed to accept invitation');
    } catch (e) {
      debugPrint('InvitationService: Error accepting invitation: $e');
      rethrow;
    }
  }

  /// List invitations for an organization (admin only)
  Future<List<Invitation>> getOrganizationInvitations(
    String organizationId,
  ) async {
    try {
      final response = await _api.dio.get(
        '/organizations/$organizationId/invitations',
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Invitation.fromJson(json)).toList();
      }
      throw Exception(response.data['error'] ?? 'Failed to get invitations');
    } catch (e) {
      debugPrint('InvitationService: Error getting invitations: $e');
      rethrow;
    }
  }

  /// Delete/cancel an invitation (admin only)
  Future<void> deleteInvitation(String invitationId) async {
    try {
      final response = await _api.dio.delete('/invitations/$invitationId');

      if (response.data['success'] != true) {
        throw Exception(
            response.data['error'] ?? 'Failed to delete invitation');
      }
    } catch (e) {
      debugPrint('InvitationService: Error deleting invitation: $e');
      rethrow;
    }
  }

  /// Generate shareable invitation link
  String getInvitationLink(String token) {
    return 'auditflow://join/$token';
  }

  /// Generate web fallback link
  String getWebInvitationLink(String token) {
    return 'https://auditflow.duckdns.org/join/$token';
  }
}
