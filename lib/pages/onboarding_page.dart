import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';
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
          title: "Permissions Required",
          body:
              "We need camera access to track your exercises and usage stats permission to monitor your apps. Your privacy is important - all data is processed locally and never shared.",
          image: Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.security,
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
    final cameraStatus = await Permission.camera.request();
    final cameraGranted = cameraStatus.isGranted;
    
    // Check usage stats permission
    bool usageGranted = false;
    try {
      usageGranted = await UsageStats.checkUsagePermission() ?? false;
    } catch (e) {
      usageGranted = false;
    }
    
    if (!context.mounted) return;
    
    if (!cameraGranted || !usageGranted) {
      // Show dialog explaining that permissions are required
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Permissions Required'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Both permissions are required for the app to function:\n'),
                Row(
                  children: [
                    Icon(
                      cameraGranted ? Icons.check_circle : Icons.cancel,
                      color: cameraGranted ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Camera Access')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      usageGranted ? Icons.check_circle : Icons.cancel,
                      color: usageGranted ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Usage Stats Access')),
                  ],
                ),
                const SizedBox(height: 16),
                if (!usageGranted)
                  const Text(
                    'Tap "Grant Usage Access" to enable usage stats permission.\n\n'
                    'You will be taken to Android Settings where you need to:\n'
                    '1. Find "Push2Unlock" in the list\n'
                    '2. Toggle the switch to enable it\n'
                    '3. Return to the app and tap "Try Again"',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                if (!cameraGranted)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Camera permission can be granted directly in the app.',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'cancel');
              },
              child: const Text('Cancel'),
            ),
            if (!usageGranted)
              ElevatedButton(
                onPressed: () async {
                  // Request usage stats permission - this opens settings
                  await UsageStats.grantUsagePermission();
                  if (!context.mounted) return;
                  Navigator.pop(context, 'granted');
                },
                child: const Text('Grant Usage Access'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, 'retry');
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
      
      if (result == 'retry' || result == 'granted') {
        // Retry permission check
        await _completeOnboarding(context);
      }
      return;
    }
    
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    // Navigate to dashboard
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }
}
