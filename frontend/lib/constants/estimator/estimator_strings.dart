/**
 * Appliance Estimator UI Strings
 *
 * Centralized strings for the Appliance Estimator module.
 * All user-facing text in one place for easy internationalization (i18n).
 *
 * Security: No sensitive data - only UI text
 * Maintainability: Single source of truth for all text
 */

/// UI Strings for Appliance Estimator Module
class EstimatorStrings {
  EstimatorStrings._(); // Private constructor - utility class

  // ============================================================================
  // SCREEN TITLES & HEADERS
  // ============================================================================

  static const String screenTitle = 'Appliance Estimator';
  static const String screenSubtitle =
      'Calculate your daily electricity consumption';

  // ============================================================================
  // DAILY BURN DISPLAY
  // ============================================================================

  static const String dailyBurnTitle = 'Estimated Daily Consumption';
  static const String dailyBurnUnits = 'units/day';
  static const String dailyBurnZero = 'Add appliances to calculate';
  static const String dailyBurnPrefix = 'Total: ';
  static const String dailyBurnTooltip =
      'Total units consumed per day by all appliances';

  // Consumption level labels
  static const String consumptionHigh = 'High Consumption';
  static const String consumptionMedium = 'Medium Consumption';
  static const String consumptionLow = 'Low Consumption';

  // ============================================================================
  // APPLIANCE LIST
  // ============================================================================

  static const String applianceListEmpty = 'No appliances added yet';
  static const String applianceListEmptyHint =
      'Tap the + button to add your first appliance';
  static const String applianceCount = 'appliances';
  static const String applianceCountSingular = 'appliance';

  // Power saver tips
  static const String powerSaverTipsTitle = 'Power Saving Tips';
  static const String deleteLabel = 'Delete';

  // ============================================================================
  // APPLIANCE ROW
  // ============================================================================

  static const String applianceWattage = 'W';
  static const String applianceHours = 'hrs/day';
  static const String applianceQuantity = 'Qty:';
  static const String applianceUnitsPerDay = 'units/day';
  static const String applianceHighConsumption = 'High';
  static const String applianceMediumConsumption = 'Medium';
  static const String applianceLowConsumption = 'Low';

  // ============================================================================
  // ADD/EDIT APPLIANCE DIALOG
  // ============================================================================

  static const String addApplianceTitle = 'Add Appliance';
  static const String editApplianceTitle = 'Edit Appliance';
  
  // Form fields
  static const String nameLabel = 'Appliance Name';
  static const String nameHint = 'e.g., Air Conditioner';
  static const String wattageLabel = 'Wattage (W)';
  static const String wattageHint = 'e.g., 1000';
  static const String hoursLabel = 'Hours per Day';
  static const String hoursHint = 'e.g., 8.5';
  static const String quantityLabel = 'Quantity';
  static const String quantityHint = '1';
  static const String categoryLabel = 'Category';
  static const String categoryHint = 'Select category';
  
  // Preview
  static const String previewLabel = 'Daily Consumption Preview';
  
  // Legacy dialog field names (aliases for compatibility)
  static const String dialogAddTitle = addApplianceTitle;
  static const String dialogEditTitle = editApplianceTitle;
  static const String dialogNameLabel = nameLabel;
  static const String dialogNameHint = nameHint;
  static const String dialogWattageLabel = wattageLabel;
  static const String dialogWattageHint = wattageHint;
  static const String dialogHoursLabel = hoursLabel;
  static const String dialogHoursHint = hoursHint;
  static const String dialogQuantityLabel = quantityLabel;
  static const String dialogQuantityHint = quantityHint;
  static const String dialogCategoryLabel = categoryLabel;
  static const String dialogCategoryHint = categoryHint;
  static const String dialogSaveButton = 'Save';
  static const String dialogCancelButton = 'Cancel';
  static const String dialogDeleteButton = 'Delete';
  static const String dialogUseDefault = 'Use Default Appliances';

  // ============================================================================
  // VALIDATION MESSAGES
  // ============================================================================

  static const String validationNameRequired = 'Name is required';
  static const String validationNameTooLong = 'Name is too long (max 50 characters)';
  static const String validationNameInvalid = 'Name contains invalid characters';

  static const String validationWattageRequired = 'Wattage is required';
  static const String validationWattageInvalid = 'Please enter a valid number';
  static const String validationWattageTooLow = 'Wattage must be at least 1W';
  static const String validationWattageTooHigh = 'Wattage must be less than 10,000W';

  static const String validationHoursRequired = 'Hours per day is required';
  static const String validationHoursInvalid = 'Please enter a valid number';
  static const String validationHoursTooLow = 'Hours must be at least 0.1';
  static const String validationHoursTooHigh = 'Hours cannot exceed 24';

