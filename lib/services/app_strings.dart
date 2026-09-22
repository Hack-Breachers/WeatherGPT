import 'package:flutter/material.dart';

import 'language_service.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _values = {
    // =========================================================
    // ENGLISH
    // =========================================================
    'en': {
      // -------------------------------------------------------
      // GENERAL / LANGUAGE
      // -------------------------------------------------------
      'language': 'Language',

      'english': 'English',
      'hindi': 'हिन्दी',
      'bengali': 'বাংলা',

      // -------------------------------------------------------
      // DRAWER
      // -------------------------------------------------------
      'officer_login': 'Officer Login',
      'donate_now': 'Donate Now',
      'join_rescue': 'Join Rescue Community',
      'offline_mode': 'Offline Mode Simulator',

      // -------------------------------------------------------
      // HOME
      // -------------------------------------------------------
      'greeting': 'Hi there! How can I help you today?',

      'rain_forecast': 'Rain forecast',
      'thunderstorm_warnings': 'Thunderstorm warnings',
      'emergency_shelters': 'Emergency shelters',
      'flood_alerts': 'Flood alerts',

      // -------------------------------------------------------
      // REGIONAL HAZARD MONITOR
      // -------------------------------------------------------
      'regional_hazard_monitor': 'Regional Hazard Monitor',

      'no_nearby_hazards': 'No nearby hazards detected',

      'current_area_alerts':
          'Current Area & Nearby Disaster Alerts',

      // -------------------------------------------------------
      // WEATHER / RISK
      // -------------------------------------------------------
      'weather_risk_advisory':
          'Weather Risk Advisory',

      'risk_low': 'LOW',
      'risk_medium': 'MEDIUM',
      'risk_high': 'HIGH',
      'risk_critical': 'CRITICAL',
      'risk_unknown': 'UNKNOWN',

      // -------------------------------------------------------
      // HAZARDS
      // -------------------------------------------------------
      'heavy_rain': 'Heavy Rain',
      'heavy_rain_advisory': 'Heavy Rain Advisory',

      'flood': 'Flood',
      'flood_advisory': 'Flood Advisory',

      'thunderstorm': 'Thunderstorm',
      'thunderstorm_advisory': 'Thunderstorm Advisory',

      'cyclone': 'Cyclone',
      'cyclone_advisory': 'Cyclone Advisory',

      'heatwave': 'Heatwave',
      'heatwave_advisory': 'Heatwave Advisory',

      'storm': 'Storm',
      'storm_advisory': 'Storm Advisory',

      // -------------------------------------------------------
      // WEATHER DATA LABELS
      // -------------------------------------------------------
      'temperature': 'Temperature',
      'humidity': 'Humidity',
      'feels_like': 'Feels like',
      'rain': 'Rain',

      'rain_probability': 'Rain probability',
      'current_rain_probability':
          'Current rain probability',

      'precipitation': 'Precipitation',
      'forecast_precipitation':
          'Forecast precipitation',

      'wind_speed': 'Wind speed',
      'weather': 'Weather',
      'weather_code': 'Weather condition',

      'next_6h_max_rain':
          'Next 6 h maximum rain probability',

      'next_6h_max': 'next 6 h max',
      'overall_risk': 'overall risk',

      // -------------------------------------------------------
      // WEATHER DESCRIPTIONS
      // -------------------------------------------------------
      'clear_sky': 'Clear sky',
      'partly_cloudy': 'Partly cloudy',
      'cloudy': 'Cloudy',
      'fog': 'Fog',
      'drizzle': 'Drizzle',
      'rain_showers': 'Rain showers',
      'rain_light': 'Light rain',
      'rain_moderate': 'Moderate rain',
      'rain_heavy': 'Heavy rain',
      'thunderstorm_weather': 'Thunderstorm',
      'weather_unknown': 'Unknown weather',

      // -------------------------------------------------------
      // ADVISORIES / EXPLANATIONS
      // -------------------------------------------------------
      'rain_advisory': 'Rain Advisory',

      'rain_probability_elevated':
          'Rain probability is elevated.',

      'upcoming_rain_probability':
          'Multiple upcoming hours show elevated rainfall probability.',

      'urban_flood_risk_detected':
          'Forecast rainfall accumulation indicates elevated urban flood risk.',

      'thunderstorm_conditions':
          'Thunderstorm conditions are indicated in the forecast.',

      'elevated_weather_condition':
          'The weather risk engine has detected an elevated condition.',

      'weather_data_unavailable':
          'Live weather data is currently unavailable.',

      'regional_data_unavailable':
          'Regional hazard feed is currently unavailable.',

      'no_significant_weather_hazard':
          'No significant weather hazard has been detected by the current risk engine.',

      'live_weather_unavailable':
          'Live weather data is currently unavailable.',

      // -------------------------------------------------------
      // RAIN / RISK ENGINE TEXT
      // -------------------------------------------------------
      'rain_data_summary':
          'Next 6 h: {rain}% maximum rain probability, {precipitation} mm forecast precipitation.',

      'rain_advisory_elevated':
          'Rain advisory: elevated risk detected',

      'next_6h_rain_summary':
          'Next 6 h: {rain}% maximum rain probability • {precipitation} mm forecast precipitation.',

      'rain_monitoring_no_hazard':
          'Rain monitoring: no verified rain hazard',

      'protocol_label': 'Protocol',

      // -------------------------------------------------------
      // SAFETY / RISK PROTOCOLS
      // -------------------------------------------------------
      'protocol': 'Protocol',

      'safety_protocol': 'Safety Protocol',

      'protocol_heavy_rain':
          'Protocol: carry rain protection, avoid waterlogged roads and monitor official alerts.',

      'protocol_flood':
          'Protocol: avoid underpasses and flooded roads. Move to safer elevated areas if water rises.',

      'protocol_thunderstorm':
          'Protocol: stay indoors, avoid open areas and do not shelter under isolated trees.',

      'protocol_cyclone':
          'Protocol: stay indoors, stay away from windows and follow official evacuation instructions.',

      'protocol_heatwave':
          'Protocol: stay hydrated, avoid direct sunlight and limit outdoor activity during peak heat.',

      'protocol_unavailable':
          'Protocol: check your connection and follow official emergency information.',

      'protocol_default':
          'Protocol: continue monitoring weather conditions and official alerts.',

      // -------------------------------------------------------
      // UI STATUS
      // -------------------------------------------------------
      'coverage_radius': 'Coverage radius',
      'last_checked': 'Last checked',

      'live': 'LIVE',
      'offline': 'OFFLINE',
      'online': 'ONLINE',

      'offline_active': 'Offline simulator active',
      'online_restored': 'Online mode restored',

      // -------------------------------------------------------
      // CHAT
      // -------------------------------------------------------
      'chat_analyzing':
          'Analyzing your request with the latest available weather and hazard data...',

      'chat_unavailable':
          "I couldn't reach the conversational service right now. Please use the available weather and risk information.",

      // -------------------------------------------------------
      // SOS
      // -------------------------------------------------------
      'sos_help': 'SOS / HELP',
    },

    // =========================================================
    // HINDI
    // =========================================================
    'hi': {
      // -------------------------------------------------------
      // GENERAL / LANGUAGE
      // -------------------------------------------------------
      'language': 'भाषा',

      'english': 'अंग्रेज़ी',
      'hindi': 'हिन्दी',
      'bengali': 'बंगाली',

      // -------------------------------------------------------
      // DRAWER
      // -------------------------------------------------------
      'officer_login': 'अधिकारी लॉगिन',
      'donate_now': 'अभी दान करें',
      'join_rescue': 'रेस्क्यू समुदाय से जुड़ें',
      'offline_mode': 'ऑफ़लाइन मोड सिम्युलेटर',

      // -------------------------------------------------------
      // HOME
      // -------------------------------------------------------
      'greeting':
          'नमस्ते! आज मैं आपकी कैसे मदद कर सकता हूँ?',

      'rain_forecast':
          'बारिश का पूर्वानुमान',

      'thunderstorm_warnings':
          'आंधी-तूफान चेतावनी',

      'emergency_shelters':
          'आपातकालीन आश्रय',

      'flood_alerts':
          'बाढ़ चेतावनी',

      // -------------------------------------------------------
      // REGIONAL HAZARD MONITOR
      // -------------------------------------------------------
      'regional_hazard_monitor':
          'क्षेत्रीय खतरा निगरानी',

      'no_nearby_hazards':
          'आसपास कोई खतरा नहीं मिला',

      'current_area_alerts':
          'वर्तमान क्षेत्र और आसपास की आपदा चेतावनियाँ',

      // -------------------------------------------------------
      // WEATHER / RISK
      // -------------------------------------------------------
      'weather_risk_advisory':
          'मौसम जोखिम सलाह',

      'risk_low': 'कम',
      'risk_medium': 'मध्यम',
      'risk_high': 'उच्च',
      'risk_critical': 'अत्यधिक',
      'risk_unknown': 'अज्ञात',

      // -------------------------------------------------------
      // HAZARDS
      // -------------------------------------------------------
      'heavy_rain': 'भारी बारिश',

      'heavy_rain_advisory':
          'भारी बारिश की चेतावनी',

      'flood': 'बाढ़',

      'flood_advisory':
          'बाढ़ की चेतावनी',

      'thunderstorm': 'आंधी-तूफान',

      'thunderstorm_advisory':
          'आंधी-तूफान की चेतावनी',

      'cyclone': 'चक्रवात',

      'cyclone_advisory':
          'चक्रवात की चेतावनी',

      'heatwave': 'लू',

      'heatwave_advisory':
          'लू की चेतावनी',

      'storm': 'तूफान',

      'storm_advisory':
          'तूफान की चेतावनी',

      // -------------------------------------------------------
      // WEATHER DATA LABELS
      // -------------------------------------------------------
      'temperature': 'तापमान',
      'humidity': 'आर्द्रता',
      'feels_like': 'महसूस हो रहा है',
      'rain': 'बारिश',

      'rain_probability':
          'बारिश की संभावना',

      'current_rain_probability':
          'वर्तमान बारिश की संभावना',

      'precipitation': 'वर्षा',

      'forecast_precipitation':
          'अनुमानित वर्षा',

      'wind_speed': 'हवा की गति',
      'weather': 'मौसम',
      'weather_code': 'मौसम की स्थिति',

      'next_6h_max_rain':
          'अगले 6 घंटों में अधिकतम बारिश की संभावना',

      'next_6h_max':
          'अगले 6 घंटे का अधिकतम',

      'overall_risk':
          'कुल जोखिम',

      // -------------------------------------------------------
      // WEATHER DESCRIPTIONS
      // -------------------------------------------------------
      'clear_sky': 'साफ़ आसमान',
      'partly_cloudy':
          'आंशिक रूप से बादल छाए हुए',
      'cloudy': 'बादल छाए हुए',
      'fog': 'कोहरा',
      'drizzle': 'बूंदाबांदी',
      'rain_showers': 'बारिश की बौछारें',
      'rain_light': 'हल्की बारिश',
      'rain_moderate': 'मध्यम बारिश',
      'rain_heavy': 'भारी बारिश',
      'thunderstorm_weather': 'आंधी-तूफान',
      'weather_unknown': 'मौसम अज्ञात',

      // -------------------------------------------------------
      // ADVISORIES / EXPLANATIONS
      // -------------------------------------------------------
      'rain_advisory':
          'बारिश की चेतावनी',

      'rain_probability_elevated':
          'बारिश की संभावना अधिक है।',

      'upcoming_rain_probability':
          'आने वाले कई घंटों में बारिश की संभावना अधिक है।',

      'urban_flood_risk_detected':
          'पूर्वानुमानित वर्षा से शहरी बाढ़ का जोखिम बढ़ा हुआ है।',

      'thunderstorm_conditions':
          'पूर्वानुमान में आंधी-तूफान की स्थिति दिखाई दे रही है।',

      'elevated_weather_condition':
          'मौसम जोखिम इंजन ने बढ़े हुए जोखिम की स्थिति का पता लगाया है।',

      'weather_data_unavailable':
          'लाइव मौसम डेटा वर्तमान में उपलब्ध नहीं है।',

      'regional_data_unavailable':
          'क्षेत्रीय खतरे की जानकारी वर्तमान में उपलब्ध नहीं है।',

      'no_significant_weather_hazard':
          'वर्तमान जोखिम इंजन द्वारा कोई महत्वपूर्ण मौसम खतरा नहीं पाया गया है।',

      'live_weather_unavailable':
          'लाइव मौसम डेटा वर्तमान में उपलब्ध नहीं है।',

      // -------------------------------------------------------
      // RAIN / RISK ENGINE TEXT
      // -------------------------------------------------------
      'rain_data_summary':
          'अगले 6 घंटों में: अधिकतम बारिश की संभावना {rain}%, अनुमानित वर्षा {precipitation} मिमी।',

      'rain_advisory_elevated':
          'बारिश की चेतावनी: जोखिम बढ़ा हुआ है',

      'next_6h_rain_summary':
          'अगले 6 घंटे: अधिकतम बारिश की संभावना {rain}% • अनुमानित वर्षा {precipitation} मिमी।',

      'rain_monitoring_no_hazard':
          'बारिश की निगरानी: बारिश का कोई सत्यापित खतरा नहीं',

      'protocol_label':
          'प्रोटोकॉल',

      // -------------------------------------------------------
      // SAFETY / RISK PROTOCOLS
      // -------------------------------------------------------
      'protocol': 'प्रोटोकॉल',

      'safety_protocol':
          'सुरक्षा निर्देश',

      'protocol_heavy_rain':
          'प्रोटोकॉल: बारिश से बचाव रखें, जलभराव वाली सड़कों से बचें और आधिकारिक चेतावनियों पर नज़र रखें।',

      'protocol_flood':
          'प्रोटोकॉल: अंडरपास और बाढ़ वाली सड़कों से बचें। पानी बढ़ने पर सुरक्षित ऊँचे स्थान पर जाएँ।',

      'protocol_thunderstorm':
          'प्रोटोकॉल: घर के अंदर रहें, खुले क्षेत्रों से बचें और अकेले खड़े पेड़ों के नीचे आश्रय न लें।',

      'protocol_cyclone':
          'प्रोटोकॉल: घर के अंदर रहें, खिड़कियों से दूर रहें और आधिकारिक निकासी निर्देशों का पालन करें।',

      'protocol_heatwave':
          'प्रोटोकॉल: पर्याप्त पानी पिएँ, सीधी धूप से बचें और तेज़ गर्मी के दौरान बाहर की गतिविधियाँ सीमित करें।',

      'protocol_unavailable':
          'प्रोटोकॉल: अपना कनेक्शन जाँचें और आधिकारिक आपातकालीन जानकारी का पालन करें।',

      'protocol_default':
          'प्रोटोकॉल: मौसम की स्थिति और आधिकारिक चेतावनियों पर नज़र रखें।',

      // -------------------------------------------------------
      // UI STATUS
      // -------------------------------------------------------
      'coverage_radius':
          'निगरानी क्षेत्र',

      'last_checked':
          'अंतिम जांच',

      'live': 'लाइव',
      'offline': 'ऑफ़लाइन',
      'online': 'ऑनलाइन',

      'offline_active':
          'ऑफ़लाइन सिम्युलेटर सक्रिय है',

      'online_restored':
          'ऑनलाइन मोड बहाल किया गया',

      // -------------------------------------------------------
      // CHAT
      // -------------------------------------------------------
      'chat_analyzing':
          'नवीनतम मौसम और खतरे की जानकारी के आधार पर आपके अनुरोध का विश्लेषण किया जा रहा है...',

      'chat_unavailable':
          'अभी वार्तालाप सेवा से संपर्क नहीं हो सका। उपलब्ध मौसम और जोखिम जानकारी का उपयोग करें।',

      // -------------------------------------------------------
      // SOS
      // -------------------------------------------------------
      'sos_help':
          'एसओएस / मदद',
    },

    // =========================================================
    // BENGALI
    // =========================================================
    'bn': {
      // -------------------------------------------------------
      // GENERAL / LANGUAGE
      // -------------------------------------------------------
      'language': 'ভাষা',

      'english': 'ইংরেজি',
      'hindi': 'হিন্দি',
      'bengali': 'বাংলা',

      // -------------------------------------------------------
      // DRAWER
      // -------------------------------------------------------
      'officer_login': 'অফিসার লগইন',
      'donate_now': 'এখনই দান করুন',
      'join_rescue': 'উদ্ধার সম্প্রদায়ে যোগ দিন',
      'offline_mode': 'অফলাইন মোড সিমুলেটর',

      // -------------------------------------------------------
      // HOME
      // -------------------------------------------------------
      'greeting':
          'হ্যালো! আজ আমি কীভাবে আপনাকে সাহায্য করতে পারি?',

      'rain_forecast':
          'বৃষ্টির পূর্বাভাস',

      'thunderstorm_warnings':
          'বজ্রঝড়ের সতর্কতা',

      'emergency_shelters':
          'জরুরি আশ্রয়কেন্দ্র',

      'flood_alerts':
          'বন্যার সতর্কতা',

      // -------------------------------------------------------
      // REGIONAL HAZARD MONITOR
      // -------------------------------------------------------
      'regional_hazard_monitor':
          'আঞ্চলিক বিপদ পর্যবেক্ষণ',

      'no_nearby_hazards':
          'আশেপাশে কোনো বিপদ শনাক্ত হয়নি',

      'current_area_alerts':
          'বর্তমান এলাকা ও আশেপাশের দুর্যোগ সতর্কতা',

      // -------------------------------------------------------
      // WEATHER / RISK
      // -------------------------------------------------------
      'weather_risk_advisory':
          'আবহাওয়া ঝুঁকি পরামর্শ',

      'risk_low': 'কম',
      'risk_medium': 'মাঝারি',
      'risk_high': 'উচ্চ',
      'risk_critical': 'অতি উচ্চ',
      'risk_unknown': 'অজানা',

      // -------------------------------------------------------
      // HAZARDS
      // -------------------------------------------------------
      'heavy_rain': 'ভারী বৃষ্টি',

      'heavy_rain_advisory':
          'ভারী বৃষ্টির সতর্কতা',

      'flood': 'বন্যা',

      'flood_advisory':
          'বন্যার সতর্কতা',

      'thunderstorm': 'বজ্রঝড়',

      'thunderstorm_advisory':
          'বজ্রঝড়ের সতর্কতা',

      'cyclone': 'ঘূর্ণিঝড়',

      'cyclone_advisory':
          'ঘূর্ণিঝড়ের সতর্কতা',

      'heatwave': 'তাপপ্রবাহ',

      'heatwave_advisory':
          'তাপপ্রবাহের সতর্কতা',

      'storm': 'ঝড়',

      'storm_advisory':
          'ঝড়ের সতর্কতা',

      // -------------------------------------------------------
      // WEATHER DATA LABELS
      // -------------------------------------------------------
      'temperature': 'তাপমাত্রা',
      'humidity': 'আর্দ্রতা',
      'feels_like': 'অনুভূত হচ্ছে',
      'rain': 'বৃষ্টি',

      'rain_probability':
          'বৃষ্টির সম্ভাবনা',

      'current_rain_probability':
          'বর্তমান বৃষ্টির সম্ভাবনা',

      'precipitation': 'বৃষ্টিপাত',

      'forecast_precipitation':
          'পূর্বাভাসকৃত বৃষ্টিপাত',

      'wind_speed': 'বাতাসের গতি',
      'weather': 'আবহাওয়া',
      'weather_code': 'আবহাওয়ার অবস্থা',

      'next_6h_max_rain':
          'পরবর্তী ৬ ঘণ্টায় সর্বোচ্চ বৃষ্টির সম্ভাবনা',

      'next_6h_max':
          'পরবর্তী ৬ ঘণ্টার সর্বোচ্চ',

      'overall_risk':
          'সামগ্রিক ঝুঁকি',

      // -------------------------------------------------------
      // WEATHER DESCRIPTIONS
      // -------------------------------------------------------
      'clear_sky': 'পরিষ্কার আকাশ',
      'partly_cloudy': 'আংশিক মেঘলা',
      'cloudy': 'মেঘলা',
      'fog': 'কুয়াশা',
      'drizzle': 'গুঁড়ি গুঁড়ি বৃষ্টি',
      'rain_showers': 'বৃষ্টির ঝরনা',
      'rain_light': 'হালকা বৃষ্টি',
      'rain_moderate': 'মাঝারি বৃষ্টি',
      'rain_heavy': 'ভারী বৃষ্টি',
      'thunderstorm_weather': 'বজ্রঝড়',
      'weather_unknown': 'আবহাওয়া অজানা',

      // -------------------------------------------------------
      // ADVISORIES / EXPLANATIONS
      // -------------------------------------------------------
      'rain_advisory':
          'বৃষ্টি সতর্কতা',

      'rain_probability_elevated':
          'বৃষ্টির সম্ভাবনা বেশি।',

      'upcoming_rain_probability':
          'আগামী কয়েক ঘণ্টায় বৃষ্টির সম্ভাবনা বেশি।',

      'urban_flood_risk_detected':
          'পূর্বাভাসিত বৃষ্টিপাতের কারণে শহুরে বন্যার ঝুঁকি বেড়েছে।',

      'thunderstorm_conditions':
          'পূর্বাভাসে বজ্রঝড়ের পরিস্থিতি দেখা যাচ্ছে।',

      'elevated_weather_condition':
          'আবহাওয়া ঝুঁকি ইঞ্জিন উচ্চ ঝুঁকির পরিস্থিতি শনাক্ত করেছে।',

      'weather_data_unavailable':
          'লাইভ আবহাওয়ার তথ্য বর্তমানে পাওয়া যাচ্ছে না।',

      'regional_data_unavailable':
          'আঞ্চলিক বিপদের তথ্য বর্তমানে পাওয়া যাচ্ছে না।',

      'no_significant_weather_hazard':
          'বর্তমান ঝুঁকি ইঞ্জিন কোনো উল্লেখযোগ্য আবহাওয়ার বিপদ শনাক্ত করেনি।',

      'live_weather_unavailable':
          'লাইভ আবহাওয়ার তথ্য বর্তমানে পাওয়া যাচ্ছে না।',

      // -------------------------------------------------------
      // RAIN / RISK ENGINE TEXT
      // -------------------------------------------------------
      'rain_data_summary':
          'পরবর্তী ৬ ঘণ্টায়: সর্বোচ্চ বৃষ্টির সম্ভাবনা {rain}%, পূর্বাভাসিত বৃষ্টিপাত {precipitation} মিমি।',

      'rain_advisory_elevated':
          'বৃষ্টির সতর্কতা: ঝুঁকি বেড়েছে',

      'next_6h_rain_summary':
          'পরবর্তী ৬ ঘণ্টা: সর্বোচ্চ বৃষ্টির সম্ভাবনা {rain}% • পূর্বাভাসিত বৃষ্টিপাত {precipitation} মিমি।',

      'rain_monitoring_no_hazard':
          'বৃষ্টি পর্যবেক্ষণ: কোনো নিশ্চিত বৃষ্টির ঝুঁকি নেই',

      'protocol_label':
          'প্রোটোকল',

      // -------------------------------------------------------
      // SAFETY / RISK PROTOCOLS
      // -------------------------------------------------------
      'protocol':
          'নিরাপত্তা নির্দেশনা',

      'safety_protocol':
          'নিরাপত্তা নির্দেশনা',

      'protocol_heavy_rain':
          'নিরাপত্তা নির্দেশনা: বৃষ্টির সুরক্ষা নিন, জলমগ্ন রাস্তা এড়িয়ে চলুন এবং সরকারি সতর্কতা পর্যবেক্ষণ করুন।',

      'protocol_flood':
          'নিরাপত্তা নির্দেশনা: আন্ডারপাস ও প্লাবিত রাস্তা এড়িয়ে চলুন। জল বাড়লে নিরাপদ উঁচু স্থানে যান।',

      'protocol_thunderstorm':
          'নিরাপত্তা নির্দেশনা: ঘরের ভিতরে থাকুন, খোলা এলাকা এড়িয়ে চলুন এবং একা দাঁড়ানো গাছের নিচে আশ্রয় নেবেন না।',

      'protocol_cyclone':
          'নিরাপত্তা নির্দেশনা: ঘরের ভিতরে থাকুন, জানালা থেকে দূরে থাকুন এবং সরকারি সরিয়ে নেওয়ার নির্দেশনা অনুসরণ করুন।',

      'protocol_heatwave':
          'নিরাপত্তা নির্দেশনা: পর্যাপ্ত পানি পান করুন, সরাসরি রোদ এড়িয়ে চলুন এবং অতিরিক্ত গরমের সময় বাইরে যাওয়া সীমিত করুন।',

      'protocol_unavailable':
          'নিরাপত্তা নির্দেশনা: সংযোগ পরীক্ষা করুন এবং সরকারি জরুরি তথ্য অনুসরণ করুন।',

      'protocol_default':
          'নিরাপত্তা নির্দেশনা: আবহাওয়ার পরিস্থিতি ও সরকারি সতর্কতা পর্যবেক্ষণ করুন।',

      // -------------------------------------------------------
      // UI STATUS
      // -------------------------------------------------------
      'coverage_radius':
          'পর্যবেক্ষণ ব্যাসার্ধ',

      'last_checked':
          'শেষবার পরীক্ষা',

      'live': 'লাইভ',
      'offline': 'অফলাইন',
      'online': 'অনলাইন',

      'offline_active':
          'অফলাইন সিমুলেটর সক্রিয়',

      'online_restored':
          'অনলাইন মোড পুনরায় চালু হয়েছে',

      // -------------------------------------------------------
      // CHAT
      // -------------------------------------------------------
      'chat_analyzing':
          'সর্বশেষ আবহাওয়া ও বিপদের তথ্য ব্যবহার করে আপনার অনুরোধ বিশ্লেষণ করা হচ্ছে...',

      'chat_unavailable':
          'এই মুহূর্তে কথোপকথন পরিষেবায় সংযোগ করা যায়নি। উপলব্ধ আবহাওয়া ও ঝুঁকির তথ্য ব্যবহার করুন।',

      // -------------------------------------------------------
      // SOS
      // -------------------------------------------------------
      'sos_help':
          'এসওএস / সাহায্য',
    },
  };

  /// Get a translated string using the current app language.
  static String t(
    BuildContext context,
    String key,
  ) {
    final language =
        LanguageScope.of(context).language.code;

    return _values[language]?[key] ??
        _values['en']?[key] ??
        key;
  }

  /// Get a translated string and replace placeholders.
  static String format(
    BuildContext context,
    String key, {
    Map<String, String> values = const {},
  }) {
    String text = t(context, key);

    values.forEach((placeholder, value) {
      text = text.replaceAll(
        '{$placeholder}',
        value,
      );
    });

    return text;
  }

  /// Get a translated string without BuildContext.
  ///
  /// Useful for background/offline logic where a context
  /// is not available.
  static String forLanguage(
    AppLanguage language,
    String key,
  ) {
    return _values[language.code]?[key] ??
        _values['en']?[key] ??
        key;
  }
}