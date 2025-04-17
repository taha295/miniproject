import 'package:flutter/material.dart';
import 'package:miniproject/db/db_helper.dart';
import 'package:miniproject/models/expense.dart';
import 'package:intl/intl.dart';

class AddExpenseScreen extends StatefulWidget {
  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _title = '';
  String _category = 'Food';
  double _amount = 0.0;
  DateTime _selectedDate = DateTime.now();
  bool _isShared = false;
  double _userAPercentage = 50.0;
  bool _isSaving = false;
  String _errorMessage = '';

  List<String> categories = ['Food', 'Transport', 'Bills', 'Shopping'];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 1)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    try {
      // Ensure we have valid data before proceeding
      _title = _titleController.text.trim();
      _amount = double.tryParse(_amountController.text) ?? 0.0;

      if (_title.isEmpty || _amount <= 0) {
        throw Exception("Please provide a title and a valid amount");
      }

      // Calculate shares
      double userAShare = _isShared ? (_amount * _userAPercentage / 100) : _amount;
      double userBShare = _isShared ? _amount - userAShare : 0.0;

      // Ensure proper rounding to avoid floating-point issues
      userAShare = double.parse(userAShare.toStringAsFixed(2));
      userBShare = double.parse(userBShare.toStringAsFixed(2));

      Expense expense = Expense(
        title: _title,
        category: _category,
        amount: _amount,
        dateTime: DateFormat('yyyy-MM-dd HH:mm').format(_selectedDate),
        isShared: _isShared,
        userAShare: userAShare,
        userBShare: userBShare,
      );

      print('Attempting to save expense: ${expense.toMap()}');
      
      // Show saving toast immediately for better feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.0,
                ),
              ),
              SizedBox(width: 10),
              Text("Saving expense..."),
            ],
          ),
          duration: Duration(seconds: 1),
        )
      );

      final result = await DBHelper().insertExpense(expense);

      if (!mounted) return;

      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Expense saved successfully!"))
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        throw Exception("Failed to insert expense");
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        )
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Expense"),
        actions: [
          if (_isSaving)
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.0,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(bottom: 15),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((String category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _category = newValue;
                      });
                    }
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey),
                          SizedBox(width: 10),
                          Text(
                            DateFormat('yyyy-MM-dd').format(_selectedDate),
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                SwitchListTile(
                  title: Text('Share this expense?'),
                  value: _isShared,
                  onChanged: (bool value) {
                    setState(() {
                      _isShared = value;
                    });
                  },
                ),
                if (_isShared) ...[
                  Text('Your share: ${_userAPercentage.toStringAsFixed(0)}%'),
                  Slider(
                    value: _userAPercentage,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: _userAPercentage.toStringAsFixed(0) + '%',
                    onChanged: (double value) {
                      setState(() {
                        _userAPercentage = value;
                      });
                    },
                  ),
                  Text('Other person\'s share: ${(100 - _userAPercentage).toStringAsFixed(0)}%'),
                ],
                SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveExpense,
                    child: _isSaving 
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                                strokeWidth: 2.0,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Saving...', style: TextStyle(fontSize: 18)),
                          ],
                        )
                      : Text('Save Expense', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}

