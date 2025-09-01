import 'package:flutter/material.dart';
import '../services/user_manager.dart';

class CustomNavbar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final VoidCallback? onLogoutSuccess;

  const CustomNavbar({
    super.key,
    this.showBackButton = true,
    this.onBackPressed,
    this.onLogoutSuccess,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Image.asset(
            'assets/images/sanoh-logo.png',
            height: 32,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_circle,
                  color: Color(0xFF6B7280),
                  size: 24,
                ),
                const SizedBox(height: 2),
                Text(
                  UserManager.username,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Color(0xFF6B7280)),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFF6B7280)),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            onSelected: (String value) {
              switch (value) {
                case 'profile':
                  _showProfileDialog(context);
                  break;
                case 'logout':
                  _showLogoutDialog(context);
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileRow('Username', UserManager.username),
              const SizedBox(height: 8),
              _buildProfileRow('Name', UserManager.name),
              const SizedBox(height: 8),
              _buildProfileRow('Role', UserManager.roleName),
              const SizedBox(height: 8),
              _buildProfileRow('Department', 'Production'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  await UserManager.logout();
                  
                  // Close loading indicator
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  
                  // Call logout success callback if provided
                  if (onLogoutSuccess != null) {
                    onLogoutSuccess!();
                  } else {
                    // Navigate to login screen
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/',
                      (route) => false,
                    );
                  }
                } catch (e) {
                  // Close loading indicator
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}