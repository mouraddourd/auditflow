import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/sync_service.dart';
import '../../hive/service.dart';
import '../../core/config/responsive_config.dart';

/// Écran de gestion des catégories permettant de créer, éditer et supprimer des catégories.
class CategoriesManagementScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const CategoriesManagementScreen({super.key, this.onBack});

  @override
  State<CategoriesManagementScreen> createState() =>
      _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState
    extends State<CategoriesManagementScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = HiveService().getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _seedDefaults() async {
    try {
      await HiveService().seedDefaultCategories();
      await _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Catégories par défaut ajoutées'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteCategory(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
            'Les templates utilisant cette catégorie ne seront pas supprimés, mais la catégorie sera retirée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await HiveService().deleteCategory(id);
      await _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Catégorie supprimée'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCategoryDialog({Map<String, dynamic>? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?['name'] ?? '');
    final descController =
        TextEditingController(text: category?['description'] ?? '');
    Color selectedColor = _parseColor(category?['color']);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title:
              Text(isEditing ? 'Modifier la catégorie' : 'Nouvelle catégorie'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    prefixIcon: Icon(FontAwesomeIcons.tag),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(FontAwesomeIcons.alignLeft),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Text('Couleur', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presetColors.map((color) {
                    final isSelected = selectedColor.value == color.value;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                      color: color.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2)
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le nom est requis')),
                  );
                  return;
                }

                try {
                  if (isEditing) {
                    await HiveService().updateCategory(
                      id: category['id'],
                      name: nameController.text.trim(),
                      description: descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                      color:
                          '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
                    );

                    // Enqueue sync
                    await SyncService().enqueue(
                      entityType: 'category',
                      entityId: category['id'],
                      mutationType: MutationType.update,
                      data: HiveService().getCategories().firstWhere(
                            (c) => c['id'] == category['id'],
                            orElse: () => category,
                          ),
                    );
                  } else {
                    final created = await HiveService().createCategory(
                      name: nameController.text.trim(),
                      description: descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                      color:
                          '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
                    );

                    await SyncService().enqueue(
                      entityType: 'category',
                      entityId: created['id'],
                      mutationType: MutationType.create,
                      data: created,
                    );
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadCategories();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing
                            ? 'Catégorie modifiée'
                            : 'Catégorie créée'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Erreur: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Modifier' : 'Créer'),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return Colors.blue;
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  static final List<Color> _presetColors = [
    const Color(0xFF4CAF50), // Green
    const Color(0xFFF44336), // Red
    const Color(0xFF2196F3), // Blue
    const Color(0xFFFF9800), // Orange
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF607D8B), // Blue Grey
    const Color(0xFF795548), // Brown
    const Color(0xFFE91E63), // Pink
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF8BC34A), // Light Green
    const Color(0xFFFFEB3B), // Yellow
    const Color(0xFF3F51B5), // Indigo
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
        title: const Text('Gestion des Catégories'),
        actions: [
          if (_categories.isEmpty)
            TextButton.icon(
              onPressed: _seedDefaults,
              icon: const Icon(FontAwesomeIcons.wandMagicSparkles, size: 16),
              label: const Text('Par défaut'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? _buildEmptyState(theme)
              : _buildCategoriesList(theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        icon: const Icon(FontAwesomeIcons.plus),
        label: const Text('Nouvelle catégorie'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FontAwesomeIcons.tags, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune catégorie',
            style:
                theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez des catégories pour organiser vos templates',
            style:
                theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showCategoryDialog(),
                icon: const Icon(FontAwesomeIcons.plus),
                label: const Text('Créer une catégorie'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _seedDefaults,
                icon: const Icon(FontAwesomeIcons.wandMagicSparkles),
                label: const Text('Utiliser les défauts'),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildCategoriesList(ThemeData theme) {
    return ListView.builder(
      padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final color = _parseColor(category['color']);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(FontAwesomeIcons.tag, color: color),
            ),
            title: Text(
              category['name'] as String? ?? 'Sans nom',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: category['description'] != null
                ? Text(
                    category['description'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(FontAwesomeIcons.penToSquare, size: 18),
                  onPressed: () => _showCategoryDialog(category: category),
                  tooltip: 'Modifier',
                ),
                IconButton(
                  icon: const Icon(FontAwesomeIcons.trash,
                      size: 18, color: Colors.red),
                  onPressed: () => _deleteCategory(category['id'] as String),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 50 * index))
            .slideX(begin: 0.1);
      },
    );
  }
}
