import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerVideoPlaceholder extends StatelessWidget {
  final Size size;

  const ShimmerVideoPlaceholder({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: size.height * 0.3,
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: size.height * 0.01),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size.width * 0.027),
        ),
      ),
    );
  }
}
