import 'package:flutter/material.dart';
import 'package:miniproject/db/db_helper.dart';
import 'package:miniproject/models/expense.dart';

class ExpenseListScreen extends StatefulWidget {
  @override
  _ExpenseListScreenState createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  List<Expense> _expenses = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await DBHelper().fetchExpenses();

      if (!mounted) return;

      setState(() {
        _expenses = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading expenses: $e';
        print(_errorMessage);
      });
    }
  }

  Future<void> _navigateToAddExpense() async {
    final result = await Navigator.pushNamed(context, '/add');
    if (result == true) {
      _loadExpenses();
    }
  }

  Future<void> _deleteExpense(String? id) async {
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot delete: Invalid expense ID'))
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await DBHelper().deleteExpense(id);
      _loadExpenses();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expense deleted'))
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting expense: $e'),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  Widget _buildCard(Expense expense) {
    Color categoryColor;
    IconData categoryIcon;

    // Assign colors and icons based on category
    switch (expense.category) {
      case 'Food':
        categoryColor = Colors.green;
        categoryIcon = Icons.restaurant;
        break;
      case 'Transport':
        categoryColor = Colors.blue;
        categoryIcon = Icons.directions_car;
        break;
      case 'Bills':
        categoryColor = Colors.red;
        categoryIcon = Icons.receipt;
        break;
      case 'Shopping':
        categoryColor = Colors.purple;
        categoryIcon = Icons.shopping_bag;
        break;
      default:
        categoryColor = Colors.grey;
        categoryIcon = Icons.category;
        break;
    }

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: categoryColor,
          child: Icon(categoryIcon, color: Colors.white),
        ),
        title: Text(
          expense.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${expense.category}'),
            Text('Date: ${expense.dateTime}'),
            if (expense.isShared)
              Text('Shared: Your share: ₹${expense.userAShare.toStringAsFixed(2)}, '
                  'Other\'s share: ₹${expense.userBShare.toStringAsFixed(2)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${expense.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(expense),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showDeleteConfirmation(Expense expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.title}"?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteExpense(expense.id);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Expense History"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadExpenses,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadExpenses,
                          child: Text('Retry'),
                        )
                      ],
                    ),
                  ),
                )
              : _expenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            "No expenses found",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: Icon(Icons.add),
                            label: Text('Add Expense'),
                            onPressed: _navigateToAddExpense,
                          )
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _expenses.length,
                      itemBuilder: (ctx, i) => _buildCard(_expenses[i]),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddExpense,
        child: Icon(Icons.add),
        tooltip: 'Add Expense',
      ),
    );
  }
}

