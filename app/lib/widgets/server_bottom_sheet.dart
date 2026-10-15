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

  Color _pingColor(String ping) {
    final ms = int.tryParse(ping.replaceAll(RegExp(r'[^0-9]'), '')) ?? 100;
    if (ms < 60) return AppConstants.successNeon;
    if (ms < 120) return AppConstants.warningNeon;
    return AppConstants.errorNeon;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.74,
      decoration: BoxDecoration(
        color: const Color(0xFF080E1C),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: AppConstants.primaryNeon.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),

          // ── Drag handle ─────────────────────────────────────────────────
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppConstants.primaryNeon.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NODE SELECTION',
                      style: TextStyle(
                        color: AppConstants.primaryNeon,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Select Server',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryNeon.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppConstants.primaryNeon.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '${widget.servers.length} Nodes',
                    style: const TextStyle(
                      color: AppConstants.primaryNeon,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Search field ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: TextField(
              controller: _search,
              onChanged: _filter,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search country or city…',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.28),
                  fontSize: 13,
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppConstants.primaryNeon.withValues(alpha: 0.6),
                    size: 20),
                filled: true,
                fillColor: const Color(0xFF0D1825),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppConstants.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppConstants.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppConstants.primaryNeon,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Server list ──────────────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            color: Colors.white24, size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          'No nodes found',
                          style: TextStyle(color: Colors.white30, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 6),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final server = _filtered[i];
                      final selected = server.id == widget.selectedServer.id;
                      final pingColor = _pingColor(server.ping);

                      return GestureDetector(
                        onTap: () {
                          widget.onSelect(server);
                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppConstants.primaryNeon.withValues(alpha: 0.07)
                                : const Color(0xFF0D1825),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? AppConstants.primaryNeon.withValues(alpha: 0.55)
                                  : AppConstants.border,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Flag
                              Text(server.flag,
                                  style: const TextStyle(fontSize: 26)),
                              const SizedBox(width: 14),

                              // Name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      server.country,
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : Colors.white.withValues(alpha: 0.85),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      server.city,
                                      style: const TextStyle(
                                          color: Colors.white30, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),

                              // Ping + load
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
                                          boxShadow: [
                                            BoxShadow(
                                              color: pingColor.withValues(alpha: 0.6),
                                              blurRadius: 5,
                                              spreadRadius: 1,
                                            )
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 5),
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
                                  const SizedBox(height: 3),
                                  Text(
                                    'Load: ${server.load}',
                                    style: const TextStyle(
                                        color: Colors.white24, fontSize: 10),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 10),

                              // Checkmark
                              if (selected)
                                const Icon(Icons.check_circle_rounded,
                                    color: AppConstants.primaryNeon, size: 20)
                              else
                                Icon(Icons.chevron_right_rounded,
                                    color: Colors.white.withValues(alpha: 0.18),
                                    size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
