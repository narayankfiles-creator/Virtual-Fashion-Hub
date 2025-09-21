import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'landing_page.dart';

// Function for downloading image in web
void downloadImageWeb(Uint8List bytes, String filename) {
  if (kIsWeb) {
    final base64Str = base64Encode(bytes);
    js.context.callMethod('eval', [
      '''
      var link = document.createElement('a');
      link.href = 'data:image/png;base64,$base64Str';
      link.download = '$filename';
      link.click();
      '''
    ]);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseAuth.instance.signOut(); // For testing, force logout
    }
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  runApp(const VirtualApp());
}

class VirtualApp extends StatelessWidget {
  const VirtualApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Fashion Hub',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: Colors.grey.shade100,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/auth': (context) => const AuthWrapper(),
        '/home': (context) => const VirtualHomeScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/home');
          });
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
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String _errorMessage = '';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text);
      } else {
        await _auth.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Authentication error';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 80 : (isMobile ? 16 : 24),
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, '/'),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.arrow_back, color: Colors.deepPurple.shade700),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: isMobile ? 28 : 32,
                            height: isMobile ? 28 : 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.deepPurple, Colors.teal, Colors.green],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.auto_fix_high, color: Colors.white, size: isMobile ? 16 : 20),
                          ),
                          SizedBox(width: 8),
                          if (!isMobile)
                            Flexible(
                              child: Text(
                                'Virtual Fashion Hub',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple.shade800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Auth Form
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.1),
                              blurRadius: 30,
                              offset: Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.deepPurple, Colors.teal, Colors.green],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(Icons.person, color: Colors.white, size: 40),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _isLogin ? 'Welcome Back!' : 'Join Fashion Hub',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isLogin ? 'Sign in to continue your virtual try-on journey' : 'Create account and start trying on styles',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            
                            // Email Field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.poppins(),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined, color: Colors.deepPurple.shade400),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Password Field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: TextField(
                                controller: _passwordController,
                                obscureText: true,
                                style: GoogleFonts.poppins(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline, color: Colors.deepPurple.shade400),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                                ),
                              ),
                            ),
                            
                            if (_errorMessage.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: GoogleFonts.poppins(
                                        color: Colors.red.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                            ],
                            
                            const SizedBox(height: 24),
                            
                            // Auth Button
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: _isLoading ? null : _authenticate,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.deepPurple, Colors.teal, Colors.green],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.deepPurple.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: _isLoading
                                      ? const Center(
                                          child: SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          _isLogin ? 'Sign In' : 'Create Account',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Switch Auth Mode
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _errorMessage = '';
                                });
                              },
                              child: Text(
                                _isLogin
                                    ? 'Need an account? Sign up here'
                                    : 'Already have an account? Sign in here',
                                style: GoogleFonts.poppins(
                                  color: Colors.deepPurple.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

class VirtualHomeScreen extends StatefulWidget {
  const VirtualHomeScreen({super.key});

  @override
  State<VirtualHomeScreen> createState() => _VirtualHomeScreenState();
}

class _VirtualHomeScreenState extends State<VirtualHomeScreen> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Uint8List? personImage;
  Uint8List? garmentImage;
  Uint8List? resultImage;
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
  String selectedModel = 'top garment';
  
  final String _pageVersion = 'v4.0';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> modelChoices = const [
    {'value': 'top garment', 'label': 'Top Garment', 'description': 'Shirts, Blouses'},
    {'value': 'bottom garment', 'label': 'Bottom Garment', 'description': 'Pants, Skirts'},
    {'value': 'full-body', 'label': 'Full Body', 'description': 'Dresses, Complete Outfits'},
    {'value': 'eyewear', 'label': 'Eyewear', 'description': 'Glasses, Sunglasses'},
    {'value': 'footwear', 'label': 'Footwear', 'description': 'Shoes, Boots'},
  ];

  // STATIC API URL - Using your reserved ngrok domain
  final String apiUrl = 'https://interparietal-unpretentious-collin.ngrok-free.app';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String get userEmail {
    var email = _auth.currentUser?.email;
    if (email == null || email.isEmpty) return 'User';
    return email;
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  Future<void> pickImage(bool isPerson) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          if (isPerson) {
            personImage = result.files.single.bytes!;
          } else {
            garmentImage = result.files.single.bytes!;
          }
          errorMessage = null;
          resultImage = null;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error selecting image: $e';
      });
    }
  }

  Future<String?> _getToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      return await user.getIdToken();
    } catch (_) {
      return null;
    }
  }

  String _mapModelChoice(String flutterChoice) {
    switch (flutterChoice) {
      case 'bottom garment':
      case 'full-body':
        return 'full-body';
      case 'top garment':
        return 'top garment';
      case 'eyewear':
        return 'eyewear';
      case 'footwear':
        return 'footwear';
      default:
        return 'top garment';
    }
  }

  Future<void> performTryOn() async {
    if (personImage == null || garmentImage == null) {
      setState(() {
        errorMessage = 'Please upload both person and garment images';
      });
      return;
    }
    
    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
      resultImage = null;
    });
    
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No auth token');
      final request = http.MultipartRequest('POST', Uri.parse('$apiUrl/api/virtual-tryon'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes('person_image', personImage!, filename: 'person.png'));
      request.files.add(http.MultipartFile.fromBytes('garment_image', garmentImage!, filename: 'garment.png'));
      request.fields['model_choice'] = _mapModelChoice(selectedModel);

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      if (streamedResponse.statusCode == 200) {
        final jsonResp = json.decode(responseBody);
        if (jsonResp['success'] == true) {
          setState(() {
            resultImage = base64.decode(jsonResp['result_image']);
            successMessage = 'Virtual try-on completed in ${jsonResp['processing_time']} seconds';
          });
        } else {
          setState(() {
            errorMessage = jsonResp['message'] ?? 'Failed to process try-on';
          });
        }
      } else if (streamedResponse.statusCode == 401) {
        setState(() {
          errorMessage = 'Unauthenticated. Please login again.';
        });
        await _signOut();
      } else {
        setState(() {
          errorMessage = 'Server error: ${streamedResponse.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> downloadImage() async {
    if (resultImage == null) return;
    try {
      final filename = 'virtual_tryon_${DateTime.now().millisecondsSinceEpoch}.png';
      downloadImageWeb(resultImage!, filename);
      setState(() {
        successMessage = 'Downloaded successfully';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to download: $e';
      });
    }
  }

  Widget buildImageCard(String title, Uint8List? image, VoidCallback onTap, IconData icon) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;
    final isMobile = screenWidth < 600;
    
    return Container(
      width: isWide ? 300 : double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.deepPurple, Colors.teal]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: isMobile ? 20 : 24, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Container(
            height: isMobile ? 180 : (isWide ? 250 : 200),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(image, fit: BoxFit.contain),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: isMobile ? 32 : (isWide ? 48 : 36), color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to upload\n$title',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 12 : (isWide ? 14 : 12),
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                  ),
          ),
          SizedBox(height: isMobile ? 16 : 20),
          if (image != null)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh, size: 16, color: Colors.teal.shade700),
                          SizedBox(width: 4),
                          Text('Change', style: GoogleFonts.poppins(fontSize: 12, color: Colors.teal.shade700)),
                        ],
                      ),
                    ),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (title.contains("Person")) {
                          personImage = null;
                        } else {
                          garmentImage = null;
                        }
                        resultImage = null;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: Colors.red.shade700),
                          SizedBox(width: 4),
                          Text('Remove', style: GoogleFonts.poppins(fontSize: 12, color: Colors.red.shade700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.deepPurple.shade100, Colors.teal.shade100]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upload, color: Colors.deepPurple.shade700),
                      SizedBox(width: 8),
                      Text(
                        'Upload Image',
                        style: GoogleFonts.poppins(
                          color: Colors.deepPurple.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: isMobile ? 14 : 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModelTile(Map<String, String> choice, bool isWide, bool isMobile) {
    final isSelected = selectedModel == choice['value'];
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedModel = choice['value']!;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          key: ValueKey('${choice['value']}_$_pageVersion'),
          padding: EdgeInsets.all(isMobile ? 8 : (isWide ? 16 : 12)),
          decoration: BoxDecoration(
            gradient: isSelected 
              ? LinearGradient(colors: [Colors.deepPurple.shade100, Colors.teal.shade100])
              : null,
            color: isSelected ? null : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.deepPurple.shade300 : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ] : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForChoice(choice['value']!),
                color: isSelected ? Colors.deepPurple : Colors.grey.shade600,
                size: isMobile ? 16 : (isWide ? 24 : 20),
              ),
              SizedBox(height: isMobile ? 4 : 8),
              Text(
                choice['label']!,
                style: GoogleFonts.poppins(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: isMobile ? 10 : (isWide ? 14 : 12),
                  color: isSelected ? Colors.deepPurple.shade800 : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isMobile ? 2 : 4),
              Text(
                choice['description']!,
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 8 : (isWide ? 10 : 9),
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForChoice(String value) {
    switch (value) {
      case 'top garment':
        return Icons.checkroom;
      case 'bottom garment':
        return Icons.foundation;
      case 'full-body':
        return Icons.person;
      case 'eyewear':
        return Icons.visibility;
      case 'footwear':
        return Icons.directions_walk;
      default:
        return Icons.checkroom;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;
    final isMobile = screenWidth < 600;

    return Scaffold(
      key: ValueKey(_pageVersion),
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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 80 : (isMobile ? 16 : 24),
                  vertical: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                        SizedBox(width: 12),
                        if (!isMobile)
                          Text(
                            'Virtual Fashion Hub',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade800,
                            ),
                          ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'logout') _signOut();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  userEmail,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.red[600]),
                              const SizedBox(width: 8),
                              Text('Logout', style: TextStyle(color: Colors.red[600])),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.deepPurple, Colors.teal]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: isMobile ? 12 : 16,
                              backgroundColor: Colors.white,
                              child: Text(
                                userEmail.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: Colors.deepPurple[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 12 : 14,
                                ),
                              ),
                            ),
                            if (isWide) ...[
                              SizedBox(width: 8),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 120),
                                child: Text(
                                  userEmail.split('@')[0],
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : (isMobile ? 16 : 24)),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Welcome Section
                        Container(
                          padding: EdgeInsets.all(isMobile ? 16 : (isWide ? 32 : 24)),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.1),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Welcome back, ${userEmail.split('@').first}!',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 20 : (isWide ? 28 : 24),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple.shade800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Upload your photos and see AI-generated virtual try-on results',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 12 : (isWide ? 16 : 14),
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Connected to: $apiUrl',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.green[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Messages
                        if (errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade600),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: GoogleFonts.poppins(color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (successMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.green.shade600),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    successMessage!,
                                    style: GoogleFonts.poppins(color: Colors.green.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Image Upload Section
                        if (isWide)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildImageCard("Person Image", personImage, () => pickImage(true), Icons.person),
                              buildImageCard("Garment Image", garmentImage, () => pickImage(false), Icons.checkroom),
                            ],
                          )
                        else
                          Column(
                            children: [
                              buildImageCard("Person Image", personImage, () => pickImage(true), Icons.person),
                              SizedBox(height: 24),
                              buildImageCard("Garment Image", garmentImage, () => pickImage(false), Icons.checkroom),
                            ],
                          ),

                        const SizedBox(height: 32),

                        // Model Selection
                        Container(
                          key: ValueKey('model_selection_$_pageVersion'),
                          width: double.infinity,
                          padding: EdgeInsets.all(isMobile ? 16 : 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.1),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Select Garment Type',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 16 : (isWide ? 20 : 18),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple.shade800,
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              if (isWide)
                                Column(
                                  children: [
                                    Row(
                                      children: modelChoices.take(3).map((choice) => 
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 4),
                                            child: _buildModelTile(choice, isWide, isMobile)
                                          )
                                        )
                                      ).toList(),
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 4),
                                            child: _buildModelTile(modelChoices[3], isWide, isMobile)
                                          )
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 4),
                                            child: _buildModelTile(modelChoices[4], isWide, isMobile)
                                          )
                                        ),
                                        Expanded(child: SizedBox()),
                                      ],
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: _buildModelTile(modelChoices[0], isWide, isMobile)),
                                        SizedBox(width: 8),
                                        Expanded(child: _buildModelTile(modelChoices[1], isWide, isMobile)),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(child: _buildModelTile(modelChoices[2], isWide, isMobile)),
                                        SizedBox(width: 8),
                                        Expanded(child: _buildModelTile(modelChoices[3], isWide, isMobile)),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    _buildModelTile(modelChoices[4], isWide, isMobile),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Generate Button
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: isLoading ? null : performTryOn,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 18, 
                                horizontal: isMobile ? 24 : (isWide ? 48 : 32)
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
                              child: isLoading
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Text(
                                          'Processing...',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: isMobile ? 14 : (isWide ? 16 : 14),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.auto_fix_high, color: Colors.white, size: isMobile ? 20 : 24),
                                        SizedBox(width: 12),
                                        Text(
                                          'Generate Virtual Try-On',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isMobile ? 14 : (isWide ? 18 : 16),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Results Section
                        if (resultImage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isMobile ? 16 : (isWide ? 32 : 24)),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.15),
                                  blurRadius: 25,
                                  offset: Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.auto_awesome, color: Colors.amber, size: isMobile ? 24 : 32),
                                    SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        'Your Virtual Try-On Result',
                                        style: GoogleFonts.poppins(
                                          fontSize: isMobile ? 18 : (isWide ? 24 : 20),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple.shade800,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isMobile ? 16 : 24),
                                
                                Container(
                                  width: double.infinity,
                                  constraints: BoxConstraints(
                                    maxHeight: isMobile ? 300 : (isWide ? 500 : 400),
                                    minHeight: isMobile ? 150 : 200,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.memory(
                                      resultImage!,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                    ),
                                  ),
                                ),
                                
                                SizedBox(height: isMobile ? 16 : 24),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: downloadImage,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 20 : (isWide ? 32 : 24), 
                                        vertical: 16
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.green.shade600, Colors.teal.shade600],
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.green.withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.download, color: Colors.white, size: isMobile ? 20 : 24),
                                          SizedBox(width: 8),
                                          Text(
                                            'Download Image',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: isMobile ? 14 : (isWide ? 16 : 14),
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
                        ] else if (isLoading) ...[
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isMobile ? 16 : (isWide ? 32 : 24)),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Processing Your Virtual Try-On',
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 16 : (isWide ? 20 : 18),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple.shade800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 24),
                                Container(
                                  height: isMobile ? 150 : 200,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: isMobile ? 40 : 60,
                                          height: isMobile ? 40 : 60,
                                          child: CircularProgressIndicator(
                                            color: Colors.deepPurple,
                                            strokeWidth: 4,
                                          ),
                                        ),
                                        SizedBox(height: 24),
                                        Text(
                                          'AI is creating your virtual try-on...\nThis may take a few moments',
                                          style: GoogleFonts.poppins(
                                            fontSize: isMobile ? 14 : 16,
                                            color: Colors.deepPurple.shade600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 40),
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
}
