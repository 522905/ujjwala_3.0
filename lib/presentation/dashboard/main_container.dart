import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/splash_screen.dart';
import '../auth/change_password_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Main Container with Navigation
///
/// Shows different UI based on user role:
/// - End Users: Bottom navigation (Home, My Application, Profile)
/// - Agents: Drawer navigation with more options

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;

  // End User screens (bottom navigation)
  final List<Widget> _userScreens = [
    const HomeScreen(),
    const Placeholder(), // MyApplicationScreen - to be implemented
    const ProfileScreen(),
  ];

  // Agent screen (single screen with drawer)
  Widget get _agentScreen => const HomeScreen(); // AgentDashboardScreen - to be implemented

  void _onBottomNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue[700],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  authProvider.isAgent
                      ? Icons.business_center
                      : Icons.person,
                  size: 48.sp,
                  color: Colors.white,
                ),
                SizedBox(height: 8.h),
                Text(
                  authProvider.isAgent ? 'Agent Portal' : 'Consumer Portal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Ujjwala 3.0',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),

          // Agent-only menu items
          if (authProvider.isAgent) ...[
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                setState(() => _currentIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Applications'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to ApplicationsListScreen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Applications screen - Coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Pre-Sureksha'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to PreSurekshaCaptureScreen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pre-Sureksha screen - Coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Sync Data'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement sync functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sync functionality - Coming soon')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.key),
              title: const Text('Change Password'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
          ],

          // Common menu items
          if (!authProvider.isAgent) ...[
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: _currentIndex == 0,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('My Application'),
              selected: _currentIndex == 1,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              selected: _currentIndex == 2,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2);
              },
            ),
            const Divider(),
          ],

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'Ujjwala 3.0',
                applicationVersion: 'v1.0.0',
                applicationLegalese: '© 2024 Arun Gas Services',
                children: [
                  SizedBox(height: 16.h),
                  const Text(
                    'PMUY for Migrant Households\n'
                    'LPG Connection Application System',
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final isAgent = authProvider.isAgent;

        return Scaffold(
          appBar: AppBar(
            title: Text(isAgent ? 'Agent Dashboard' : 'Ujjwala 3.0'),
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            actions: [
              if (!isAgent)
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // TODO: Show notifications
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications - Coming soon')),
                    );
                  },
                ),
            ],
          ),
          drawer: _buildDrawer(context, authProvider),
          body: isAgent
              ? _agentScreen
              : IndexedStack(
                  index: _currentIndex,
                  children: _userScreens,
                ),
          bottomNavigationBar: !isAgent
              ? BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: _onBottomNavTap,
                  selectedItemColor: Colors.blue[700],
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.description),
                      label: 'My Application',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}
