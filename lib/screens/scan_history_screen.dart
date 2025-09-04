import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/custom_navbar.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _history = [];
  int _currentPage = 1;
  int _lastPage = 1;
  final int _perPage = 20;

  @override
  void initState() {
    super.initState();
    _load(page: 1);
  }

  Future<void> _load({required int page}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res =
          await _api.getOperatorScanHistory(page: page, perPage: _perPage);
      final data = res['data'] as Map<String, dynamic>?;
      final List<dynamic> list = (data?['history'] as List<dynamic>?) ?? [];
      final pagination = data?['pagination'] as Map<String, dynamic>?;

      setState(() {
        _history = list.map((e) => (e as Map<String, dynamic>)).toList();
        _currentPage = pagination?['current_page'] ?? page;
        _lastPage = pagination?['last_page'] ?? page;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'store':
        return const Color(0xFF10B981); // green
      case 'pull':
        return const Color(0xFFF59E0B); // orange
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const CustomNavbar(showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scan History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _history.isEmpty
                      ? const Center(child: Text('No history found'))
                      : RefreshIndicator(
                          onRefresh: () => _load(page: 1),
                          child: ListView.separated(
                            itemCount: _history.length + 1,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              if (index == _history.length) {
                                // Pagination controls
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Page $_currentPage of $_lastPage',
                                          style: TextStyle(
                                              color: Colors.grey[700])),
                                      Row(
                                        children: [
                                          OutlinedButton(
                                            onPressed:
                                                _currentPage > 1 && !_isLoading
                                                    ? () => _load(
                                                        page: _currentPage - 1)
                                                    : null,
                                            child: const Text('Prev'),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton(
                                            onPressed:
                                                _currentPage < _lastPage &&
                                                        !_isLoading
                                                    ? () => _load(
                                                        page: _currentPage + 1)
                                                    : null,
                                            child: const Text('Next'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final item = _history[index];
                              final erp = item['erp_code']?.toString() ?? '-';
                              final slot = item['slot_name']?.toString() ?? '-';
                              final status = item['status']?.toString() ?? '-';
                              final date = item['date']?.toString() ?? '-';

                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          status.toLowerCase() == 'store'
                                              ? Icons.inventory_2
                                              : Icons.shopping_cart,
                                          color: _statusColor(status),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              erp,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                    Icons.location_on_outlined,
                                                    size: 16,
                                                    color: Color(0xFF6B7280)),
                                                const SizedBox(width: 4),
                                                Text('Slot: $slot',
                                                    style: const TextStyle(
                                                        color:
                                                            Color(0xFF6B7280))),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _statusColor(status)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: TextStyle(
                                                color: _statusColor(status),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            date,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B7280)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
