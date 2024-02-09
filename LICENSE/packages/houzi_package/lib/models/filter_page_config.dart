class FilterPageElement {
  String? sectionType;
  String? title;
  String? dataType;
  String? apiValue;
  String? pickerType;
  bool? showSearchByCity;
  bool? showSearchByLocation;
  String? minValue;
  String? maxValue;

  FilterPageElement({
    this.sectionType,
    this.title,
    this.dataType,
    this.apiValue,
    this.pickerType,
    this.showSearchByCity = true,
    this.showSearchByLocation = true,
    this.minValue = "0",
    this.maxValue = "1000000",
  });

  factory FilterPageElement.fromJson(Map<String, dynamic> json) => FilterPageElement(
    sectionType: json["section_type"],
    title: json["title"],
    dataType: json["data_type"],
    apiValue: json["api_value"],
    pickerType: json["picker_type"],
    showSearchByCity: json["show_search_by_city"],
    showSearchByLocation: json["show_search_by_location"],
    minValue: json["min_range_value"],
    maxValue: json["max_range_value"],
  );

  static Map<String, dynamic> toMap(FilterPageElement filterPageElement) => {
    "section_type": filterPageElement.sectionType,
    "title": filterPageElement.title,
    "data_type": filterPageElement.dataType,
    "api_value": filterPageElement.apiValue,
    "picker_type": filterPageElement.pickerType,
    "show_search_by_city": filterPageElement.showSearchByCity,
    "show_search_by_location": filterPageElement.showSearchByLocation,
    "min_range_value": filterPageElement.minValue,
    "max_range_value": filterPageElement.maxValue,
  };

  static List<Map<String, dynamic>> encode(List<dynamic> filterPageElementsList) {
    return filterPageElementsList.map<Map<String, dynamic>>((item) =>
        FilterPageElement.toMap(item)).toList();
  }

  static List<dynamic> decode(List<dynamic> filterPageElementsEncodedList) {
    return (filterPageElementsEncodedList).map<FilterPageElement>((item) =>
        FilterPageElement.fromJson(item)).toList();
  }
}

