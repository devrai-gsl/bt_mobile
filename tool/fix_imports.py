#!/usr/bin/env python3
"""Rewrite legacy relative imports to package:bt_mobile paths after folder restructure."""

import re
from pathlib import Path

ROOT = Path("/var/www/bt_mobile/lib")

# Match import path suffix -> package import
REPLACEMENTS = [
    (r"config/app_config\.dart", "package:bt_mobile/config/app_config.dart"),
    (r"core/theme/bt_colors\.dart", "package:bt_mobile/core/theme/bt_colors.dart"),
    (r"core/theme/bt_spacing\.dart", "package:bt_mobile/core/theme/bt_spacing.dart"),
    (r"core/theme/bt_typography\.dart", "package:bt_mobile/core/theme/bt_typography.dart"),
    (r"core/theme/bt_theme\.dart", "package:bt_mobile/core/theme/bt_theme.dart"),
    (r"core/camera/camera_permission\.dart", "package:bt_mobile/core/services/camera_service.dart"),
    (r"core/camera/capture_photo\.dart", "package:bt_mobile/core/services/camera_service.dart"),
    (r"core/api/orders_repository\.dart", "package:bt_mobile/features/orders/repositories/orders_repository.dart"),
    (r"core/api/returns_repository\.dart", "package:bt_mobile/features/returns/repositories/returns_repository.dart"),
    (r"core/api/bt_api_client\.dart", "package:bt_mobile/core/network/clients/bt_api_client.dart"),
    (r"core/api/bt_fixture_loader\.dart", "package:bt_mobile/core/network/fixtures/bt_fixture_loader.dart"),
    (r"core/api/bt_mock_api\.dart", "package:bt_mobile/core/network/fixtures/bt_mock_api.dart"),
    (r"core/auth/auth_controller\.dart", "package:bt_mobile/features/auth/providers/auth_controller.dart"),
    (r"core/auth/auth_flow_repository\.dart", "package:bt_mobile/features/auth/repositories/auth_flow_repository.dart"),
    (r"core/auth/auth_repository\.dart", "package:bt_mobile/features/auth/repositories/auth_repository.dart"),
    (r"core/auth/user_profile\.dart", "package:bt_mobile/features/auth/models/user_profile.dart"),
    (r"core/auth/dev_mock_session\.dart", "package:bt_mobile/features/auth/services/dev_mock_session.dart"),
    (r"core/assets/bt_assets\.dart", "package:bt_mobile/core/constants/asset_paths.dart"),
    (r"core/storage/secure_session_store\.dart", "package:bt_mobile/core/services/storage_service.dart"),
    (r"widgets/common/bt_buttons\.dart", "package:bt_mobile/core/widgets/buttons/bt_buttons.dart"),
    (r"widgets/common/bt_badge\.dart", "package:bt_mobile/core/widgets/buttons/bt_badge.dart"),
    (r"widgets/common/bt_input_field\.dart", "package:bt_mobile/core/widgets/inputs/bt_input_field.dart"),
    (r"widgets/common/bt_list_screen_header\.dart", "package:bt_mobile/core/widgets/inputs/bt_list_screen_header.dart"),
    (r"widgets/common/bt_secondary_tabs\.dart", "package:bt_mobile/core/widgets/inputs/bt_secondary_tabs.dart"),
    (r"widgets/common/bt_app_branding\.dart", "package:bt_mobile/core/widgets/branding/bt_app_branding.dart"),
    (r"widgets/common/bt_logo\.dart", "package:bt_mobile/core/widgets/branding/bt_logo.dart"),
    (r"widgets/scanner/bt_barcode_scanner_screen\.dart", "package:bt_mobile/features/scanner/screens/bt_barcode_scanner_screen.dart"),
    (r"widgets/camera/bt_camera_preview\.dart", "package:bt_mobile/features/scanner/widgets/bt_camera_preview.dart"),
    (r"widgets/navigation/bt_app_shell\.dart", "package:bt_mobile/shared/components/bt_app_shell.dart"),
    (r"widgets/navigation/bt_bottom_nav_bar\.dart", "package:bt_mobile/shared/components/bt_bottom_nav_bar.dart"),
    (r"widgets/navigation/app_nav_id\.dart", "package:bt_mobile/shared/components/app_nav_id.dart"),
    (r"features/home/dashboard_screen\.dart", "package:bt_mobile/features/home/screens/dashboard_screen.dart"),
    (r"features/home/dashboard_screen_wrapper\.dart", "package:bt_mobile/features/home/screens/dashboard_screen_wrapper.dart"),
    (r"features/home/widgets/location_picker_sheet\.dart", "package:bt_mobile/shared/bottom_sheets/location_picker_sheet.dart"),
    (r"features/more/more_screen\.dart", "package:bt_mobile/features/more/screens/more_screen.dart"),
    (r"features/notifications/notifications_screen\.dart", "package:bt_mobile/features/notifications/screens/notifications_screen.dart"),
    (r"features/notifications/notification_settings_screen\.dart", "package:bt_mobile/features/notifications/screens/notification_settings_screen.dart"),
    (r"features/orders/orders_screen\.dart", "package:bt_mobile/features/orders/screens/orders_screen.dart"),
    (r"features/orders/order_detail_screen\.dart", "package:bt_mobile/features/orders/screens/order_detail_screen.dart"),
    (r"features/orders/orders_models\.dart", "package:bt_mobile/features/orders/models/orders_models.dart"),
    (r"features/orders/order_detail_models\.dart", "package:bt_mobile/features/orders/models/order_detail_models.dart"),
    (r"features/orders/order_processing_models\.dart", "package:bt_mobile/features/orders/models/order_processing_models.dart"),
    (r"features/orders/orders_filter_state\.dart", "package:bt_mobile/features/orders/models/orders_filter_state.dart"),
    (r"features/orders/orders_filter_definitions\.dart", "package:bt_mobile/features/orders/models/orders_filter_definitions.dart"),
    (r"features/returns/returns_models\.dart", "package:bt_mobile/features/returns/models/returns_models.dart"),
    (r"features/returns/create_return_screen\.dart", "package:bt_mobile/features/returns/screens/create_return_screen.dart"),
    (r"features/returns/returns_home_screen\.dart", "package:bt_mobile/features/returns/screens/returns_home_screen.dart"),
    (r"features/returns/returns_screen\.dart", "package:bt_mobile/features/returns/screens/returns_screen.dart"),
    (r"features/returns/acknowledge_returns_screen\.dart", "package:bt_mobile/features/returns/screens/acknowledge_returns_screen.dart"),
    (r"features/returns/return_qc_screen\.dart", "package:bt_mobile/features/returns/screens/return_qc_screen.dart"),
    (r"features/scan_picklist/scan_picklist_screen\.dart", "package:bt_mobile/features/scanner/screens/scan_picklist_screen.dart"),
    (r"widgets/create_return_sheet\.dart", "package:bt_mobile/shared/bottom_sheets/create_return_sheet.dart"),
    (r"widgets/orders_filter_sheet\.dart", "package:bt_mobile/shared/bottom_sheets/orders_filter_sheet.dart"),
    (r"widgets/reject_order_sheet\.dart", "package:bt_mobile/shared/bottom_sheets/reject_order_sheet.dart"),
    (r"widgets/order_card\.dart", "package:bt_mobile/features/orders/widgets/order_card.dart"),
    (r"widgets/return_card\.dart", "package:bt_mobile/features/returns/widgets/return_card.dart"),
    (r"returns/acknowledge_scanner_screen\.dart", "package:bt_mobile/features/scanner/screens/acknowledge_scanner_screen.dart"),
    (r"returns/create_return_screen\.dart", "package:bt_mobile/features/returns/screens/create_return_screen.dart"),
    (r"returns/returns_models\.dart", "package:bt_mobile/features/returns/models/returns_models.dart"),
    (r"scan_picklist/scan_picklist_screen\.dart", "package:bt_mobile/features/scanner/screens/scan_picklist_screen.dart"),
    (r"orders_filter_definitions\.dart", "package:bt_mobile/features/orders/models/orders_filter_definitions.dart"),
    (r"orders_filter_state\.dart", "package:bt_mobile/features/orders/models/orders_filter_state.dart"),
    (r"orders_models\.dart", "package:bt_mobile/features/orders/models/orders_models.dart"),
    (r"order_detail_models\.dart", "package:bt_mobile/features/orders/models/order_detail_models.dart"),
    (r"order_processing_models\.dart", "package:bt_mobile/features/orders/models/order_processing_models.dart"),
    (r"returns_models\.dart", "package:bt_mobile/features/returns/models/returns_models.dart"),
    (r"auth_flow_repository\.dart", "package:bt_mobile/features/auth/repositories/auth_flow_repository.dart"),
    (r"auth_repository\.dart", "package:bt_mobile/features/auth/repositories/auth_repository.dart"),
    (r"dev_mock_session\.dart", "package:bt_mobile/features/auth/services/dev_mock_session.dart"),
    (r"user_profile\.dart", "package:bt_mobile/features/auth/models/user_profile.dart"),
    (r"bt_mock_api\.dart", "package:bt_mobile/core/network/fixtures/bt_mock_api.dart"),
    (r"bt_fixture_loader\.dart", "package:bt_mobile/core/network/fixtures/bt_fixture_loader.dart"),
    (r"bt_api_client\.dart", "package:bt_mobile/core/network/clients/bt_api_client.dart"),
    (r"^import 'app\.dart';", "import 'package:bt_mobile/app/app.dart';"),
]

