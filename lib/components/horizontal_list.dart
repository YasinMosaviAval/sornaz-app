import 'package:flutter/material.dart';

class HorizontalList extends StatelessWidget {
  final double height;
  final int itemCount;
  final Widget Function(int) builder;

  const HorizontalList({
    super.key,
    required this.height,
    required this.itemCount,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: height,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: itemCount,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: builder(index),
          ),
        ),
      ),
    );
  }
}
