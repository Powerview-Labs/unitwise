/// Represents the active input mode in Budget Planner
/// WHY: Enforces mutual exclusivity between ₦ and units input
/// SECURITY: Prevents ambiguous state where both inputs are active
enum BudgetInputMode {
  /// User is inputting budget amount in Naira (₦)
  budgetAmount,

  /// User is inputting target units
  targetUnits,
}

extension BudgetInputModeExtension on BudgetInputMode {
  /// Human-readable label for UI
  String get label {
    switch (this) {
      case BudgetInputMode.budgetAmount:
        return 'Budget Amount (₦)';
      case BudgetInputMode.targetUnits:
        return 'Target Units';
    }
  }

  /// Helper text for input field
  String get hint {
    switch (this) {
      case BudgetInputMode.budgetAmount:
        return 'Enter amount in Naira';
      case BudgetInputMode.targetUnits:
        return 'Enter desired units';
    }
  }

  /// Determines which input field should be enabled
  bool isAmountMode() => this == BudgetInputMode.budgetAmount;
  bool isUnitsMode() => this == BudgetInputMode.targetUnits;
}
