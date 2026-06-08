import 'dart:ui';
import 'package:flutter/material.dart';

enum MapLayerType { normal, satellite, terrain, hybrid, traffic }

class MapLayerItem {
  final MapLayerType type;
  final String label;
  final IconData icon;
  final Color activeColor;

  MapLayerItem({
    required this.type,
    required this.label,
    required this.icon,
    required this.activeColor,
  });
}

class MapLayersControl extends StatelessWidget {
  final MapLayerType selectedLayer;
  final Function(MapLayerType) onLayerSelected;
  final bool isDarkMode;

  const MapLayersControl({
    super.key,
    required this.selectedLayer,
    required this.onLayerSelected,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<MapLayerItem> items = [
      MapLayerItem(
        type: MapLayerType.normal,
        label: 'Default',
        icon: Icons.map_rounded,
        activeColor: Colors.blue,
      ),
      MapLayerItem(
        type: MapLayerType.satellite,
        label: 'Satellite',
        icon: Icons.satellite_alt_rounded,
        activeColor: Colors.orange,
      ),
      MapLayerItem(
        type: MapLayerType.terrain,
        label: 'Terrain',
        icon: Icons.terrain_rounded,
        activeColor: Colors.green,
      ),
      MapLayerItem(
        type: MapLayerType.hybrid,
        label: 'Hybrid',
        icon: Icons.layers_rounded,
        activeColor: Colors.purple,
      ),
      MapLayerItem(
        type: MapLayerType.traffic,
        label: 'Traffic',
        icon: Icons.traffic_rounded,
        activeColor: Colors.red,
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: items.map((item) {
              final isSelected = selectedLayer == item.type;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildLayerItem(item, isSelected),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLayerItem(MapLayerItem item, bool isSelected) {
    return GestureDetector(
      onTap: () => onLayerSelected(item.type),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDarkMode ? Colors.grey[800] : Colors.white)
                  : (isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey[200]!.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? item.activeColor : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: item.activeColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: Icon(
              item.icon,
              color: isSelected
                  ? item.activeColor
                  : (isDarkMode ? Colors.white70 : Colors.black54),
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? (isDarkMode ? Colors.white : Colors.black87)
                  : (isDarkMode ? Colors.white54 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
