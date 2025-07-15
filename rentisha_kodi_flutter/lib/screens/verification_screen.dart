import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class VerificationScreen extends StatefulWidget {
  final String email;
  final String phone;

  VerificationScreen({required this.email, required this.phone});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> with TickerProviderStateMixin {
  final List<TextEditingController> _emailControllers = List.generate(6, (_) => TextEditingController());
  final List<TextEditingController> _smsControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _emailFocusNodes = List.generate(6, (_) => FocusNode());
  final List<FocusNode> _smsFocusNodes = List.generate(6, (_) => FocusNode());
  
  bool _isEmailVerified = false;
  bool _isSmsVerified = false;
  bool _isLoading = false;
  int _emailResendCountdown = 0;
  int _smsResendCountdown = 0;
  int _currentStep = 0; // 0: Email verification, 1: SMS verification, 2: Complete
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _successController;
  late Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _successController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _successScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _successController.dispose();
    _emailControllers.forEach((controller) => controller.dispose());
    _smsControllers.forEach((controller) => controller.dispose());
    _emailFocusNodes.forEach((node) => node.dispose());
    _smsFocusNodes.forEach((node) => node.dispose());
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _emailResendCountdown = 60;
      _smsResendCountdown = 60;
    });
    
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_emailResendCountdown > 0) _emailResendCountdown--;
          if (_smsResendCountdown > 0) _smsResendCountdown--;
        });
        
        if (_emailResendCountdown == 0 && _smsResendCountdown == 0) {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _resendEmailCode() async {
    setState(() {
      _emailResendCountdown = 60;
    });
    
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Verification code sent to ${widget.email}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resendSmsCode() async {
    setState(() {
      _smsResendCountdown = 60;
    });
    
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('SMS code sent to ${widget.phone}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _verifyEmail() async {
    String code = _emailControllers.map((controller) => controller.text).join();
    if (code.length != 6) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _isEmailVerified = true;
    });

    _successController.forward();
    
    // Move to next step after delay
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentStep = 1;
        });
        _animationController.reset();
        _animationController.forward();
      }
    });
  }

  void _verifySms() async {
    String code = _smsControllers.map((controller) => controller.text).join();
    if (code.length != 6) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _isSmsVerified = true;
      _currentStep = 2;
    });

    _successController.forward();
  }

  void _completeVerification() {
    Navigator.pushReplacementNamed(context, '/main');
  }

  Widget _buildEmailVerification() {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Icon(Icons.email, color: Colors.blue[800], size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email Verification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    Text(
                      'Enter the 6-digit code sent to\n${widget.email}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 30),
        
        // Code Input Fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 45,
              child: TextField(
                controller: _emailControllers[index],
                focusNode: _emailFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
                  ),
                ),
                onChanged: (value) {
                  if (value.length == 1 && index < 5) {
                    _emailFocusNodes[index + 1].requestFocus();
                  }
                  if (value.isEmpty && index > 0) {
                    _emailFocusNodes[index - 1].requestFocus();
                  }
                  
                  // Check if all fields are filled
                  String code = _emailControllers.map((controller) => controller.text).join();
                  if (code.length == 6) {
                    _verifyEmail();
                  }
                },
              ),
            );
          }),
        ),
        
        SizedBox(height: 30),
        
        // Resend Button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive the code? ",
              style: TextStyle(color: Colors.grey[600]),
            ),
            TextButton(
              onPressed: _emailResendCountdown == 0 ? _resendEmailCode : null,
              child: Text(
                _emailResendCountdown == 0
                    ? 'Resend'
                    : 'Resend in ${_emailResendCountdown}s',
                style: TextStyle(
                  color: _emailResendCountdown == 0 ? Colors.blue[800] : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 20),
        
        // Loading Indicator
        if (_isLoading)
          Column(
            children: [
              CircularProgressIndicator(color: Colors.blue[800]),
              SizedBox(height: 16),
              Text('Verifying...', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
      ],
    );
  }

  Widget _buildSmsVerification() {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Icon(Icons.sms, color: Colors.green[800], size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMS Verification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    Text(
                      'Enter the 6-digit code sent to\n${widget.phone}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 30),
        
        // Code Input Fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 45,
              child: TextField(
                controller: _smsControllers[index],
                focusNode: _smsFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.green[800]!, width: 2),
                  ),
                ),
                onChanged: (value) {
                  if (value.length == 1 && index < 5) {
                    _smsFocusNodes[index + 1].requestFocus();
                  }
                  if (value.isEmpty && index > 0) {
                    _smsFocusNodes[index - 1].requestFocus();
                  }
                  
                  // Check if all fields are filled
                  String code = _smsControllers.map((controller) => controller.text).join();
                  if (code.length == 6) {
                    _verifySms();
                  }
                },
              ),
            );
          }),
        ),
        
        SizedBox(height: 30),
        
        // Resend Button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive the code? ",
              style: TextStyle(color: Colors.grey[600]),
            ),
            TextButton(
              onPressed: _smsResendCountdown == 0 ? _resendSmsCode : null,
              child: Text(
                _smsResendCountdown == 0
                    ? 'Resend'
                    : 'Resend in ${_smsResendCountdown}s',
                style: TextStyle(
                  color: _smsResendCountdown == 0 ? Colors.green[800] : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 20),
        
        // Loading Indicator
        if (_isLoading)
          Column(
            children: [
              CircularProgressIndicator(color: Colors.green[800]),
              SizedBox(height: 16),
              Text('Verifying...', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
      ],
    );
  }

  Widget _buildCompletion() {
    return Column(
      children: [
        ScaleTransition(
          scale: _successScale,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green[800],
            ),
          ),
        ),
        
        SizedBox(height: 30),
        
        Text(
          'Verification Complete!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
        
        SizedBox(height: 16),
        
        Text(
          'Your account has been successfully verified.\nYou can now access all features of Rentisha Kodi.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        
        SizedBox(height: 40),
        
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _completeVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[800],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Get Started',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Verification',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[900]!,
              Colors.blue[700]!,
              Colors.blue[500]!,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Progress Indicator
                    if (_currentStep < 2) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: _currentStep >= 0 ? Colors.white : Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: _currentStep >= 1 ? Colors.white : Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 20),
                      
                      Text(
                        _currentStep == 0 ? 'Step 1 of 2: Email Verification' : 'Step 2 of 2: SMS Verification',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    
                    SizedBox(height: 40),
                    
                    // Content
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: _currentStep == 0
                          ? _buildEmailVerification()
                          : _currentStep == 1
                              ? _buildSmsVerification()
                              : _buildCompletion(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 