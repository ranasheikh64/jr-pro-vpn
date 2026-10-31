import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/vpn_server.dart';

class ServerBottomSheet extends StatefulWidget {
  final List<VpnServer> servers;
  final VpnServer selectedServer;
  final ValueChanged<VpnServer> onSelect;

  const ServerBottomSheet({
    super.key,
    required this.servers,
    required this.selectedServer,
    required this.onSelect,
  });

  static Future<void> show({
    required BuildContext context,
    required List<VpnServer> servers,
    required VpnServer selectedServer,
    required ValueChanged<VpnServer> onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ServerBottomSheet(
        servers: servers,
        selectedServer: selectedServer,
        onSelect: onSelect,
      ),
    );
  }

  @override
  State<ServerBottomSheet> createState() => _ServerBottomSheetState();
}

class _ServerBottomSheetState extends State<ServerBottomSheet> {
  late List<VpnServer> _filtered;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.servers;
  }

  void _filter(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? widget.servers
          : widget.servers.where((s) {
              final lq = q.toLowerCase();
              return s.country.toLowerCase().contains(lq) ||
                  s.city.toLowerCase().contains(lq);
            }).toList();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          height: (MediaQuery.of(context).size.height * 0.65).clamp(380.0, 600.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 24,
                spreadRadius: 2,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
        children: [
          const SizedBox(height: 12),

          // Drag handle
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          const SizedBox(height: 14),

          // Header Title: "Choose Country" (exact match to Figma node 3:86)
          const Text(
            'Choose Country',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 14),

          // Divider line across (Figma 3:86)
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: _filter,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_search.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _search.clear();
                        _filter('');
                      },
                      child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade400),
                    ),
                ],
              ),
            ),
          ),

          // Country List (Matching Figma node 3:86)
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              itemCount: _filtered.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                thickness: 0.5,
                color: Colors.grey.shade100,
                indent: 58,
              ),
              itemBuilder: (context, index) {
                final server = _filtered[index];
                final isSelected = server.id == widget.selectedServer.id;

                return InkWell(
                  onTap: () {
                    widget.onSelect(server);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppConstants.goldLight.withValues(alpha: 0.22)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Circular Flag avatar with subtle border
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade100,
                            border: Border.all(
                              color: isSelected
                                  ? AppConstants.goldDark
                                  : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            server.flag,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Country name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                server.country,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppConstants.goldDeep
                                      : const Color(0xFF374151),
                                ),
                              ),
                              if (server.city.isNotEmpty)
                                Text(
                                  server.city,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Latency / Status
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppConstants.goldDark
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.check_rounded,
                                      size: 13, color: Colors.white),
                                ),
                              Text(
                                server.ping,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    ),
    );
  }
}
