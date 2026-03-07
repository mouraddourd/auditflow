import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../powersync/service.dart';
import '../config/api_config.dart';

/// Organization model
class Organization {
  final String id;
  final String name;
  final String slug;
  final String? licenseTier;
  final String createdAt;
  final String updatedAt;
  final String userRole;

  Organization({
    required this.id,
    required this.name,
    required this.slug,
    this.licenseTier,
    required this.createdAt,
    required this.updatedAt,
    required this.userRole,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      licenseTier: json['licenseTier'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      userRole: json['userRole'] ?? 'member',
    );
  }

  bool get isOwner => userRole == 'owner';
  bool get isAdmin => userRole == 'admin' || userRole == 'owner';
}

/// Organization member model
class OrganizationMember {
  final String id;
  final String userId;
  final String organizationId;
  final String role;
  final String joinedAt;
  final String? userName;
  final String? userEmail;

  OrganizationMember({
    required this.id,
    required this.userId,
    required this.organizationId,
    required this.role,
    required this.joinedAt,
    this.userName,
    this.userEmail,
  });

  factory OrganizationMember.fromJson(Map<String, dynamic> json) {
    return OrganizationMember(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      organizationId: json['organizationId'] ?? '',
      role: json['role'] ?? 'member',
      joinedAt: json['joinedAt'] ?? '',
      userName: json['user']?['name'],
      userEmail: json['user']?['email'],
    );
  }
}

/// Invitation model
class Invitation {
  final String id;
  final String email;
  final String organizationId;
  final String token;
  final String status;
  final String expiresAt;
  final String createdAt;

  Invitation({
    required this.id,
    required this.email,
    required this.organizationId,
    required this.token,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      organizationId: json['organizationId'] ?? '',
      token: json['token'] ?? '',
      status: json['status'] ?? 'pending',
      expiresAt: json['expiresAt'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

/// Organization provider for state management
class OrganizationProvider extends ChangeNotifier {
  static const String _activeOrgKey = 'active_organization_id';

  final Dio _dio;

  List<Organization> _organizations = [];
  Organization? _activeOrganization;
  bool _isLoading = false;
  String? _error;

  OrganizationProvider({Dio? dio}) : _dio = dio ?? Dio();

  List<Organization> get organizations => _organizations;
  Organization? get activeOrganization => _activeOrganization;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasOrganization => _organizations.isNotEmpty;
  bool get hasActiveOrganization => _activeOrganization != null;

  /// Initialize - load organizations and restore active org
  Future<void> initialize(String userId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dio.options.headers['x-user-id'] = userId;
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final orgsUrl = await ApiConfig.getOrganizationsUrl();
      final response = await _dio.get(orgsUrl);

      if (response.data['success'] == true) {
        final List<dynamic> orgsData = response.data['data'] ?? [];
        _organizations = orgsData
            .map((json) => Organization.fromJson(json as Map<String, dynamic>))
            .toList();

        // Restore active org from storage
        final prefs = await SharedPreferences.getInstance();
        final savedOrgId = prefs.getString(_activeOrgKey);

        if (savedOrgId != null) {
          _activeOrganization = _organizations.firstWhere(
            (org) => org.id == savedOrgId,
            orElse: () => _organizations.isNotEmpty
                ? _organizations.first
                : throw StateError('No org'),
          );
        } else if (_organizations.isNotEmpty) {
          _activeOrganization = _organizations.first;
          await prefs.setString(_activeOrgKey, _activeOrganization!.id);
        }

        // Sync with PowerSyncService
        if (_activeOrganization != null) {
          PowerSyncService().setOrganization(_activeOrganization!.id);
        }
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading organizations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new organization
  Future<Organization?> createOrganization(
      String name, String userId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dio.options.headers['x-user-id'] = userId;
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final orgsUrl = await ApiConfig.getOrganizationsUrl();
      final response = await _dio.post(
        orgsUrl,
        data: {'name': name},
      );

      if (response.data['success'] == true) {
        final org = Organization.fromJson(response.data['data']);
        _organizations.insert(0, org);
        _activeOrganization = org;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_activeOrgKey, org.id);

        // Sync with PowerSyncService
        PowerSyncService().setOrganization(org.id);

        notifyListeners();
        return org;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating organization: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  /// Join an organization via invitation token
  Future<Organization?> joinOrganization(
      String token, String userId, String authToken) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dio.options.headers['x-user-id'] = userId;
      _dio.options.headers['Authorization'] = 'Bearer $authToken';

      final joinUrl = await ApiConfig.getOrganizationsUrl();
      final response = await _dio.post(
        '$joinUrl/join/$token',
      );

      if (response.data['success'] == true) {
        final org = Organization.fromJson(response.data['data']);
        _organizations.insert(0, org);
        _activeOrganization = org;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_activeOrgKey, org.id);

        // Sync with PowerSyncService
        PowerSyncService().setOrganization(org.id);

        notifyListeners();
        return org;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error joining organization: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  /// Set active organization
  Future<void> setActiveOrganization(Organization org) async {
    _activeOrganization = org;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeOrgKey, org.id);

    // Sync with PowerSyncService
    PowerSyncService().setOrganization(org.id);

    notifyListeners();
  }

  /// Invite a member to the active organization
  Future<bool> inviteMember(String email, String userId, String token) async {
    if (_activeOrganization == null) return false;

    try {
      _dio.options.headers['x-user-id'] = userId;
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final orgsUrl = await ApiConfig.getOrganizationsUrl();
      final response = await _dio.post(
        '$orgsUrl/${_activeOrganization!.id}/invite',
        data: {'email': email},
      );

      return response.data['success'] == true;
    } catch (e) {
      debugPrint('Error inviting member: $e');
      return false;
    }
  }

  /// Clear organization data (logout)
  Future<void> clear() async {
    _organizations = [];
    _activeOrganization = null;
    _error = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeOrgKey);

    notifyListeners();
  }
}
