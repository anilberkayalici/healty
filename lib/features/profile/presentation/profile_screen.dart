import 'package:flutter/material.dart';
import '../domain/profile.dart';
import '../data/profile_repository_impl.dart';
import '../domain/bmi.dart';

/// Profile/Personal Info screen
/// Allows user to edit their health metrics and personal information
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repository = ProfileRepositoryImpl();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedGender = 'male';
  bool _isLoading = true;
  BmiResult _bmiResult = BmiResult.unavailable();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    
    // Add listeners for live BMI calculation
    _heightController.addListener(_updateBmi);
    _weightController.addListener(_updateBmi);
  }

  void _updateBmi() {
    final height = parseNumber(_heightController.text);
    final weight = parseNumber(_weightController.text);
    
    final bmi = computeBmi(
      heightCm: height ?? 0,
      weightKg: weight ?? 0,
    );
    
    final newResult = classifyBmi(bmi);
    
    if (newResult.categoryKey != _bmiResult.categoryKey || 
        (newResult.bmiValue - _bmiResult.bmiValue).abs() > 0.05) {
      setState(() {
        _bmiResult = newResult;
      });
    }
  }

  Future<void> _loadProfile() async {
    final profile = await _repository.load();
    if (mounted) {
      setState(() {
        _nameController.text = profile.name;
        _heightController.text = profile.heightCm?.toString() ?? '178';
        _weightController.text = profile.weightKg?.toString() ?? '72.5';
        _selectedGender = profile.gender ?? 'male';
        _isLoading = false;
      });
      // Calculate initial BMI
      _updateBmi();
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    final height = parseNumber(_heightController.text);
    final weight = parseNumber(_weightController.text);

    final profile = UserProfile(
      name: name,
      heightCm: height,
      weightKg: weight,
      gender: _selectedGender,
    );

    await _repository.save(profile);

    if (mounted) {
      Navigator.pop(context, true); // Return true to indicate save successful
    }
  }

  @override
  void dispose() {
    _heightController.removeListener(_updateBmi);
    _weightController.removeListener(_updateBmi);
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101F22),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(context),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildHealthInfoCard(),
                    const SizedBox(height: 16),
                    _buildBMISummary(),
                    const SizedBox(height: 100), // Space for bottom buttons
                  ],
                ),
              ),
            ),
            
            // Bottom Actions
            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF101F22).withOpacity(0.9),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),
          const Text(
            'Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          TextButton(
            onPressed: _saveProfile,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF13C8EC).withOpacity(0.1),
              foregroundColor: const Color(0xFF13C8EC),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Save', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2527),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Decorative gradient
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF13C8EC).withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          // Avatar
          Stack(
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF253033), width: 4),
                  color: Colors.grey[700],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, size: 56, color: Colors.white70),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF101F22),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF101F22), width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Name Input
          SizedBox(
            width: 180,
            child: TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF13C8EC)),
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.edit, size: 18, color: Colors.white.withOpacity(0.3)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          TextButton(
            onPressed: () {},
            child: const Text(
              'Change photo',
              style: TextStyle(color: Color(0xFF13C8EC), fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2527),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF13C8EC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.favorite, color: Color(0xFF13C8EC), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Body Metrics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Height & Weight
          Row(
            children: [
              Expanded(child: _buildMetricInput('HEIGHT', _heightController, 'cm')),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricInput('WEIGHT', _weightController, 'kg')),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Gender Selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'GENDER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF151D1F),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    _buildGenderOption('Male', 'male'),
                    _buildGenderOption('Female', 'female'),
                    _buildGenderOption('Other', 'other'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricInput(String label, TextEditingController controller, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF151D1F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Text(
                unit,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(String label, String value) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = value),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF283639) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF13C8EC) : Colors.grey[500],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBMISummary() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2527),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.health_and_safety, color: Color(0xFF13C8EC), size: 18),
              const SizedBox(width: 8),
              Text(
                'BMI: ',
                style: TextStyle(fontSize: 14, color: Colors.grey[300], fontWeight: FontWeight.w500),
              ),
              Text(
                _bmiResult.categoryKey == 'unavailable' ? '—' : _bmiResult.formattedBmi,
                style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              if (_bmiResult.categoryKey != 'unavailable') ...[
                const SizedBox(width: 4),
                Text(
                  '(${_bmiResult.labelText})',
                  style: TextStyle(fontSize: 14, color: _bmiResult.color, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'BMI is a general indicator and may not reflect body composition.',
          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF101F22).withOpacity(0.8),
            const Color(0xFF101F22),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF13C8EC),
                foregroundColor: const Color(0xFF101F22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 0,
                shadowColor: const Color(0xFF13C8EC).withOpacity(0.3),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }
}
