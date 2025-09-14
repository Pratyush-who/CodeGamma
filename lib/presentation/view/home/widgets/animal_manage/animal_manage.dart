import 'package:codegamma_sih/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AnimalManagementScreen extends StatefulWidget {
  const AnimalManagementScreen({super.key});

  @override
  State<AnimalManagementScreen> createState() => _AnimalManagementScreenState();
}

class _AnimalManagementScreenState extends State<AnimalManagementScreen> {
  List<Animal> _animals = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAnimals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAnimals() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://8f2wld3k-8001.inc1.devtunnels.ms/database/animals?limit=1000'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _animals = data.map((json) => Animal.fromJson(json)).toList();
        });
      }
    } catch (e) {
      _showSnackBar('Failed to fetch animals: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addAnimal(Animal animal) async {
    try {
      final response = await http.post(
        Uri.parse('https://8f2wld3k-8001.inc1.devtunnels.ms/database/animals'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(animal.toJson()),
      );

      if (response.statusCode == 200) {
        _fetchAnimals();
        _showSnackBar('Animal added successfully');
      }
    } catch (e) {
      _showSnackBar('Failed to add animal: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddAnimalDialog() {
    showDialog(
      context: context,
      builder: (context) => AddAnimalDialog(onSave: _addAnimal),
    );
  }

  List<Animal> get _filteredAnimals {
    if (_searchQuery.isEmpty) return _animals;
    return _animals.where((animal) {
      return animal.tagNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          animal.breed.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          animal.farmId.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Animal Management',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search animals by tag, breed, or farm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
              ),
            ),
          ),

          // Animals List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchAnimals,
                    child: _filteredAnimals.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredAnimals.length,
                            itemBuilder: (context, index) {
                              final animal = _filteredAnimals[index];
                              return AnimalCard(animal: animal);
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAnimalDialog,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Animal'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No animals found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first animal to get started',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// Animal Card Widget
class AnimalCard extends StatelessWidget {
  final Animal animal;

  const AnimalCard({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    final statusColor = animal.complianceStatus.status == 'OK'
        ? Colors.green
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.pets, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tag: ${animal.tagNo}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${animal.breed} • ${animal.gender}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  animal.complianceStatus.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusChip(
                icon: Icons.vaccines,
                label: 'Vaccinated',
                active: animal.vaccination,
              ),
              const SizedBox(width: 8),
              _StatusChip(
                icon: Icons.security,
                label: 'Insured',
                active: animal.insurance,
              ),
              const SizedBox(width: 8),
              _StatusChip(
                icon: Icons.favorite,
                label: 'AI',
                active: animal.artificialInsemination,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Farm: ${animal.farmId}',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: active ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: active ? Colors.green : Colors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: active ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// Add Animal Dialog
class AddAnimalDialog extends StatefulWidget {
  final Function(Animal) onSave;

  const AddAnimalDialog({super.key, required this.onSave});

  @override
  State<AddAnimalDialog> createState() => _AddAnimalDialogState();
}

class _AddAnimalDialogState extends State<AddAnimalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tagNoController = TextEditingController();
  final _breedController = TextEditingController();
  final _farmIdController = TextEditingController();

  String _selectedGender = 'Male';
  bool _insurance = false;
  bool _vaccination = false;
  bool _artificialInsemination = false;

  @override
  void dispose() {
    _tagNoController.dispose();
    _breedController.dispose();
    _farmIdController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final animal = Animal(
        tagNo: _tagNoController.text,
        breed: _breedController.text,
        gender: _selectedGender,
        farmId: _farmIdController.text,
        dateOfAdmission: DateTime.now().toIso8601String().split('T')[0],
        scanTag: 'QR',
        insurance: _insurance,
        vaccination: _vaccination,
        artificialInsemination: _artificialInsemination,
        summary: '',
        complianceStatus: ComplianceStatus(
          status: 'OK',
          lastUpdated: DateTime.now().toIso8601String(),
        ),
      );

      widget.onSave(animal);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add New Animal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _tagNoController,
                        decoration: const InputDecoration(
                          labelText: 'Tag Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter tag number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _breedController,
                        decoration: const InputDecoration(
                          labelText: 'Breed',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter breed';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Male', 'Female'].map((gender) {
                          return DropdownMenuItem(value: gender, child: Text(gender));
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedGender = value!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _farmIdController,
                        decoration: const InputDecoration(
                          labelText: 'Farm ID',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter farm ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Insurance'),
                        value: _insurance,
                        onChanged: (value) => setState(() => _insurance = value),
                      ),
                      SwitchListTile(
                        title: const Text('Vaccination'),
                        value: _vaccination,
                        onChanged: (value) => setState(() => _vaccination = value),
                      ),
                      SwitchListTile(
                        title: const Text('Artificial Insemination'),
                        value: _artificialInsemination,
                        onChanged: (value) => setState(() => _artificialInsemination = value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Animal Model
class Animal {
  final String tagNo;
  final String breed;
  final String gender;
  final String farmId;
  final String dateOfAdmission;
  final String scanTag;
  final bool insurance;
  final bool vaccination;
  final bool artificialInsemination;
  final String summary;
  final ComplianceStatus complianceStatus;

  Animal({
    required this.tagNo,
    required this.breed,
    required this.gender,
    required this.farmId,
    required this.dateOfAdmission,
    required this.scanTag,
    required this.insurance,
    required this.vaccination,
    required this.artificialInsemination,
    required this.summary,
    required this.complianceStatus,
  });

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      tagNo: json['tagNo'] ?? '',
      breed: json['breed'] ?? '',
      gender: json['gender'] ?? '',
      farmId: json['farmId'] ?? '',
      dateOfAdmission: json['dateOfAdmission'] ?? '',
      scanTag: json['scanTag'] ?? 'QR',
      insurance: json['insurance'] ?? false,
      vaccination: json['vaccination'] ?? false,
      artificialInsemination: json['artificialInsemination'] ?? false,
      summary: json['summary'] ?? '',
      complianceStatus: ComplianceStatus.fromJson(json['complianceStatus'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tagNo': tagNo,
      'breed': breed,
      'gender': gender,
      'farmId': farmId,
      'dateOfAdmission': dateOfAdmission,
      'scanTag': scanTag,
      'insurance': insurance,
      'vaccination': vaccination,
      'artificialInsemination': artificialInsemination,
      'summary': summary,
      'complianceStatus': complianceStatus.toJson(),
      'doctorVisits': [],
      'history': [],
      'prescriptions': [],
      'treatments': [],
    };
  }
}

class ComplianceStatus {
  final String status;
  final String lastUpdated;

  ComplianceStatus({required this.status, required this.lastUpdated});

  factory ComplianceStatus.fromJson(Map<String, dynamic> json) {
    return ComplianceStatus(
      status: json['status'] ?? 'OK',
      lastUpdated: json['lastUpdated'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'lastUpdated': lastUpdated};
  }
}