import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();
  
  // Reference to the expenses collection
  final CollectionReference expensesCollection = 
      FirebaseFirestore.instance.collection('expenses');

  // Increased timeout duration for Firebase operations (from 10 to 30 seconds)
  static const Duration _timeout = Duration(seconds: 30);

  // Configure Firestore settings to allow more time for operations
  void configureFirestore() {
    FirebaseFirestore.instance.settings = 
        Settings(cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
  }

  Future<int> insertExpense(Expense expense) async {
    // Configure Firestore settings first
    configureFirestore();
    
    try {
      // Print the data for debugging
      print('Inserting expense: ${expense.toMap()}');
      
      Map<String, dynamic> data = expense.toMap();
      // Remove id if it's null to let Firestore generate one
      if (data['id'] == null) {
        data.remove('id');
      }
      
      // Add document to Firestore with extended timeout
      DocumentReference docRef = await expensesCollection.add(data)
          .timeout(_timeout, onTimeout: () {
            throw TimeoutException("Operation timed out. Check your internet connection and try again with better connectivity.");
          });
      
      // Update the document with its ID in the background
      docRef.update({'id': docRef.id}).catchError((error) {
        print('Warning: Failed to update document with ID: $error');
      });
      
      return 1; // Success
    } on FirebaseException catch (e) {
      print('Firebase error inserting expense: ${e.code} - ${e.message}');
      throw Exception('Firebase error: ${e.message}. Check your connection and try again.');
    } catch (e) {
      print('Error inserting expense: $e');
      throw Exception('Failed to add expense: $e. Please check your connection and try again.');
    }
  }

  Future<List<Expense>> fetchExpenses() async {
    // Configure Firestore settings first
    configureFirestore();
    
    try {
      print('Fetching expenses...');
      QuerySnapshot querySnapshot = await expensesCollection.get()
          .timeout(_timeout, onTimeout: () {
            throw TimeoutException("Fetching expenses timed out. Check your internet connection.");
          });
      print('Found ${querySnapshot.docs.length} expenses');
      
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Ensure the id is set correctly from Firestore
        if (!data.containsKey('id') || data['id'] == null) {
          data['id'] = doc.id;
        }
        
        // Handle number conversions that might be necessary for web
        if (kIsWeb) {
          if (data['amount'] != null && data['amount'] is! double) {
            data['amount'] = double.parse(data['amount'].toString());
          }
          if (data['userAShare'] != null && data['userAShare'] is! double) {
            data['userAShare'] = double.parse(data['userAShare'].toString());
          }
          if (data['userBShare'] != null && data['userBShare'] is! double) {
            data['userBShare'] = double.parse(data['userBShare'].toString());
          }
        }
        
        return Expense.fromMap(data);
      }).toList();
    } on FirebaseException catch (e) {
      print('Firebase error fetching expenses: ${e.code} - ${e.message}');
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      print('Error fetching expenses: $e');
      throw Exception('Failed to fetch expenses: $e');
    }
  }

  Future<int> deleteExpense(String id) async {
    // Configure Firestore settings first
    configureFirestore();
    
    try {
      // Delete the expense directly without checking existence first
      await expensesCollection.doc(id).delete()
          .timeout(_timeout, onTimeout: () {
            throw TimeoutException("Delete operation timed out. Check your internet connection.");
          });
      print('Expense deleted with ID: $id');
      return 1; // Success
    } on FirebaseException catch (e) {
      print('Firebase error deleting expense: ${e.code} - ${e.message}');
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      print('Error deleting expense: $e');
      throw Exception('Failed to delete expense: $e');
    }
  }
}

// Custom exception for timeout handling
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}
