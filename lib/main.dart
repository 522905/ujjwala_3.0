import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'data/local/hive_service.dart';
import 'data/services/api_service.dart';
import 'data/services/tus_upload_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/application_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/application_provider.dart';
import 'providers/submission_provider.dart';
import 'presentation/auth/splash_screen.dart';

/// Main Entry Point
///
/// Ujjwala 3.0 - PMUY for Migrant Households
/// LPG Connection Application System

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive database
    await HiveService.init();
    print('✅ Hive initialized successfully');
  } catch (e) {
    print('❌ Hive initialization failed: $e');
    // Continue anyway - app will show error if Hive is required
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services and Repositories
        Provider(
          create: (_) => ApiService(),
        ),
        Provider(
          create: (_) => TusUploadService(),
        ),
        Provider(
          create: (context) => AuthRepository(context.read<ApiService>()),
        ),
        Provider(
          create: (context) => ApplicationRepository(
            context.read<ApiService>(),
            context.read<TusUploadService>(),
          ),
        ),

        // State Management Providers
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<ApplicationProvider>(
          create: (_) => ApplicationProvider(),
        ),
        ChangeNotifierProvider<SubmissionProvider>(
          create: (context) => SubmissionProvider(
            context.read<ApplicationRepository>(),
          ),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812), // iPhone 11 Pro dimensions
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            title: 'Ujjwala 3.0',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: const Color(0xFF2196F3),
              useMaterial3: true,
              fontFamily: 'Roboto',

              // AppBar Theme
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: false,
              ),

              // Input Decoration Theme
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),

              // Elevated Button Theme
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // Outlined Button Theme
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  side: BorderSide(color: Colors.blue[700]!),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // Card Theme
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              // Checkbox Theme
              checkboxTheme: CheckboxThemeData(
                fillColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.blue[700];
                  }
                  return null;
                }),
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
