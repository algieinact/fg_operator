import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/custom_navbar.dart';
import '../services/api_service.dart';
import '../services/user_manager.dart';

enum ScanState { initial, slotScanned, completed, error }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _partNoController = TextEditingController();
  final _rackController = TextEditingController();
  final _scanController = TextEditingController();
  final _availableController = TextEditingController();

  final ApiService _apiService = ApiService();

  ScanState _scanState = ScanState.initial;
  SlotInfo? _currentSlot;
  String? _packageImageUrl;
  String? _errorMessage;
  bool _isLoading = false;
  int _currentQty = 0;
  int _capacity = 0;

  // Define imageBaseUrl to match the API server
  static const String imageBaseUrl = 'http://10.1.101.90:8000/storage/';

  @override
  void dispose() {
    _partNoController.dispose();
    _rackController.dispose();
    _scanController.dispose();
    _availableController.dispose();
    super.dispose();
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
            // Header section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Store FG',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                StreamBuilder<DateTime>(
                  stream: Stream.periodic(
                    const Duration(seconds: 1),
                    (_) => DateTime.now(),
                  ),
                  builder: (context, snapshot) {
                    final now = snapshot.data ?? DateTime.now();
                    final formatted =
                        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
                    return Text(
                      formatted,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Read only fields row
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    'Part No.',
                    _partNoController,
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    'Rack',
                    _rackController,
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    'Available',
                    _availableController,
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Image Field
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildImageSection(),
              ),
            ),
            const SizedBox(height: 24),

            // Error message display
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Scan Field
            _buildScanField(),
            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    print('ScanScreen: _buildImageSection called with URL: $_packageImageUrl');

    if (_packageImageUrl != null && _packageImageUrl!.isNotEmpty) {
      return Column(
        children: [
          // Debug info (you can remove this in production)
          // Container(
          //   width: double.infinity,
          //   padding: const EdgeInsets.all(8),
          //   margin: const EdgeInsets.only(bottom: 8),
          //   decoration: BoxDecoration(
          //     color: Colors.blue.shade50,
          //     border: Border.all(color: Colors.blue.shade200),
          //     borderRadius: BorderRadius.circular(4),
          //   ),
          //   child: Text(
          //     'Image URL: $_packageImageUrl',
          //     style: TextStyle(
          //       color: Colors.blue.shade700,
          //       fontSize: 10,
          //       fontFamily: 'monospace',
          //     ),
          //   ),
          // ),
          // Image with fallback to Image.network if CachedNetworkImage fails
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _buildImageWidget(),
            ),
          ),
        ],
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 64, color: Color(0xFF9CA3AF)),
            SizedBox(height: 16),
            Text(
              'Package Image',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Scan slot to view package image',
              style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildImageWidget() {
    return Image.network(
      _packageImageUrl!,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading image...',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('ScanScreen: Image load error: $error');
        print('ScanScreen: Failed URL: $_packageImageUrl');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image_outlined,
                size: 64,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load image',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'URL: $_packageImageUrl',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Error: $error',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9CA3AF),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    // Force rebuild to retry image loading
                  });
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanField() {
    String hintText;
    switch (_scanState) {
      case ScanState.initial:
        hintText = 'Scan slot name (e.g., A11)';
        break;
      case ScanState.slotScanned:
        hintText = 'Scan ERP code';
        break;
      case ScanState.completed:
        hintText = 'Scan completed';
        break;
      case ScanState.error:
        hintText = 'Scan slot name to retry';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scan Field',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _scanController,
          enabled: !_isLoading && _scanState != ScanState.completed,
          onSubmitted: _handleScan,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor:
                _scanState == ScanState.completed
                    ? Colors.grey.shade100
                    : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            suffixIcon:
                _isLoading
                    ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_scanState == ScanState.completed && _currentQty >= _capacity) {
      // Show alternative buttons when slot is full
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  () => Navigator.pushReplacementNamed(context, '/main-menu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981), // Green
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Back to Main Menu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _resetScan,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                side: const BorderSide(color: Color(0xFF6B7280)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Reset Scan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // Show normal scan button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed:
              _isLoading ? null : () => _handleScan(_scanController.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A), // Navy blue
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(Icons.qr_code_scanner, size: 20),
              const SizedBox(width: 8),
              Text(
                _isLoading
                    ? 'Processing...'
                    : (_scanState == ScanState.initial ||
                        _scanState == ScanState.error)
                    ? 'Scan Slot'
                    : 'Store Item',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _handleScan(String scanValue) async {
    if (scanValue.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_scanState == ScanState.initial || _scanState == ScanState.error) {
        await _scanSlot(scanValue);
      } else if (_scanState == ScanState.slotScanned) {
        await _storeByErp(scanValue);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e is ApiException ? e.message : e.toString();
        _scanState = ScanState.error;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scanSlot(String slotName) async {
    // Debug token status before making request
    UserManager.debugTokenStatus();

    // Force refresh token from storage
    await ApiService.refreshTokenFromStorage();
    print(
      'ScanScreen: Token after refresh: ${ApiService.getCurrentToken()?.substring(0, 10) ?? "null"}...',
    );

    final response = await _apiService.scanSlotForPosting(slotName);

    if (response['success'] == true && response['data'] != null) {
      final data = response['data'];
      final slot = data['slot'];
      final item = data['item'];
      final rack = data['rack'];

      // Improved image URL construction with better fallback logic
      String? imageUrl = _constructImageUrl(data);

      print('ScanScreen: Final constructed image URL: $imageUrl');

      setState(() {
        _scanState = ScanState.slotScanned;
        _currentSlot = SlotInfo.fromJson(slot);
        _packageImageUrl = imageUrl;
        _currentQty = data['current_qty'] ?? 0;
        _capacity = data['capacity'] ?? 0;

        // Fill the read-only fields
        _partNoController.text = item?['part_no'] ?? '';
        _rackController.text = rack?['rack_name'] ?? '';
        _availableController.text = '${_capacity - _currentQty}/$_capacity';

        // Clear scan field for next input
        _scanController.clear();
      });

      _showSuccessMessage('Slot scanned successfully. Now scan ERP code.');
    } else {
      throw ApiException(
        message: response['message'] ?? 'Failed to scan slot',
        statusCode: 400,
        data: response,
      );
    }
  }

  String? _constructImageUrl(Map<String, dynamic> data) {
    // Priority order for image URL construction:
    // 1. Direct full URL from packaging_image_url
    // 2. Direct full URL from package_image  
    // 3. Construct from item.packaging_img
    // 4. Construct from item.part_img as fallback

    String? imageUrl;

    // Check for complete URLs first
    if (data['packaging_image_url'] != null &&
        data['packaging_image_url'].toString().isNotEmpty) {
      final url = data['packaging_image_url'].toString();
      if (url.startsWith('http')) {
        imageUrl = url;
        print('ScanScreen: Using direct packaging_image_url: $imageUrl');
      } else {
        imageUrl = imageBaseUrl + url;
        print('ScanScreen: Constructed from packaging_image_url: $imageUrl');
      }
    } else if (data['package_image'] != null &&
        data['package_image'].toString().isNotEmpty) {
      final url = data['package_image'].toString();
      if (url.startsWith('http')) {
        imageUrl = url;
        print('ScanScreen: Using direct package_image: $imageUrl');
      } else {
        imageUrl = imageBaseUrl + url;
        print('ScanScreen: Constructed from package_image: $imageUrl');
      }
    } else if (data['item'] != null) {
      final item = data['item'];
      
      // Try packaging_img first
      if (item['packaging_img'] != null &&
          item['packaging_img'].toString().isNotEmpty) {
        final imgPath = item['packaging_img'].toString();
        // Remove leading slash if present to avoid double slashes
        final cleanPath = imgPath.startsWith('/') ? imgPath.substring(1) : imgPath;
        imageUrl = imageBaseUrl + cleanPath;
        print('ScanScreen: Constructed from item.packaging_img: $imageUrl');
      } 
      // Fallback to part_img
      else if (item['part_img'] != null &&
          item['part_img'].toString().isNotEmpty) {
        final imgPath = item['part_img'].toString();
        final cleanPath = imgPath.startsWith('/') ? imgPath.substring(1) : imgPath;
        imageUrl = imageBaseUrl + cleanPath;
        print('ScanScreen: Fallback to item.part_img: $imageUrl');
      }
    }

    // Validate final URL
    if (imageUrl != null) {
      // Ensure URL is properly formatted
      if (!imageUrl.startsWith('http')) {
        imageUrl = imageBaseUrl + imageUrl;
      }
      
      // Clean up any double slashes in path (but preserve http://)
      imageUrl = imageUrl.replaceAll(RegExp(r'(?<!:)//+'), '/');
      
      print('ScanScreen: Final validated URL: $imageUrl');
    } else {
      print('ScanScreen: No valid image URL found in response data');
    }

    return imageUrl;
  }

  Future<void> _storeByErp(String erpCode) async {
    if (_currentSlot == null) return;

    final response = await _apiService.storeByErp(
      erpCode: erpCode,
      slotName: _currentSlot!.slotName,
    );

    if (response['success'] == true) {
      final data = response['data'];
      setState(() {
        _scanState = ScanState.completed;
        _currentQty = data['current_qty'] ?? _currentQty + 1;
        _availableController.text = '${_capacity - _currentQty}/$_capacity';
        _scanController.clear();
      });

      _showSuccessMessage(response['message'] ?? 'Item stored successfully');

      // Check if slot is full
      if (_currentQty >= _capacity) {
        _showSlotFullDialog();
      }
    } else {
      // Handle specific error cases
      final data = response['data'];
      if (data != null && data['lot_no'] != null) {
        throw ApiException(
          message: response['message'] ?? 'Lot number already exists',
          statusCode: 409,
          data: response,
        );
      } else if (data != null && data['will_exceed_by'] != null) {
        throw ApiException(
          message: response['message'] ?? 'Slot capacity exceeded',
          statusCode: 409,
          data: response,
        );
      } else {
        throw ApiException(
          message: response['message'] ?? 'Failed to store item',
          statusCode: 400,
          data: response,
        );
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSlotFullDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(width: 8),
              Text('Slot Full'),
            ],
          ),
          content: Text(
            'Slot ${_currentSlot?.slotName} is now full ($_currentQty/$_capacity).\n\nWhat would you like to do next?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetScan();
              },
              child: const Text('Scan Another Slot'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/main-menu');
              },
              child: const Text('Back to Menu'),
            ),
          ],
        );
      },
    );
  }

  void _resetScan() {
    setState(() {
      _scanState = ScanState.initial;
      _currentSlot = null;
      _packageImageUrl = null;
      _errorMessage = null;
      _currentQty = 0;
      _capacity = 0;

      _partNoController.clear();
      _rackController.clear();
      _availableController.clear();
      _scanController.clear();
    });
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color:
                    readOnly
                        ? const Color(0xFFE5E7EB)
                        : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}