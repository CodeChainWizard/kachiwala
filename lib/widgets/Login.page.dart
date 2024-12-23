import 'package:flutter/material.dart';
import 'package:newprg/home_page.dart';
import 'package:newprg/main.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void onLoginSuccess(BuildContext context) async {
    // Assuming login is successful, update login status
    await setLoginStatus(true);

    // Navigate to HomePage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }
  void _navigateToHomePage() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email == 'narayan' && password == 'kachiwala') {
     onLoginSuccess(context);
    }else if(email.isEmpty || password.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please Enter the Email and Password Both')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid email or password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Center(
                child: Container(
                  height: 100,
                  width: 100,
                  child: Image.asset("assets/images/kachiwala.png", fit: BoxFit.cover),
                  // child: SvgPicture.asset(
                  //   'assets/images/kachiwala.svg',
                  //   fit: BoxFit.cover,
                  // ),
                ),
                // child: Container(
                //   height: 60,
                //   width: 60,
                //   decoration: BoxDecoration(
                //     shape: BoxShape.circle,
                //     // color: Colors.black,
                //     image: DecorationImage(
                //       image: AssetImage('assets/images/kachiwala.svg'),
                //       fit: BoxFit.cover,
                //     ),
                //   ),
                // ),
              ),
              SizedBox(height: 24),
              // Title
              Text(
                'Log in',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              // Email Input Field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Enter your Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              // Password Input Field
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: 16),
              // Continue Button
              ElevatedButton(
                onPressed: _navigateToHomePage,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  backgroundColor: Colors.black,
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
