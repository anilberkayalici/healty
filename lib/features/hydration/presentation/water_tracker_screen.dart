import 'package:flutter/material.dart';
import '../logic/water_tracker_controller.dart';
import 'widgets/water_wave_animation.dart';

/// Water Tracker Screen
/// Displays daily hydration progress with Stitch-based UI design
class WaterTrackerScreen extends StatefulWidget {
  const WaterTrackerScreen({super.key});

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen> {
  late final WaterTrackerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WaterTrackerController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111821),
      bottomNavigationBar: _buildAddWaterButton(),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopSection(),
                          const SizedBox(height: 32),
                          _buildIntakeHistory(),
                          const SizedBox(height: 48),
                          _buildMotivationalSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Header with water drop icon and title
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Icon(
            Icons.water_drop,
            color: Color(0xFF307DE8),
            size: 28,
          ),
          const SizedBox(width: 8),
          const Text(
            'Hydration',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  /// Top section: Water drop progress card + Daily goal card
  Widget _buildTopSection() {
    final state = _controller.state;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Water drop progress card (55% width)
        Expanded(
          flex: 55,
          child: _buildWaterDropCard(state),
        ),
        const SizedBox(width: 16),

        // Right: Daily goal card (45% width)
        Expanded(
          flex: 45,
          child: _buildDailyGoalCard(state),
        ),
      ],
    );
  }

  /// Water drop progress card with premium wave animation
  Widget _buildWaterDropCard(state) {
    final progressPercent = (state.progressPercentage * 100).toInt();

    return Column(
      children: [
        // Square container with water drop
        AspectRatio(
          aspectRatio: 1.0,
          child: AnimatedWaterWave(
            fillPercentage: state.progressPercentage,
            waterColor: const Color(0xFF307DE8),
            child: Container(
              decoration: BoxDecoration(
                // REMOVED: color property was BLOCKING water animation!
                // The AnimatedWaterWave draws water BEHIND this container
                // Container MUST be transparent to see the water
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF1A2432).withOpacity(0.3),
                          const Color(0xFF1A2432).withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  // Center content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.water_drop,
                          size: 84,
                          color: const Color(0xFF307DE8).withOpacity(0.9),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$progressPercent%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Remaining label and amount
        Column(
          children: [
            Text(
              'REMAINING',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF307DE8).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF307DE8).withOpacity(0.2),
                ),
              ),
              child: Text(
                '${state.remainingLiters.toStringAsFixed(1)} L',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Daily goal card with update button
  Widget _buildDailyGoalCard(state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2432),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.flag,
                color: const Color(0xFF307DE8).withOpacity(0.8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Goal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[300],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Goal value
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      state.dailyGoalLiters.toStringAsFixed(1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Litre',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                height: 2,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Update button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showUpdateGoalDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF307DE8).withOpacity(0.1),
                foregroundColor: const Color(0xFF307DE8),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Update',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.check, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Intake history grid (16 glasses)
  Widget _buildIntakeHistory() {
    final state = _controller.state;
    final filledCount = (state.consumedMl / 200).floor();
    
    // Dynamic glass count: minimum 8 (1 row), then multiples of 8
    // Show filled glasses + at least 8 empty for next row
    final minGlassCount = 8;
    final totalGlasses = ((filledCount / 8).ceil() * 8).clamp(minGlassCount, 10000);
    
    // Calculate dynamic height based on row count
    final rowCount = (totalGlasses / 8).ceil();
    final dynamicHeight = rowCount * 70.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Intake History',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Dynamic glass grid
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2432),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: SizedBox(
            height: dynamicHeight,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 6,
                mainAxisSpacing: 10,
                childAspectRatio: 0.65,
              ),
              itemCount: totalGlasses,
              itemBuilder: (context, index) {
                final isFilled = index < filledCount;
                return _buildGlass(isFilled, index < state.glassHistory.length 
                    ? state.glassHistory[index] 
                    : null);
              },
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Consumed amount
        Center(
          child: Text(
            '${state.consumedLiters.toStringAsFixed(1)}L Consumed',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[400],
            ),
          ),
        ),
      ],
    );
  }

  /// Single glass widget
  Widget _buildGlass(bool filled, DateTime? timestamp) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FA), // Neutral light grey-white
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.grey.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: filled
              ? Image.asset(
                  'assets/icons/glass.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  color: const Color(0xFF307DE8), // Blue water inside
                  colorBlendMode: BlendMode.modulate,
                )
              : Opacity(
                  opacity: 0.4, // Empty glass with light opacity
                  child: Image.asset(
                    'assets/icons/glass.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    color: Colors.grey[400], // Grey glass outline only
                    colorBlendMode: BlendMode.modulate,
                  ),
                ),
        ),
        if (timestamp != null) ...[
          const SizedBox(height: 2),
          Text(
            '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  /// Motivational message section
  Widget _buildMotivationalSection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          _controller.getMotivationalMessage(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF93C5FD),
            height: 1.5,
          ),
        ),
      ),
    );
  }

  /// Fixed bottom "Add Water" button
  Widget _buildAddWaterButton() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF111821),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Add Water button (left, flexible)
            Expanded(
              child: ElevatedButton(
                onPressed: () => _controller.addWater(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF307DE8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF307DE8).withOpacity(0.3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.local_drink, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Add Water',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Quick add 200ml',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFBFDBFE),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Minus button
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2432),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF307DE8).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.remove,
                  color: Color(0xFF307DE8),
                  size: 24,
                ),
                onPressed: () => _controller.removeWater(),
              ),
            ),
            const SizedBox(width: 8),

            // Plus button
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.add,
                  color: Color(0xFF307DE8),
                  size: 24,
                ),
                onPressed: () => _controller.addWater(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show update goal dialog
  void _showUpdateGoalDialog() {
    final currentGoal = _controller.state.dailyGoalLiters;
    final textController = TextEditingController(
      text: currentGoal.toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2432),
        title: const Text(
          'Update Daily Goal',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 24),
              decoration: InputDecoration(
                suffix: Text(
                  'Litre',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                helperText: 'Max: 5.0 Litre',
                helperStyle: TextStyle(color: Colors.grey[600]),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF307DE8)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () {
              final newGoal = double.tryParse(textController.text);
              if (newGoal != null) {
                _controller.updateDailyGoal(newGoal);
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Color(0xFF307DE8)),
            ),
          ),
        ],
      ),
    );
  }
}
