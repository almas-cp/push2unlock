import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_page.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Stay Healthy, Stay Scrolling",
          body:
              "Push2Unlock helps you earn scroll time on your favorite apps by completing quick exercises. The more you move, the more you scroll!",
          image: Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          decoration: PageDecoration(
            titleTextStyle: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            bodyTextStyle: const TextStyle(fontSize: 18),
            bodyPadding: const EdgeInsets.all(24),
            imagePadding: const EdgeInsets.only(top: 80, bottom: 40),
          ),
        ),
        PageViewModel(
          title: "Camera Permission Required",
          body:
              "We need camera access to track your exercises using pose detection. Your privacy is important - video is processed locally and never stored or shared.",
          image: Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt,
                size: 100,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          decoration: PageDecoration(
            titleTextStyle: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            bodyTextStyle: const TextStyle(fontSize: 18),
            bodyPadding: const EdgeInsets.all(24),
            imagePadding: const EdgeInsets.only(top: 80, bottom: 40),
          ),
        ),
      ],
      onDone: () => _completeOnboarding(context),
      onSkip: () => _completeOnboarding(context),
      showSkipButton: true,
      skip: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: Theme.of(context).colorScheme.primary,
        color: Colors.grey.shade300,
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
    );
  }

  Future<void> _completeOnboarding(BuildContext context) async {
    // Request camera permission
    final status = await Permission.camera.request();
    
    if (!context.mounted) return;
    
    // Check if permission was granted
    if (status.isGranted) {
      // Mark onboarding as completed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);

      // Navigate to dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } else if (status.isDenied) {
      // Show dialog explaining why permission is needed
      _showPermissionDialog(context);
    } else if (status.isPermanentlyDenied) {
      // Guide user to app settings
      _showSettingsDialog(context);
    }
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Camera access is essential for tracking your exercises. Please grant permission to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _completeOnboarding(context);
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Camera permission is permanently denied. Please enable it in app settings to use Push2Unlock.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
