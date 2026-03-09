import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../hive/service.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'licenseTier': licenseTier,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'userRole': userRole,
    };
  }

  bool get isOwner => userRole == 'owner';
  bool get isAdmin => userRole == 'admin' || userRole == 'owner';
}

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

class OrganizationProvider extends ChangeNotifier {
  static const String _activeOrgKey = 'active_organization_id';

  List<Organization> _organizations = [];
  Organization? _activeOrganization;
  bool _isLoading = false;
  String? _error;

  List<Organization> get organizations => _organizations;
  Organization? get activeOrganization => _activeOrganization;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasOrganization => _organizations.isNotEmpty;
  bool get hasActiveOrganization => _activeOrganization != null;

  Future<void> initialize(String userId, String token) async {
    _isLoading = true;
    _error = null;
    // Note: Ne pas appeler notifyListeners() ici car cette méthode est appelée pendant initState

    try {
      final hiveService = HiveService();

      // Load organizations from Hive (already saved during login)
      final orgs = hiveService.getOrganizations();
      _organizations = orgs.map((e) => Organization.fromJson(e)).toList();

      debugPrint('Loaded ${_organizations.length} organizations from Hive');

      final prefs = await SharedPreferences.getInstance();
      final savedOrgId = prefs.getString(_activeOrgKey);

      if (savedOrgId != null && _organizations.isNotEmpty) {
        try {
          _activeOrganization = _organizations.firstWhere(
            (org) => org.id == savedOrgId,
          );
        } catch (_) {
          _activeOrganization = _organizations.first;
          await prefs.setString(_activeOrgKey, _activeOrganization!.id);
        }
      } else if (_organizations.isNotEmpty) {
        _activeOrganization = _organizations.first;
        await prefs.setString(_activeOrgKey, _activeOrganization!.id);
      }

      if (_activeOrganization != null) {
        hiveService.setOrganization(_activeOrganization!.id);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading organizations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Organization?> createOrganization(
      String name, String userId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Create organization via API
      final response = await Dio().post(
        ApiConfig.organizations,
        data: {'name': name},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-user-id': userId,
          },
        ),
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        final orgData = response.data['data'] as Map<String, dynamic>;
        final org = Organization.fromJson(orgData);

        // Save to Hive
        final hiveService = HiveService();
        await hiveService.saveOrganization(org.toJson());

        _organizations.insert(0, org);
        _activeOrganization = org;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_activeOrgKey, org.id);

        hiveService.setOrganization(org.id);

        notifyListeners();
        return org;
      } else {
        _error = response.data['error'] ?? 'Erreur lors de la création';
      }
    } on DioException catch (e) {
      _error = e.response?.data?['error'] ?? 'Erreur de connexion';
      debugPrint('Error creating organization: ${e.message}');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating organization: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<void> setActiveOrganization(Organization org) async {
    _activeOrganization = org;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeOrgKey, org.id);

    HiveService().setOrganization(org.id);

    notifyListeners();
  }

  Future<void> clear() async {
    _organizations = [];
    _activeOrganization = null;
    _error = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeOrgKey);

    notifyListeners();
  }
}
