import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_spacing.dart';

class NoteLength {
  final String name;
  final int ticksPerBeat;
  final Widget Function(Color color, double size) iconBuilder;
  final Widget Function(Color color, double size) selectedIconBuilder;

  const NoteLength({
    required this.name,
    required this.ticksPerBeat,
    required this.iconBuilder,
    required this.selectedIconBuilder,
  });

  Widget icon({
    required Color color, 
    bool isSelectedIcon = false, 
    double size = AppSpacing.space_36
  }) {
    return isSelectedIcon ? selectedIconBuilder(color, size) : iconBuilder(color, size);
  }

  Widget nameBox({
    required TextStyle style, 
    bool isSelected = false,
    bool isDark = false
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected 
          ? isDark ? AppColors.surface_dark : AppColors.surface_light
          : Colors.transparent,
        borderRadius: BorderRadius.all(Radius.circular(AppSpacing.space_2))
      ),
      padding: EdgeInsets.all(AppSpacing.space_4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_8),
        child: Text(
          name, 
          style: style,
        ),
      ),
    );
  }

}

final noteLengths = [
  NoteLength(
    name: '1',
    ticksPerBeat: 1,
    iconBuilder: (color, size) => Icon(Icons.looks_one_outlined, color: color, size: size),
    selectedIconBuilder: (color, size) => Icon(Icons.looks_one, color: color, size: size),
    
  ),
  NoteLength(
    name: '2',
    ticksPerBeat: 2,
    iconBuilder: (color, size) => Icon(Icons.looks_two_outlined, color: color, size: size),
    selectedIconBuilder: (color, size) => Icon(Icons.looks_two_rounded, color: color, size: size),
    
  ),
  NoteLength(
    name: '3',
    ticksPerBeat: 3,
    iconBuilder: (color, size) => Icon(Icons.looks_3_outlined, color: color, size: size),
    selectedIconBuilder: (color, size) => Icon(Icons.looks_3_sharp, color: color, size: size),
  ),
  NoteLength(
    name: '4',
    ticksPerBeat: 4,
    iconBuilder: (color, size) => Icon(Icons.looks_4_outlined, color: color, size: size),
    selectedIconBuilder: (color, size) => Icon(Icons.looks_4, color: color, size: size),
  ),
];

