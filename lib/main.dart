import 'package:flutter/material.dart';
import 'package:miniproject/splashScreen.dart';
import 'package:miniproject/homescreen.dart';
import 'package:miniproject/AddExpenseScreen.dart';
import 'package:miniproject/ExpenseListScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add error handling for the entire app
  runZonedGuarded(() {
    runApp(FirebaseInitializerApp());
  }, (error, stackTrace) {
    print('Caught error in runZonedGuarded: $error');
    print('Stack trace: $stackTrace');
  });
}

class FirebaseInitializerApp extends StatelessWidget {
  // Use lazy initialization to improve startup time
  final Future<FirebaseApp> _initialization = Firebase.initializeApp(
    options: kIsWeb ? const FirebaseOptions(
      apiKey: "YOUR_API_KEY",
      authDomain: "YOUR_AUTH_DOMAIN",
      projectId: "YOUR_PROJECT_ID", 
      storageBucket: "YOUR_STORAGE_BUCKET",
      messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
      appId: "YOUR_APP_ID",
    ) : null,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          // Error handling
          if (snapshot.hasError) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 60),
                      SizedBox(height: 16),
                      Text(
                        'Error initializing Firebase',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Reload the app
                          runApp(FirebaseInitializerApp());
                        },
                        child: Text('Retry'),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Make sure you have a proper internet connection',
                        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Firebase initialized successfully, load app
          if (snapshot.connectionState == ConnectionState.done) {
            return ExpenseLocatorApp();
          }

          // Loading
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 24),
                    Text("Initializing app..."),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ExpenseLocatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Locator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/',
      routes: {
        '/': (_) => SplashScreen(),
        '/home': (_) => HomeScreen(username: 'User'),
        '/add': (_) => AddExpenseScreen(),
        '/list': (_) => ExpenseListScreen(),
      },
    );
  }
}