  static const String validationQuantityRequired = 'Quantity is required';
  static const String validationQuantityInvalid = 'Please enter a valid number';
  static const String validationQuantityTooLow = 'Quantity must be at least 1';
  static const String validationQuantityTooHigh = 'Quantity cannot exceed 99';

  // ============================================================================
  // POWER SAVER TIPS
  // ============================================================================

  static const String tipsTitle = 'Power Saver Tips';
  static const String tipsEmpty = 'Great job! No high-consumption appliances detected.';

  // Tip templates (formatted with appliance name)
  static const String tipHighWattage =
      '{name} uses high power ({wattage}W). Consider energy-efficient alternatives.';
  static const String tipHighUnits =
      '{name} consumes {units} units/day. Try reducing usage hours.';
  static const String tipHighHours =
      '{name} runs {hours} hours/day. Consider scheduling usage during off-peak hours.';
  static const String tipBandAdjustment =
      '{name} usage exceeds your band supply hours. Actual consumption may be lower.';

  // ============================================================================
  // BAND ADJUSTMENT
  // ============================================================================

  static const String bandAdjustmentTitle = 'Band Adjustment';
  static const String bandAdjustmentExplained =
      'Your electricity supply is limited to {hours} hours per day (Band {band}). '
      'Appliances set to run longer will automatically adjust to this limit.';
  static const String bandAdjustmentExample =
      'Example: If you set an appliance to run 24 hours but your band only provides '
      '12 hours of power, it will calculate consumption for 12 hours.';
  static const String bandAdjustmentNote =
      'This helps you get accurate consumption estimates based on your actual power supply.';

  // ============================================================================
  // EMPTY STATE
  // ============================================================================

  static const String emptyStateTitle = 'No Appliances Yet';
  static const String emptyStateMessage =
      'Start by adding appliances you use daily to calculate your electricity consumption.';
  static const String emptyStateButton = 'Add Your First Appliance';
  static const String emptyStateOrDivider = 'or';
  static const String emptyStateDefaultsButton = 'Use Default Appliances';

  // ============================================================================
  // BUTTONS & ACTIONS
  // ============================================================================

  static const String buttonAdd = 'Add Appliance';
  static const String buttonSave = 'Save';
  static const String buttonCancel = 'Cancel';
  static const String buttonDelete = 'Delete';
  static const String buttonEdit = 'Edit';
  static const String buttonSkip = 'Skip for Now';
  static const String buttonContinue = 'Save & Continue';
  static const String buttonLoadDefaults = 'Load Defaults';
  static const String buttonClearAll = 'Clear All';
  static const String buttonClose = 'Close';

  // Button aliases (for UI consistency)
  static const String addButton = buttonAdd;
  static const String saveButton = buttonSave;
  static const String cancelButton = buttonCancel;
  static const String deleteButton = buttonDelete;
  static const String loadDefaultsButton = buttonLoadDefaults;
  static const String clearAllButton = buttonClearAll;
  static const String closeButton = buttonClose;
  static const String helpButton = 'Help';

  // ============================================================================
  // TOOLTIPS
  // ============================================================================

  static const String loadDefaultsTooltip = 'Load common Nigerian appliances';
  static const String addApplianceTooltip = 'Add new appliance';
  static const String tooltipDailyBurn = 'Total units consumed daily by all appliances';
  static const String tooltipBandInfo = 'How band adjustment works';
  static const String tooltipHighConsumption = 'This appliance uses significant power';
  static const String tooltipEdit = 'Edit appliance';
  static const String tooltipDelete = 'Delete appliance';
  static const String tooltipAdd = 'Add new appliance';
  static const String tooltipCategory = 'Filter by category';

  // ============================================================================
  // CONFIRMATION DIALOGS
  // ============================================================================

  static const String deleteConfirmTitle = 'Delete Appliance?';
  static const String deleteConfirmMessage =
      'Are you sure you want to delete';
  static const String confirmDeleteYes = 'Delete';
  static const String confirmDeleteNo = 'Cancel';

  static const String clearAllConfirmTitle = 'Clear All Appliances?';
  static const String clearAllConfirmMessage =
      'Are you sure you want to remove all appliances? This action cannot be undone.';
  static const String confirmClearAllYes = 'Clear All';
  static const String confirmClearAllNo = 'Cancel';

  static const String loadDefaultsConfirmTitle = 'Replace with Defaults?';
  static const String loadDefaultsConfirmMessage =
      'This will replace your current appliances with common Nigerian appliances. Continue?';

