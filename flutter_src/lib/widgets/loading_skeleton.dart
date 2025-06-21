import 'package:flutter/material.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';

/// Skeleton loading widget for spot cards
/// Shows animated placeholder while real data loads
class SpotCardSkeleton extends StatefulWidget {
  final double height;
  final double width;

  const SpotCardSkeleton({
    Key? key,
    this.height = 200,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  State<SpotCardSkeleton> createState() => _SpotCardSkeletonState();
}

class _SpotCardSkeletonState extends State<SpotCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Loop the animation
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: ColorAliases.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: UIColors.borderPrimary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ColorAliases.neutral100.withOpacity(
                      _animation.value,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                ),
              ),

              // Content placeholder
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Title placeholder
                      Container(
                        height: 16,
                        width: MediaQuery.of(context).size.width * 0.6,
                        decoration: BoxDecoration(
                          color: ColorAliases.neutral200.withOpacity(
                            _animation.value,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                      // Subtitle placeholder
                      Container(
                        height: 12,
                        width: MediaQuery.of(context).size.width * 0.4,
                        decoration: BoxDecoration(
                          color: ColorAliases.neutral200.withOpacity(
                            _animation.value,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget that shows multiple skeleton cards for trending swiper
class TrendingSkeleton extends StatelessWidget {
  final int itemCount;

  const TrendingSkeleton({Key? key, this.itemCount = 3}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return const SizedBox(
            width: 240, // Similar to your swiper card width
            child: SpotCardSkeleton(),
          );
        },
      ),
    );
  }
}

/// Skeleton for spot list items (for future use)
class SpotListItemSkeleton extends StatelessWidget {
  const SpotListItemSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: BoxDecoration(
        color: ColorAliases.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: UIColors.borderPrimary),
      ),
      child: Row(
        children: [
          // Image placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: ColorAliases.neutral100,
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          const SizedBox(width: 12),

          // Content placeholder
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ColorAliases.neutral200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: ColorAliases.neutral200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