LOCAL_SCREEN_IMPORTS = {
    "features/auth/screens/": [
        "concurrent_login_screen.dart",
        "forgot_password_screen.dart",
        "login_locked_screen.dart",
        "login_otp_screen.dart",
    ],
    "features/returns/screens/": [
        "acknowledge_returns_screen.dart",
        "acknowledge_success_screen.dart",
        "qc_capture_screen.dart",
        "return_qc_screen.dart",
        "returns_screen.dart",
    ],
    "features/orders/screens/": [
        "order_detail_screen.dart",
    ],
    "features/scanner/screens/": [
        "picklist_scanning_screen.dart",
    ],
}


def fix_file(path: Path) -> bool:
    text = path.read_text()
    original = text

    for pattern, replacement in REPLACEMENTS:
        text = re.sub(
            rf"import\s+['\"][^'\"]*{pattern}['\"];",
            f"import '{replacement}';",
            text,
        )

    rel = str(path.relative_to(ROOT)).replace("\\", "/")
    for prefix, files in LOCAL_SCREEN_IMPORTS.items():
        if rel.startswith(prefix):
            for fname in files:
                text = re.sub(
                    rf"import\s+['\"]{re.escape(fname)}['\"];",
                    f"import 'package:bt_mobile/{prefix}{fname}';",
                    text,
                )

    if path.name == "acknowledge_returns_screen.dart":
        text = text.replace(
            "package:bt_mobile/features/returns/screens/acknowledge_scanner_screen.dart",
            "package:bt_mobile/features/scanner/screens/acknowledge_scanner_screen.dart",
        )

    if text != original:
        path.write_text(text)
        return True
    return False


def main() -> None:
    changed = 0
    for dart in ROOT.rglob("*.dart"):
        if fix_file(dart):
            changed += 1
            print(dart.relative_to(ROOT))
    print(f"Updated {changed} files")


if __name__ == "__main__":
    main()
