import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _floatingController;
  late AnimationController _beforeAfterController;
  late Animation<double> _heroFadeAnimation;
  late Animation<Offset> _heroSlideAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _beforeAfterAnimation;

  final ScrollController _scrollController = ScrollController();
  bool _showFeatures = false;
  bool _showCTA = false;
  bool _showDemoModal = false;

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _beforeAfterController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _heroFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutCubic,
    ));

    _heroSlideAnimation = Tween<Offset>(
      begin: const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutCubic,
    ));

    _floatingAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _beforeAfterAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _beforeAfterController,
      curve: Curves.easeInOut,
    ));

    _heroController.forward();
    _floatingController.repeat(reverse: true);
    _beforeAfterController.repeat(reverse: true);

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final scrollPercent = currentScroll / maxScroll;

    if (scrollPercent > 0.3 && !_showFeatures) {
      setState(() {
        _showFeatures = true;
      });
    }

    if (scrollPercent > 0.7 && !_showCTA) {
      setState(() {
        _showCTA = true;
      });
    }
  }

  void _showDemo() {
    setState(() {
      _showDemoModal = true;
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _floatingController.dispose();
    _beforeAfterController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWide = screenWidth > 800;
    final isMobile = screenWidth < 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade50,
              Colors.teal.shade50,
              Colors.green.shade50,
            ],
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Stack(
                children: [
                  // Floating animated elements
                  ...List.generate(3, (index) => _buildFloatingElement(index, screenWidth)),
                  
                  Column(
                    children: [
                      // Header Section
                      _buildHeader(isWide, isMobile),
                      
                      // Hero Section
                      _buildHeroSection(isWide, isMobile, screenHeight),
                      
                      // Features Section
                      _buildFeaturesSection(isWide, isMobile),
                      
                      // Interactive Demo Section
                      _buildDemoSection(isWide, isMobile),
                      
                      // Before/After Gallery
                      _buildGallerySection(isWide, isMobile),
                      
                      // Final CTA Section
                      _buildFinalCTA(isWide, isMobile),
                      
                      // Footer
                      _buildFooter(),
                    ],
                  ),
                ],
              ),
            ),
            
            // Demo Modal
            if (_showDemoModal) _buildDemoModal(isWide),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingElement(int index, double screenWidth) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Positioned(
          left: (index * (screenWidth / 3)),
          top: 100 + (index * 200.0) + _floatingAnimation.value,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  [
                    Colors.deepPurple.withOpacity(0.2),
                    Colors.teal.withOpacity(0.2),
                    Colors.green.withOpacity(0.2),
                  ][index % 3],
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isWide, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : (isMobile ? 16 : 24),
        vertical: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isMobile ? 32 : 40,
                  height: isMobile ? 32 : 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.teal, Colors.green],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_fix_high, color: Colors.white, size: isMobile ? 16 : 20),
                ),
                SizedBox(width: isMobile ? 8 : 12),
                if (!isMobile)
                  Flexible(
                    child: Text(
                      'Virtual Fashion Hub',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 18 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/auth'),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24, 
                  vertical: isMobile ? 8 : 12
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.teal],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Log in',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isWide, bool isMobile, double screenHeight) {
    return Container(
      height: screenHeight * (isMobile ? 0.7 : 0.8),
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : (isMobile ? 16 : 24),
      ),
      child: isWide 
        ? Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildHeroContent(isWide, isMobile),
              ),
              Expanded(
                flex: 1,
                child: _buildAnimatedHeroVisual(),
              ),
            ],
          )
        : _buildHeroContent(isWide, isMobile),
    );
  }

  Widget _buildHeroContent(bool isWide, bool isMobile) {
    return SlideTransition(
      position: _heroSlideAnimation,
      child: FadeTransition(
        opacity: _heroFadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade100, Colors.teal.shade100],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '✨ AI-Powered Fashion Experience',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
            ),
            SizedBox(height: isMobile ? 16 : 24),
            Text(
              'Try Before\nYou Buy',
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 32 : (isWide ? 72 : 48),
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade800,
                height: 1.1,
              ),
              textAlign: isMobile ? TextAlign.center : TextAlign.left,
            ),
            SizedBox(height: isMobile ? 16 : 24),
            Text(
              'Experience the future of fashion with our AI virtual try-on technology. Upload your photo and see how clothes, accessories, and shoes look on you instantly.',
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 14 : 18,
                color: Colors.grey[700],
                height: 1.6,
              ),
              textAlign: isMobile ? TextAlign.center : TextAlign.left,
            ),
            SizedBox(height: isMobile ? 24 : 40),
            isMobile 
              ? Column(
                  children: [
                    _buildPrimaryButton(isMobile),
                    SizedBox(height: 16),
                    _buildSecondaryButton(isMobile),
                  ],
                )
              : Row(
                  mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    _buildPrimaryButton(isMobile),
                    SizedBox(width: 20),
                    _buildSecondaryButton(isMobile),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(bool isMobile) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/auth'),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 32, 
            vertical: 16
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.teal, Colors.green],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.4),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.rocket_launch, color: Colors.white, size: isMobile ? 20 : 24),
              SizedBox(width: 8),
              Text(
                'Get Started Free',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(bool isMobile) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _showDemo,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 24, 
            vertical: 16
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.deepPurple.shade300),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_outline, color: Colors.deepPurple, size: isMobile ? 20 : 24),
              SizedBox(width: 8),
              Text(
                'Watch Demo',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Animated Hero Visual with Before/After Person
  Widget _buildAnimatedHeroVisual() {
    return Container(
      height: 500,
      child: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple.withOpacity(0.1),
                  Colors.teal.withOpacity(0.1),
                  Colors.green.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          // Animated Before/After Person
          Center(
            child: AnimatedBuilder(
              animation: _beforeAfterAnimation,
              builder: (context, child) {
                return Container(
                  width: 320,
                  height: 480,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.2),
                        blurRadius: 25,
                        offset: Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Column(
                      children: [
                        // Animated header
                        Container(
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.deepPurple, Colors.teal],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Virtual Fashion Hub',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        // Before/After animated content
                        Expanded(
                          child: AnimatedContainer(
                            duration: Duration(seconds: 1),
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Animated person transformation
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        colors: _beforeAfterAnimation.value > 0.5
                                          ? [Colors.green.shade50, Colors.teal.shade50]
                                          : [Colors.grey.shade100, Colors.grey.shade50],
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        // Before state
                                        AnimatedOpacity(
                                          duration: Duration(milliseconds: 500),
                                          opacity: _beforeAfterAnimation.value > 0.5 ? 0.0 : 1.0,
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 80,
                                                  height: 120,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade300,
                                                    borderRadius: BorderRadius.circular(40),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.person, size: 40, color: Colors.grey.shade600),
                                                      SizedBox(height: 8),
                                                      Container(
                                                        width: 60,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey.shade400,
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 16),
                                                Text(
                                                  'BEFORE',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // After state
                                        AnimatedOpacity(
                                          duration: Duration(milliseconds: 500),
                                          opacity: _beforeAfterAnimation.value > 0.5 ? 1.0 : 0.0,
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 80,
                                                  height: 120,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [Colors.deepPurple.shade200, Colors.teal.shade200],
                                                    ),
                                                    borderRadius: BorderRadius.circular(40),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.person, size: 40, color: Colors.deepPurple),
                                                      SizedBox(height: 8),
                                                      Container(
                                                        width: 60,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [Colors.blue.shade300, Colors.purple.shade300],
                                                          ),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 16),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'AFTER',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.deepPurple.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                // Generate button
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.deepPurple, Colors.teal],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Text(
                                    'Generate Try-On',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Floating elements
          Positioned(
            top: 60,
            right: 30,
            child: AnimatedBuilder(
              animation: _floatingAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatingAnimation.value),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_fix_high, color: Colors.green.shade700, size: 24),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(bool isWide, bool isMobile) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 800),
      opacity: _showFeatures ? 1.0 : 0.0,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 800),
        transform: Matrix4.translationValues(
          _showFeatures ? 0 : (isWide ? -100 : 0), 0, 0,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 80 : (isMobile ? 16 : 24),
            vertical: isMobile ? 80 : 120,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.green.shade50],
            ),
          ),
          child: Column(
            children: [
              Text(
                'Revolutionary Try-On Experience',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 24 : (isWide ? 48 : 32),
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                'See yourself in any outfit with our advanced AI technology',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 14 : 18,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 40 : 80),
              if (isWide)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFeatureCard(
                      'Virtual Clothing',
                      'Try on shirts, dresses, jackets and complete outfits with perfect fit simulation.',
                      Icons.checkroom,
                      [Colors.purple, Colors.deepPurple],
                      isMobile,
                    ),
                    _buildFeatureCard(
                      'Accessories & Shoes',
                      'See how sunglasses, hats, jewelry, and footwear complement your style.',
                      Icons.visibility,
                      [Colors.teal, Colors.cyan],
                      isMobile,
                    ),
                    _buildFeatureCard(
                      'Real-Time Results',
                      'Instant photo-realistic results with accurate lighting and shadows.',
                      Icons.flash_on,
                      [Colors.green, Colors.lightGreen],
                      isMobile,
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildFeatureCard(
                      'Virtual Clothing',
                      'Try on shirts, dresses, jackets and complete outfits.',
                      Icons.checkroom,
                      [Colors.purple, Colors.deepPurple],
                      isMobile,
                    ),
                    SizedBox(height: 40),
                    _buildFeatureCard(
                      'Accessories & Shoes',
                      'See how accessories and footwear complement your style.',
                      Icons.visibility,
                      [Colors.teal, Colors.cyan],
                      isMobile,
                    ),
                    SizedBox(height: 40),
                    _buildFeatureCard(
                      'Real-Time Results',
                      'Instant photo-realistic results with accurate lighting.',
                      Icons.flash_on,
                      [Colors.green, Colors.lightGreen],
                      isMobile,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, List<Color> gradientColors, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 300,
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: isMobile ? 60 : 80,
            height: isMobile ? 60 : 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white, size: isMobile ? 30 : 40),
          ),
          SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 14 : 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDemoSection(bool isWide, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : (isMobile ? 16 : 24),
        vertical: isMobile ? 60 : 100,
      ),
      child: Column(
        children: [
          Text(
            'How It Works',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 24 : (isWide ? 48 : 32),
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade800,
            ),
          ),
          SizedBox(height: isMobile ? 30 : 60),
          if (isWide)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStepCard('1', 'Upload Photo', 'Take a selfie or upload your photo', Icons.camera_alt, isMobile),
                Icon(Icons.arrow_forward, size: 40, color: Colors.teal),
                _buildStepCard('2', 'Choose Items', 'Select clothes, shoes, or accessories', Icons.shopping_bag, isMobile),
                Icon(Icons.arrow_forward, size: 40, color: Colors.teal),
                _buildStepCard('3', 'See Results', 'Get instant realistic try-on results', Icons.auto_fix_high, isMobile),
              ],
            )
          else
            Column(
              children: [
                _buildStepCard('1', 'Upload Photo', 'Take a selfie or upload your photo', Icons.camera_alt, isMobile),
                SizedBox(height: 40),
                _buildStepCard('2', 'Choose Items', 'Select clothes, shoes, or accessories', Icons.shopping_bag, isMobile),
                SizedBox(height: 40),
                _buildStepCard('3', 'See Results', 'Get instant realistic try-on results', Icons.auto_fix_high, isMobile),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStepCard(String step, String title, String description, IconData icon, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 250,
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.teal.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        children: [
          Container(
            width: isMobile ? 50 : 60,
            height: isMobile ? 50 : 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.green],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Icon(icon, size: isMobile ? 30 : 40, color: Colors.teal),
          SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 12 : 14,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection(bool isWide, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : (isMobile ? 16 : 24),
        vertical: isMobile ? 60 : 100,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade50, Colors.white],
        ),
      ),
      child: Column(
        children: [
          Text(
            'See the Amazing Results',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 24 : (isWide ? 48 : 32),
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            'Real users, real transformations with our AI virtual try-on',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 14 : 18,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 40 : 60),
          if (isWide)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildExampleCard('Casual Wear', 'Perfect for everyday style', isMobile),
                _buildExampleCard('Business Attire', 'Professional and elegant', isMobile),
                _buildExampleCard('Party Outfits', 'Stand out in style', isMobile),
              ],
            )
          else
            Column(
              children: [
                _buildExampleCard('Casual Wear', 'Perfect for everyday style', isMobile),
                SizedBox(height: 30),
                _buildExampleCard('Business Attire', 'Professional and elegant', isMobile),
                SizedBox(height: 30),
                _buildExampleCard('Party Outfits', 'Stand out in style', isMobile),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(String title, String description, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 280,
      height: isMobile ? 300 : 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated before/after images
          Container(
            height: isMobile ? 200 : 250,
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedBuilder(
              animation: _beforeAfterAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade50, Colors.green.shade50],
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: Duration(seconds: 1),
                                width: _beforeAfterAnimation.value > 0.5 ? 40 : 50,
                                height: _beforeAfterAnimation.value > 0.5 ? 40 : 50,
                                child: Icon(
                                  Icons.person, 
                                  size: _beforeAfterAnimation.value > 0.5 ? 40 : 50, 
                                  color: Colors.grey.shade500
                                ),
                              ),
                              Text('BEFORE', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: Colors.teal),
                      Expanded(
                        child: AnimatedContainer(
                          duration: Duration(seconds: 1),
                          margin: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: _beforeAfterAnimation.value > 0.5 
                              ? LinearGradient(colors: [Colors.deepPurple.shade100, Colors.teal.shade100])
                              : LinearGradient(colors: [Colors.grey.shade100, Colors.grey.shade200]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: Duration(milliseconds: 500),
                                child: _beforeAfterAnimation.value > 0.5
                                  ? Icon(Icons.auto_awesome, size: 50, color: Colors.deepPurple, key: Key('after'))
                                  : Icon(Icons.person, size: 50, color: Colors.grey.shade500, key: Key('before')),
                              ),
                              Text('AFTER', style: GoogleFonts.poppins(fontSize: 10, color: Colors.deepPurple.shade600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalCTA(bool isWide, bool isMobile) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 800),
      opacity: _showCTA ? 1.0 : 0.0,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 800),
        transform: Matrix4.translationValues(
          _showCTA ? 0 : (isWide ? 100 : 0), 0, 0,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 80 : (isMobile ? 16 : 24),
            vertical: isMobile ? 60 : 100,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.shade800,
                Colors.teal.shade600,
                Colors.green.shade600,
              ],
            ),
          ),
          child: Column(
            children: [
              Text(
                'Ready to Transform Your\nShopping Experience?',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 24 : (isWide ? 48 : 32),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Text(
                'Join thousands of users who are already trying before they buy',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 14 : 18,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/auth'),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 32 : 48, 
                      vertical: 20
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_fix_high, color: Colors.deepPurple),
                        SizedBox(width: 12),
                        Text(
                          'Start Your Free Trial',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 16 : 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(40),
      color: Colors.deepPurple.shade900,
      child: Center(
        child: Text(
          '© 2025 Virtual Fashion Hub. All rights reserved.',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDemoModal(bool isWide) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.85,
            constraints: BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _showDemoModal = false),
                      icon: Icon(Icons.close, size: 30),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
                // Demo content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.deepPurple, Colors.teal, Colors.green],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.play_circle_filled, size: 40, color: Colors.white),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Interactive Demo',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade800,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'See how Virtual Fashion Hub works step by step:',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 30),
                        
                        // Demo steps
                        _buildDemoStep('1', 'Upload Your Photo', 'Take a clear selfie or upload your favorite photo.', Icons.camera_alt, Colors.blue),
                        SizedBox(height: 20),
                        _buildDemoStep('2', 'Choose Fashion Items', 'Select from clothing items, shoes, and accessories.', Icons.shopping_bag, Colors.purple),
                        SizedBox(height: 20),
                        _buildDemoStep('3', 'AI Magic Happens', 'Our AI creates a realistic try-on result in seconds.', Icons.auto_fix_high, Colors.green),
                        SizedBox(height: 20),
                        _buildDemoStep('4', 'Download & Share', 'Download the image and share with friends.', Icons.download, Colors.teal),
                        
                        SizedBox(height: 30),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _showDemoModal = false);
                              Navigator.pushNamed(context, '/auth');
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.deepPurple, Colors.teal, Colors.green],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurple.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Try It Now - Free!',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoStep(String number, String title, String description, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Icon(icon, size: 24, color: color),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