  static const String confirmSkipTitle = 'Skip Estimator?';
  static const String confirmSkipMessage =
      'You can add appliances later from Settings. Continue without estimating?';
  static const String confirmSkipYes = 'Skip';
  static const String confirmSkipNo = 'Stay Here';

  // ============================================================================
  // SUCCESS MESSAGES
  // ============================================================================

  static const String applianceAddedMessage = 'Appliance added successfully';
  static const String applianceUpdatedMessage = 'Appliance updated successfully';
  static const String applianceDeletedMessage = 'Appliance deleted';
  static const String saveSuccessMessage = 'Changes saved successfully';
  static const String defaultsLoadedMessage = 'Default appliances loaded';
  static const String clearedMessage = 'All appliances cleared';
  
  // Legacy success message names (aliases)
  static const String successAdded = applianceAddedMessage;
  static const String successUpdated = applianceUpdatedMessage;
  static const String successDeleted = applianceDeletedMessage;
  static const String successSaved = saveSuccessMessage;
  static const String successDefaultsLoaded = defaultsLoadedMessage;

  // ============================================================================
  // ERROR MESSAGES
  // ============================================================================

  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorLoadFailed = 'Failed to load appliances';
  static const String errorSaveFailed = 'Failed to save changes';
  static const String errorDeleteFailed = 'Failed to delete appliance';
  static const String errorMaxAppliances = 'Maximum number of appliances reached (100)';
  static const String errorInvalidData = 'Invalid appliance data';
  static const String errorNetworkFailed = 'Network error. Changes saved locally.';
  
  // Error message aliases
  static const String saveFailedMessage = errorSaveFailed;

  // ============================================================================
  // HELP DIALOG
  // ============================================================================

  static const String helpTitle = 'How to Use Appliance Estimator';
  static const String helpMessage = 
      '1. Add Appliances: Tap the + button to add appliances you use daily.\n\n'
      '2. Enter Details: Provide the wattage (found on the appliance label) and average hours of use per day.\n\n'
      '3. Review Consumption: See your total daily units and get power-saving tips.\n\n'
      '4. Save: Your estimator is auto-saved, but tap Save to finalize.\n\n'
      'Tip: Load default appliances to get started quickly!';

  // ============================================================================
  // LOADING STATES
  // ============================================================================

  static const String loadingMessage = 'Loading...';
  static const String loadingEstimator = 'Loading estimator...';
  static const String loadingDefaults = 'Loading default appliances...';
  static const String savingEstimator = 'Saving...';
  static const String calculatingUnits = 'Calculating consumption...';

  // ============================================================================
  // ACCESSIBILITY LABELS
  // ============================================================================

  static const String a11yAddButton = 'Add new appliance button';
  static const String a11yEditButton = 'Edit {name} button';
  static const String a11yDeleteButton = 'Delete {name} button';
  static const String a11yDailyBurn = 'Total daily consumption: {units} units';
  static const String a11yApplianceRow = '{name}, {wattage} watts, {hours} hours per day, {units} units per day';
  static const String a11yTipCard = 'Power saving tip: {tip}';
  static const String a11yBandInfo = 'Band adjustment information button';

  // ============================================================================
  // ONBOARDING (if used during signup flow)
  // ============================================================================

  static const String onboardingTitle = 'Estimate Your Consumption';
  static const String onboardingSubtitle =
      'Add appliances you use regularly to calculate your daily electricity needs.';
  static const String onboardingSkipHint =
      'You can always add appliances later from your dashboard.';
  static const String onboardingBenefit1 = '✓ Accurate consumption estimates';
  static const String onboardingBenefit2 = '✓ Personalized power-saving tips';
  static const String onboardingBenefit3 = '✓ Better budget planning';

  // ============================================================================
  // CATEGORY NAMES (for display)
  // ============================================================================

  static const String categoryLighting = 'Lighting';
  static const String categoryKitchen = 'Kitchen';
  static const String categoryCooling = 'Cooling';
  static const String categoryHeating = 'Heating';
  static const String categoryEntertainment = 'Entertainment';
  static const String categoryOffice = 'Office';
  static const String categoryLaundry = 'Laundry';
  static const String categoryOther = 'Other';
  static const String categoryAll = 'All Categories';

  // ============================================================================
  // HELPER METHODS FOR DYNAMIC STRINGS
  // ============================================================================

  /// Format tip with appliance name
  static String formatTip(String template, Map<String, String> params) {
    String result = template;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }

  /// Format count with singular/plural
  static String formatCount(int count, String singular, String plural) {
    return '$count ${count == 1 ? singular : plural}';
  }

  /// Format appliance count
  static String formatApplianceCount(int count) {
    return formatCount(count, applianceCountSingular, applianceCount);
  }
}
