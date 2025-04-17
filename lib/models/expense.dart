class Expense {
  String? id; // Changed from int to String for Firestore document IDs
  String title;
  String category;
  double amount;
  String dateTime;
  bool isShared;
  double userAShare;
  double userBShare;

  Expense({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.dateTime,
    required this.isShared,
    required this.userAShare,
    required this.userBShare,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'dateTime': dateTime,
      'isShared': isShared,
      'userAShare': userAShare,
      'userBShare': userBShare,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      title: map['title'],
      category: map['category'],
      amount: map['amount'] is int ? (map['amount'] as int).toDouble() : map['amount'],
      dateTime: map['dateTime'],
      isShared: map['isShared'] is bool ? map['isShared'] : map['isShared'] == true,
      userAShare: map['userAShare'] is int ? (map['userAShare'] as int).toDouble() : map['userAShare'],
      userBShare: map['userBShare'] is int ? (map['userBShare'] as int).toDouble() : map['userBShare'],
    );
  }
}
