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
      builder: (context) => ServerBottomSheet(
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
  late List<VpnServer> _filteredServers;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredServers = widget.servers;
  }

  void _filterServers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredServers = widget.servers;
      } else {
        _filteredServers = widget.servers.where((server) {
          final q = query.toLowerCase();
          return server.country.toLowerCase().contains(q) ||
              server.city.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getPingColor(String ping) {
    final ms = int.tryParse(ping.replaceAll(RegExp(r'[^0-9]'), '')) ?? 100;
    if (ms < 60) return AppConstants.successNeon;
    if (ms < 120) return AppConstants.warningNeon;
    return AppConstants.errorNeon;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppConstants.border, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag indicator
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryNeon.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.servers.length} Servers',
                    style: const TextStyle(
                      color: AppConstants.primaryNeon,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              onChanged: _filterServers,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search country or city...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
                filled: true,
                fillColor: AppConstants.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppConstants.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppConstants.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppConstants.primaryNeon),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Server list
          Expanded(
            child: _filteredServers.isEmpty
                ? const Center(
                    child: Text(
                      'No locations found',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _filteredServers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final server = _filteredServers[index];
                      final isSelected = server.id == widget.selectedServer.id;
                      final pingColor = _getPingColor(server.ping);

                      return InkWell(
                        onTap: () {
                          widget.onSelect(server);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppConstants.primaryNeon.withValues(alpha: 0.08)
                                : AppConstants.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppConstants.primaryNeon
                                  : AppConstants.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Flag icon
                              Text(
                                server.flag,
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(width: 16),

                              // Country and City
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      server.country,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white.withValues(alpha: 0.9),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      server.city,
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Latency & load badge
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: pingColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        server.ping,
                                        style: TextStyle(
                                          color: pingColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Load: ${server.load}',
                                    style: const TextStyle(
                                      color: Colors.white30,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 12),

                              // Selection Checkmark
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppConstants.primaryNeon,
                                  size: 22,
                                )
                              else
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white24,
                                  size: 22,
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
    );
  }
}
