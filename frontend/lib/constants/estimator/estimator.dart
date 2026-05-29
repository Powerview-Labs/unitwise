/**
 * Appliance Estimator Exports
 * 
 * Barrel file that exports all Appliance Estimator components.
 * Provides a single import for all estimator functionality.
 * 
 * Usage:
 * import 'package:unitwise/estimator/estimator.dart';
 * 
 * Maintainability: Single import point simplifies code
 */

// ============================================================================
// MODELS (Phase 1)
// ============================================================================

export '../../models/appliance_model.dart';
export '../../models/appliance_estimator_model.dart';
export '../../models/appliance_estimator_state.dart';
export '../../models/power_saver_tip_model.dart';
export '../../models/band_lookup_result.dart';

// ============================================================================
// SERVICES (Phase 1)
// ============================================================================

export '../../services/appliance_service.dart';
export '../../services/band_lookup_service.dart';
export '../../services/local_storage_service.dart';
export '../../services/analytics_service.dart';

// ============================================================================
// UTILS (Phase 1)
// ============================================================================

export '../../utils/appliance_calculator.dart';
export '../../utils/number_formatters.dart';

// ============================================================================
// CONSTANTS (Phase 1 & 2A)
// ============================================================================

export '../../constants/default_appliances.dart';
export 'estimator_constants.dart';
export 'estimator_strings.dart';

// ============================================================================
// EXTENSIONS (Phase 2A)
// ============================================================================

export '../../utils/estimator/estimator_extensions.dart';

// ============================================================================
// CONTROLLERS (Phase 2A)
// ============================================================================

export '../../controllers/estimator/appliance_estimator_controller.dart';

// ============================================================================
// SCREENS (Phase 2B - will be added)
// ============================================================================

// export '../../screens/estimator/appliance_estimator_screen.dart';

// ============================================================================
// WIDGETS (Phase 2B & 2C - will be added)
// ============================================================================

// export '../../widgets/estimator/appliance_list_widget.dart';
// export '../../widgets/estimator/appliance_row_widget.dart';
// export '../../widgets/estimator/add_appliance_dialog.dart';
// export '../../widgets/estimator/daily_burn_display.dart';
// export '../../widgets/estimator/power_saver_tips_widget.dart';
// export '../../widgets/estimator/band_adjustment_tooltip.dart';
// export '../../widgets/estimator/high_consumption_badge.dart';
// export '../../widgets/estimator/empty_state_widget.dart';
// export '../../widgets/estimator/appliance_category_selector.dart';
