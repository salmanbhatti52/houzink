import 'package:houzi_package/dataProvider/locale_provider.dart';
import 'package:houzi_package/files/configurations/app_configurations.dart';
import 'package:houzi_package/files/generic_methods/utility_methods.dart';
import 'package:houzi_package/files/hooks_files/hooks_configurations.dart';
import 'package:houzi_package/houzi_main.dart';
import 'package:houzi_package/dataProvider/locale_provider.dart' as locale;
import 'package:houzi_package/files/hooks_files/hooks_configurations.dart';

import 'package:houzi_package/l10n/l10n.dart';
import 'package:houzi_package/pages/home_page_screens/home_elegant_related/related_widgets/home_elegant_sliver_app_bar.dart';
import 'package:houzi_package/pages/home_page_screens/parent_home_related/home_screen_widgets/home_screen_drawer_widgets/home_screen_drawer_widget.dart';
import 'package:houzi_package/pages/home_page_screens/parent_home_related/home_screen_widgets/home_screen_realtors_related_widgets/home_screen_realtors_list_widget.dart';
import 'package:houzi_package/pages/home_screen_drawer_menu_pages/settings_page.dart';
import 'package:houzi_package/pages/home_screen_drawer_menu_pages/user_related/phone_sign_in_widgets/user_get_phone_number.dart';
import 'package:houzi_package/pages/home_screen_drawer_menu_pages/user_related/user_profile.dart';
import 'package:houzi_package/pages/map_view.dart';
import 'package:houzi_package/pages/property_details_related_pages/pd_widgets_listing.dart';
import 'package:houzi_package/widgets/article_box_widgets/article_box_design.dart';

import 'package:houzi_package/widgets/custom_segment_widget.dart';
import 'package:houzi_package/widgets/explore_by_type_design_widgets/explore_by_type_design.dart';
import 'package:houzi_package/widgets/filter_page_widgets/term_picker_related/term_picker.dart';
import 'package:houzi_package/widgets/generic_text_field_widgets/text_field_widget.dart';

abstract class HooksV2Interface {
  Map<String, dynamic> getHeaderMap();
  Map<String, dynamic> getPropertyDetailPageIconsMap();
  Map<String, dynamic> getElegantHomeTermsIconMap();
  DrawerHook getDrawerItems();
  FontsHook getFontHook();
  PropertyItemHook getPropertyItemHook();
  TermItemHook getTermItemHook();
  AgentItemHook getAgentItemHook();
  AgencyItemHook getAgencyItemHook();
  PropertyPageWidgetsHook getWidgetHook();
  LanguageHook getLanguageCodeAndName();
  locale.DefaultLanguageCodeHook getDefaultLanguageHook();

  DefaultHomePageHook getDefaultHomePageHook();
  DefaultCountryCodeHook getDefaultCountryCodeHook();
  SettingsHook getSettingsItemHook();
  ProfileHook getProfileItemHook();
  HomeRightBarButtonWidgetHook getHomeRightBarButtonWidgetHook();
  MarkerTitleHook getMarkerTitleHook();
  MarkerIconHook getMarkerIconHook();
  CustomMarkerHook getCustomMarkerHook();
  PriceFormatterHook getPriceFormatterHook();
  CompactPriceFormatterHook getCompactPriceFormatterHook();
  TextFormFieldCustomizationHook getTextFormFieldCustomizationHook();
  TextFormFieldWidgetHook getTextFormFieldWidgetHook();
  CustomSegmentedControlHook getCustomSegmentedControlHook();
  DrawerHeaderHook getDrawerHeaderHook();
  HidePriceHook getHidePriceHook();
  HideEmptyTerm hideEmptyTerm();
}
