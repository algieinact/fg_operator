import 'package:flutter/material.dart';
import 'dart:io';
import '../services/api_service.dart';

class NetworkDebugScreen extends StatefulWidget {
  const NetworkDebugScreen({super.key});

  @override
  State<NetworkDebugScreen> createState() => _NetworkDebugScreenState();
}

class _NetworkDebugScreenState extends State<NetworkDebugScreen> {
  final List<String> _testUrls = [
    'http://10.1.121.99:8000/api',
    'http://fg-store.ns1.sanoh.co.id/api',
    'https://httpbin.org/get',  // Public test endpoint
    'https://google.com',       // Basic connectivity test
  ];
  
  final Map<String, String> _testResults = {};
  bool _isTestingAll = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Connectivity Test',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Test all button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isTestingAll ? null : _testAllUrls,
                child: Text(
                  _isTestingAll ? 'Testing...' : 'Test All URLs',
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            
            // Test results
            Expanded(
              child: ListView.builder(
                itemCount: _testUrls.length,
                itemBuilder: (context, index) {
                  final url = _testUrls[index];
                  final result = _testResults[url];
                  
                  return Card(
                    child: ListTile(
                      title: Text(
                        url,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: result != null 
                          ? Text(
                              result,
                              style: TextStyle(
                                color: result.contains('SUCCESS') 
                                    ? Colors.green 
                                    : Colors.red,
                                fontSize: 12,
                              ),
                            )
                          : const Text('Not tested'),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _testSingleUrl(url),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const Divider(),
            
            // Device info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Device Info:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Platform: ${Platform.operatingSystem}'),
                  Text('Version: ${Platform.operatingSystemVersion}'),
                  if (Platform.isAndroid) 
                    const Text('Network: Check WiFi/Mobile Data'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Proceed to login button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Proceed to Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testAllUrls() async {
    setState(() {
      _isTestingAll = true;
      _testResults.clear();
    });

    for (final url in _testUrls) {
      await _testSingleUrl(url, updateState: false);
    }

    setState(() {
      _isTestingAll = false;
    });
  }

  Future<void> _testSingleUrl(String baseUrl, {bool updateState = true}) async {
    if (updateState) {
      setState(() {
        _testResults[baseUrl] = 'Testing...';
      });
    }

    try {
      final stopwatch = Stopwatch()..start();
      
      // Test basic connectivity
      final socket = await Socket.connect(
        Uri.parse(baseUrl).host,
        Uri.parse(baseUrl).port,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      
      stopwatch.stop();
      
      final result = 'SUCCESS - Socket connection (${stopwatch.elapsedMilliseconds}ms)';
      
      if (updateState) {
        setState(() {
          _testResults[baseUrl] = result;
        });
      } else {
        _testResults[baseUrl] = result;
      }
      
      // If it's an API endpoint, test HTTP request
      if (baseUrl.contains('/api')) {
        await _testHttpRequest(baseUrl, updateState);
      }
      
    } catch (e) {
      final result = 'FAILED - ${e.toString()}';
      
      if (updateState) {
        setState(() {
          _testResults[baseUrl] = result;
        });
      } else {
        _testResults[baseUrl] = result;
      }
    }
  }

  Future<void> _testHttpRequest(String baseUrl, bool updateState) async {
    try {
      final apiService = ApiService();
      
      // Try a simple API call
      final response = await apiService.debugSimple();
      
      final result = _testResults[baseUrl]! + '\nHTTP: SUCCESS - ${response['success']}';
      
      if (updateState) {
        setState(() {
          _testResults[baseUrl] = result;
        });
      } else {
        _testResults[baseUrl] = result;
      }
      
    } catch (e) {
      final currentResult = _testResults[baseUrl] ?? '';
      final result = '$currentResult\nHTTP: FAILED - ${e.toString()}';
      
      if (updateState) {
        setState(() {
          _testResults[baseUrl] = result;
        });
      } else {
        _testResults[baseUrl] = result;
      }
    }
  }
}