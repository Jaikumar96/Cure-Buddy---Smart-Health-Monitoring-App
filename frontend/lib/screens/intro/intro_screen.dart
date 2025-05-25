import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'; // Make sure this package is in your pubspec.yaml
// import '../auth/login_screen.dart'; // Not strictly needed if using named routes for navigation

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key}); // Added const and super.key

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _controller = PageController(); // Made final
  bool onLastPage = false;

  @override
  void initState() {
    super.initState();
    print("IntroScreen: initState CALLED");
  }

  @override
  void dispose() {
    _controller.dispose(); // Good practice to dispose controllers
    print("IntroScreen: dispose CALLED");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("IntroScreen: build METHOD CALLED - onLastPage: $onLastPage");
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _controller,
              onPageChanged: (index) {
                print("IntroScreen: PageChanged - new index: $index");
                setState(() {
                  onLastPage = index == 2; // Assuming 3 pages (0, 1, 2)
                });
              },
              children: [
                buildPage('assets/intro1.gif', 'We help you grow your business', 'Our aim is to fulfill the demand...'),
                buildPage('assets/intro2.gif', 'We will create best app', 'Our aim is to fulfill the demand...'),
                buildPage('assets/intro3.gif', 'Best health team for you', 'Your smart cure assistant'),
              ],
            ),
            Container(
              alignment: const Alignment(0, 0.75), // Added const
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Page Indicator
                  SmoothPageIndicator(
                      controller: _controller,
                      count: 3,
                      effect: const WormEffect( // Example effect, choose one you like
                        dotHeight: 10,
                        dotWidth: 10,
                        activeDotColor: Colors.deepPurple, // Match your theme
                        paintStyle: PaintingStyle.fill,
                      ),
                      onDotClicked: (index) {
                        print("IntroScreen: Dot clicked - index: $index");
                        _controller.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeIn,
                        );
                      }
                  ),

                  // Next / Get Started Button
                  onLastPage
                      ? ElevatedButton(
                      onPressed: () {
                        print("IntroScreen: Get Started button PRESSED");
                        if (mounted) { // Good practice to check mounted before async navigation
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      child: const Text("Get Started")) // Added const
                      : ElevatedButton(
                      onPressed: () {
                        print("IntroScreen: Next button PRESSED");
                        _controller.nextPage(
                            duration: const Duration(milliseconds: 500), // Added const
                            curve: Curves.easeIn);
                      },
                      child: const Text("Next")), // Added const
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildPage(String imagePath, String title, String subtitle) {
    print("IntroScreen: buildPage CALLED for image: $imagePath");
    // Ensure your assets are correctly defined in pubspec.yaml
    // and the files exist at the specified paths
    // e.g., assets/intro1.gif, assets/intro2.gif, assets/intro3.gif
    return Padding(
      padding: const EdgeInsets.all(40.0), // Added const
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placeholder if image loading is an issue, or use Image.asset directly
          // Make sure the GIF files are not excessively large
          Image.asset(imagePath, height: 250,
            errorBuilder: (context, error, stackTrace) {
              print("IntroScreen: Error loading image $imagePath: $error");
              return const Icon(Icons.error_outline, size: 100, color: Colors.red); // Placeholder for error
            },
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(seconds: 1),
                curve: Curves.easeOut,
                child: child,
              );
            },
          ),
          const SizedBox(height: 30), // Added const
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), // Added const
          const SizedBox(height: 20), // Added const
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }
}