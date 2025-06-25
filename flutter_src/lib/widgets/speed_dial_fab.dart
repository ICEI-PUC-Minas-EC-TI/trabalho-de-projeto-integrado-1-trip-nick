// Import for PostCreationScreen - adjust path as needed
// You might need to import your existing PostCreationScreen here
import '../screens/post_creation_screen.dart';
import 'package:flutter/material.dart';
import '../design_system/colors/color_aliases.dart';
import '../design_system/colors/ui_colors.dart';
import '../models/enums/post_creation_mode.dart';

/// A floating action button with expandable speed dial options
/// Provides quick access to main creation actions: New List and Community Post
class SpeedDialFAB extends StatefulWidget {
  const SpeedDialFAB({Key? key}) : super(key: key);

  @override
  State<SpeedDialFAB> createState() => _SpeedDialFABState();
}

class _SpeedDialFABState extends State<SpeedDialFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees rotation
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _collapse() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _animationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Speed dial options (only show when expanded)
        if (_isExpanded) ...[
          // New List option
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: _buildSpeedDialOption(
                  icon: Icons.list_alt,
                  label: 'New List',
                  onTap: _onNewListTapped,
                  backgroundColor: ColorAliases.primaryDefault,
                  iconColor: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Community Post option
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: _buildSpeedDialOption(
                  icon: Icons.create,
                  label: 'Post',
                  onTap: _onPostTapped,
                  backgroundColor: ColorAliases.primaryDefault,
                  iconColor: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // Main FAB
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle:
                  _rotationAnimation.value * 2 * 3.14159, // Convert to radians
              child: FloatingActionButton(
                onPressed: _toggleExpanded,
                backgroundColor: ColorAliases.primaryDefault,
                elevation: 6,
                child: Icon(
                  _isExpanded ? Icons.close : Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Builds an individual speed dial option
  Widget _buildSpeedDialOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Mini FAB
        FloatingActionButton(
          mini: true,
          onPressed: () {
            _collapse();
            onTap();
          },
          backgroundColor: backgroundColor,
          elevation: 4,
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ],
    );
  }

  // =============================================================================
  // EVENT HANDLERS
  // =============================================================================

  /// Handles New List button tap
  void _onNewListTapped() {
    print('==================================================');
    print('NEW LIST CREATION - Navigating to list post creation');
    print('==================================================');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) =>
                const PostCreationScreen(mode: PostCreationMode.listPost),
        fullscreenDialog: true,
      ),
    );
  }

  /// Handles Post button tap
  void _onPostTapped() {
    print('==================================================');
    print('COMMUNITY POST CREATION - Navigating to community post creation');
    print('==================================================');

    // Navigate to existing PostCreationScreen (community mode)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PostCreationScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}
