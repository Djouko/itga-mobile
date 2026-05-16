import 'package:flutter/material.dart';
import 'package:untitled/utilities/const.dart';

class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? cLightText.withValues(alpha: 0.08);
    final highlight = widget.highlightColor ?? cLightText.withValues(alpha: 0.18);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class FeedShimmerPlaceholder extends StatelessWidget {
  const FeedShimmerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: List.generate(3, (_) => _buildPostSkeleton()),
      ),
    );
  }

  Widget _buildPostSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerBox(width: 42, height: 42, borderRadius: 21),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 120, height: 14),
                  SizedBox(height: 6),
                  ShimmerBox(width: 80, height: 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const ShimmerBox(width: double.infinity, height: 14),
          const SizedBox(height: 6),
          const ShimmerBox(width: 200, height: 14),
          const SizedBox(height: 12),
          const ShimmerBox(width: double.infinity, height: 180, borderRadius: 12),
          const SizedBox(height: 12),
          Row(
            children: const [
              ShimmerBox(width: 50, height: 12),
              SizedBox(width: 20),
              ShimmerBox(width: 50, height: 12),
              SizedBox(width: 20),
              ShimmerBox(width: 50, height: 12),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: cLightText.withValues(alpha: 0.1)),
        ],
      ),
    );
  }
}

class RoomShimmerPlaceholder extends StatelessWidget {
  const RoomShimmerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: List.generate(4, (_) => _buildRoomSkeleton()),
      ),
    );
  }

  Widget _buildRoomSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cLightText.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const ShimmerBox(width: 52, height: 52, borderRadius: 14),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 150, height: 16),
                  SizedBox(height: 6),
                  ShimmerBox(width: 100, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileShimmerPlaceholder extends StatelessWidget {
  const ProfileShimmerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: List.generate(5, (_) => _buildUserSkeleton()),
      ),
    );
  }

  Widget _buildUserSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          const ShimmerBox(width: 48, height: 48, borderRadius: 12),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 130, height: 14),
                SizedBox(height: 6),
                ShimmerBox(width: 90, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
