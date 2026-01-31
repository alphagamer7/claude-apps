import 'package:flutter/material.dart';
import '../models/template.dart';
import '../models/trip.dart';
import '../services/database_service.dart';
import '../widgets/progress_bar.dart';
import 'checklist_screen.dart';
import 'template_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseService();
  List<Trip> _trips = [];
  List<Template> _templates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final trips = await _db.getTrips();
    final templates = await _db.getTemplates();
    setState(() {
      _trips = trips;
      _templates = templates;
      _loading = false;
    });
  }

  List<Trip> get _activeTrips =>
      _trips.where((t) => !t.isFullyPacked).toList();

  List<Trip> get _completedTrips =>
      _trips.where((t) => t.isFullyPacked).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PackList',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: _buildContent(),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFabOptions,
        backgroundColor: const Color(0xFF00BCD4),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContent() {
    if (_trips.isEmpty && _templates.isEmpty) {
      return const Center(
        child: Text(
          'No trips or templates yet.\nTap + to get started!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 16),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        if (_activeTrips.isNotEmpty) ...[
          _sectionHeader('Active Trips'),
          ..._activeTrips.map(_buildTripTile),
        ],
        if (_completedTrips.isNotEmpty) ...[
          _sectionHeader('Completed Trips'),
          ..._completedTrips.map(_buildTripTile),
        ],
        if (_templates.isNotEmpty) ...[
          _sectionHeader('Templates'),
          ..._templates.map(_buildTemplateTile),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF00BCD4),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTripTile(Trip trip) {
    return Dismissible(
      key: ValueKey('trip_${trip.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent.withValues(alpha: 0.3),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      confirmDismiss: (_) => _confirmDelete('trip'),
      onDismissed: (_) async {
        await _db.deleteTrip(trip.id!);
        _loadData();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        color: Colors.white.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF00BCD4).withValues(alpha: 0.15),
            child: Icon(
              trip.isFullyPacked ? Icons.check_circle : Icons.luggage,
              color: trip.isFullyPacked
                  ? Colors.greenAccent
                  : const Color(0xFF00BCD4),
            ),
          ),
          title: Text(
            trip.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: PackingProgressBar(
              checked: trip.checkedCount,
              total: trip.totalCount,
            ),
          ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChecklistScreen(tripId: trip.id!),
              ),
            );
            _loadData();
          },
        ),
      ),
    );
  }

  Widget _buildTemplateTile(Template template) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Colors.white.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00BCD4).withValues(alpha: 0.15),
          child: Icon(
            _templateIcon(template.iconName),
            color: const Color(0xFF00BCD4),
          ),
        ),
        title: Text(
          template.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${template.items.length} items',
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white38),
          color: const Color(0xFF2A2A2A),
          onSelected: (value) => _handleTemplateAction(value, template),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'start_trip',
              child: Text('Start Trip', style: TextStyle(color: Colors.white)),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit', style: TextStyle(color: Colors.white)),
            ),
            if (!template.isDefault)
              const PopupMenuItem(
                value: 'delete',
                child:
                    Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ),
          ],
        ),
        onTap: () => _createTripFromTemplate(template),
      ),
    );
  }

  void _handleTemplateAction(String action, Template template) async {
    switch (action) {
      case 'start_trip':
        _createTripFromTemplate(template);
        break;
      case 'edit':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TemplateEditorScreen(templateId: template.id),
          ),
        );
        _loadData();
        break;
      case 'delete':
        final confirmed = await _confirmDelete('template');
        if (confirmed == true) {
          await _db.deleteTemplate(template.id!);
          _loadData();
        }
        break;
    }
  }

  void _createTripFromTemplate(Template template) async {
    final name = await _showNameDialog('New Trip', 'Trip name',
        defaultValue: '${template.name} - Trip');
    if (name == null || name.isEmpty) return;

    await _db.createTripFromTemplate(name, template.id!);
    _loadData();
  }

  void _showFabOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF00BCD4),
                  child: Icon(Icons.luggage, color: Colors.white),
                ),
                title: const Text('New Trip from Template',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Pick a template to start packing',
                    style: TextStyle(color: Colors.white38)),
                onTap: () {
                  Navigator.pop(context);
                  _showTemplatePickerForTrip();
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF00BCD4).withValues(alpha: 0.3),
                  child:
                      const Icon(Icons.playlist_add, color: Color(0xFF00BCD4)),
                ),
                title: const Text('New Template',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Create a reusable packing list',
                    style: TextStyle(color: Colors.white38)),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TemplateEditorScreen(),
                    ),
                  );
                  _loadData();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplatePickerForTrip() {
    if (_templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No templates available. Create one first!')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Choose a Template',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ..._templates.map(
                (t) => ListTile(
                  leading: Icon(
                    _templateIcon(t.iconName),
                    color: const Color(0xFF00BCD4),
                  ),
                  title: Text(t.name,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${t.items.length} items',
                      style: const TextStyle(color: Colors.white38)),
                  onTap: () {
                    Navigator.pop(context);
                    _createTripFromTemplate(t);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showNameDialog(String title, String hint,
      {String defaultValue = ''}) async {
    final controller = TextEditingController(text: defaultValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00BCD4)),
            ),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create',
                style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(String type) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text('Delete $type?',
            style: const TextStyle(color: Colors.white)),
        content: Text('This action cannot be undone.',
            style: const TextStyle(color: Colors.white54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  IconData _templateIcon(String iconName) {
    switch (iconName) {
      case 'weekend':
        return Icons.weekend;
      case 'beach_access':
        return Icons.beach_access;
      case 'business_center':
        return Icons.business_center;
      case 'forest':
        return Icons.forest;
      case 'flight':
        return Icons.flight;
      default:
        return Icons.luggage;
    }
  }
}
