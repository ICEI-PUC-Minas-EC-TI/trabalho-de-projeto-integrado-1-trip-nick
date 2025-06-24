import 'package:flutter/material.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';

/// Speed Dial Floating Action Button with two options: New List and Post
///
/// This widget creates a FAB that expands to show two action buttons:
/// - "New List" for creating shareable spot lists
/// - "Post" for creating community posts
///
/// The widget manages its own expanded/collapsed state and provides
/// callbacks for when each option is selected.
class SpeedDialFAB extends StatefulWidget {
  /// Callback when "Post" option is selected
  final VoidCallback? onCreatePost;

  /// Callback when "New List" option is selected
  final VoidCallback? onCreateList;

  /// Whether the speed dial should start in expanded state
  final bool initiallyExpanded;

  const SpeedDialFAB({
    Key? key,
    this.onCreatePost,
    this.onCreateList,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  State<SpeedDialFAB> createState() => _SpeedDialFABState();
}

class _SpeedDialFABState extends State<SpeedDialFAB>
    with SingleTickerProviderStateMixin {
  /// Controls the expansion/collapse animation
  late AnimationController _animationController;

  /// Animation for rotating the main FAB icon
  late Animation<double> _rotationAnimation;

  /// Animation for scaling the speed dial options
  late Animation<double> _scaleAnimation;

  /// Tracks whether the speed dial is currently expanded
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller with 200ms duration
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Create rotation animation (0 to 45 degrees for the + icon)
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees = 1/8 of full rotation
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Create scale animation for the option buttons
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Set initial state if needed
    if (widget.initiallyExpanded) {
      _isExpanded = true;
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Toggles the expanded/collapsed state of the speed dial
  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  /// Handles selection of an option and collapses the speed dial
  void _onOptionSelected(VoidCallback? callback) {
    // Collapse the speed dial first
    if (_isExpanded) {
      _toggle();
    }

    // Execute the callback after a short delay to allow animation
    Future.delayed(const Duration(milliseconds: 100), () {
      callback?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          CrossAxisAlignment.end, // This ensures right alignment
      children: [
        // Speed dial options (shown when expanded)
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _isExpanded ? null : 0,
          child:
              _isExpanded
                  ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.end, // Right align the options
                    children: [
                      _buildSpeedDialOption(
                        icon: Icons.list_alt,
                        label: 'New List',
                        onTap: () => _onOptionSelected(widget.onCreateList),
                      ),
                      const SizedBox(height: 16),
                      _buildSpeedDialOption(
                        icon: Icons.edit_note,
                        label: 'Post',
                        onTap: () => _onOptionSelected(widget.onCreatePost),
                      ),
                      const SizedBox(height: 16),
                    ],
                  )
                  : const SizedBox.shrink(),
        ),

        // Main FAB button
        _buildMainFAB(),
      ],
    );
  }

  /// Builds an individual speed dial option button
  Widget _buildSpeedDialOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end, // Align to the right
            children: [
              // Label text
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ColorAliases.neutral700.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
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
                    color: UIColors.textOnAction,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Option button
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: ColorAliases.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: UIColors.borderPrimary, width: 1),
                  ),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(28),
                    child: Icon(
                      icon,
                      color: ColorAliases.primaryDefault,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the main FAB button with rotation animation
  Widget _buildMainFAB() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: ColorAliases.primaryDefault,
          elevation: 6,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159, // Convert to radians
            child: Icon(Icons.add, color: UIColors.iconOnAction, size: 28),
          ),
        );
      },
    );
  }
}

/// Extension to easily add SpeedDialFAB to any Scaffold
extension ScaffoldSpeedDial on Widget {
  /// Wraps the widget in a Scaffold with SpeedDialFAB
  Widget withSpeedDialFAB({
    VoidCallback? onCreatePost,
    VoidCallback? onCreateList,
  }) {
    return Builder(
      builder: (context) {
        return Stack(
          children: [
            this,
            Positioned(
              bottom: 16,
              right: 16,
              child: SpeedDialFAB(
                onCreatePost: onCreatePost,
                onCreateList: onCreateList,
              ),
            ),
          ],
        );
      },
    );
  }
}
