import 'package:flutter/material.dart';

import '../models/quiz_model.dart';
import '../models/rule_model.dart';
import 'rules_violations_bank.dart';

class LearningCategory {
  final String id;
  final String title;
  final String emoji;
  final String subtitle;
  final Color accentColor;

  const LearningCategory({
    required this.id,
    required this.title,
    required this.emoji,
    required this.subtitle,
    required this.accentColor,
  });
}

class LearningCategoryIds {
  static const String trafficSigns = 'traffic_signs';
  static const String basicRules = 'basic_rules';
  static const String violations = 'violations_fines';
  static const String quizMode = 'quiz_mode';
}

class _SignSeed {
  final String id;
  final String title;
  final String icon;
  final String meaning;
  final String? description;

  const _SignSeed({
    required this.id,
    required this.title,
    required this.icon,
    required this.meaning,
    this.description,
  });
}

class LearningData {
  static const List<LearningCategory> categories = [
    LearningCategory(
      id: LearningCategoryIds.trafficSigns,
      title: 'Traffic Signs',
      emoji: '\u{1F6A6}',
      subtitle: 'Learn essential signs with quick micro-sessions.',
      accentColor: Color.fromARGB(255, 3, 4, 104),
    ),
    LearningCategory(
      id: LearningCategoryIds.basicRules,
      title: 'Basic Rules',
      emoji: '\u{1F697}',
      subtitle: 'Master core day-to-day driving habits.',
      accentColor: Color(0xFF1A2FA3),
    ),
    LearningCategory(
      id: LearningCategoryIds.violations,
      title: 'Violations & Fines',
      emoji: '\u26A0\uFE0F',
      subtitle: 'Understand high-risk mistakes and penalties.',
      accentColor: Color(0xFFD32F2F),
    ),
  ];

  static const LearningCategory quizModeCategory = LearningCategory(
    id: LearningCategoryIds.quizMode,
    title: 'Quiz Mode',
    emoji: '\u{1F9E0}',
    subtitle: 'Test retention with mixed MCQs.',
    accentColor: Color(0xFF8B1A1A),
  );

  static const List<String> _distractors = [
    'You may ignore this sign when traffic is light.',
    'This sign applies only to commercial vehicles.',
    'The sign is only advisory and not enforceable.',
    'It is valid only at night.',
    'Only emergency vehicles should follow this sign.',
    'It applies only during rain conditions.',
    'The sign is meant only for pedestrians.',
    'It is not relevant on city roads.',
  ];

  static final List<RuleModel> _rules = [
    ..._regulatorySigns.map(
      (sign) => _toTrafficRule(
        sign: sign,
        penalty: '\u20B9500-\u20B92,000 (state dependent)',
      ),
    ),
    ..._warningSigns.map(
      (sign) => _toTrafficRule(
        sign: sign,
        penalty: '\u20B9500-\u20B91,500 if ignored',
      ),
    ),
    ..._informatorySigns.map(
      (sign) => _toTrafficRule(
        sign: sign,
        penalty: 'Guidance sign (usually no direct fine)',
      ),
    ),
    ..._basicRules,
    ..._violationRules,
  ];

  static RuleModel _toTrafficRule({
    required _SignSeed sign,
    required String penalty,
  }) {
    final answer = sign.meaning;

    return RuleModel(
      id: sign.id,
      categoryId: LearningCategoryIds.trafficSigns,
      title: sign.title,
      icon: sign.icon,
      description: sign.description ?? 'This sign means: ${sign.meaning}',
      penalty: penalty,
      image: 'assets/signs/${sign.id}.png',
      question: 'What does the "${sign.title}" sign indicate?',
      options: _buildOptions(answer, sign.id),
      answer: answer,
    );
  }

  static List<String> _buildOptions(String answer, String seed) {
    final start = seed.codeUnits.fold<int>(0, (value, unit) => value + unit) %
        _distractors.length;

    final wrongChoices = <String>[];
    var offset = 0;
    while (wrongChoices.length < 3) {
      final candidate = _distractors[(start + offset) % _distractors.length];
      if (!wrongChoices.contains(candidate) && candidate != answer) {
        wrongChoices.add(candidate);
      }
      offset += 1;
    }

    final options = <String>[answer, ...wrongChoices];
    final rotateBy = start % options.length;
    return [
      ...options.sublist(rotateBy),
      ...options.sublist(0, rotateBy),
    ];
  }

  static List<RuleModel> rulesForCategory(String categoryId) {
    return _rules.where((rule) => rule.categoryId == categoryId).toList();
  }

  static List<QuizModel> quizQuestions() {
    return _rules
        .where((rule) => rule.categoryId == LearningCategoryIds.trafficSigns)
        .map(
          (rule) => QuizModel(
            question: rule.question,
            image: rule.image,
            options: rule.options,
            answer: rule.answer,
          ),
        )
        .toList(growable: false);
  }

  static int get trafficSignCount =>
      _regulatorySigns.length + _warningSigns.length + _informatorySigns.length;
  static RuleModel _toSeedRule({
    required LearningRuleSeed seed,
    required String categoryId,
  }) {
    return RuleModel(
      id: seed.id,
      categoryId: categoryId,
      title: seed.title,
      icon: seed.icon,
      description: seed.description,
      penalty: seed.penalty,
      image: 'assets/signs/${seed.id}.png',
      question: 'Which statement is correct for "${seed.title}"?',
      options: _buildOptions(seed.keyPoint, seed.id),
      answer: seed.keyPoint,
    );
  }

  static final List<RuleModel> _basicRules = basicRuleSeeds
      .map(
        (seed) => _toSeedRule(
          seed: seed,
          categoryId: LearningCategoryIds.basicRules,
        ),
      )
      .toList(growable: false);

  static final List<RuleModel> _violationRules = violationRuleSeeds
      .map(
        (seed) => _toSeedRule(
          seed: seed,
          categoryId: LearningCategoryIds.violations,
        ),
      )
      .toList(growable: false);
  static final List<_SignSeed> _speedLimitSigns =
      [20, 30, 40, 50, 60, 70, 80, 100]
          .map(
            (speed) => _SignSeed(
              id: 'speed_limit_$speed',
              title: 'Speed Limit $speed',
              icon: '\u23F1\uFE0F',
              meaning: 'Maximum speed is $speed km/h.',
              description:
                  'Do not exceed $speed km/h unless a lower local limit applies.',
            ),
          )
          .toList(growable: false);

  static final List<_SignSeed> _regulatorySigns = [
    const _SignSeed(
      id: 'stop_sign',
      title: 'Stop Sign',
      icon: '\u{1F6D1}',
      meaning: 'You must come to a complete stop.',
    ),
    const _SignSeed(
      id: 'give_way',
      title: 'Give Way',
      icon: '\u{1F6A7}',
      meaning: 'Yield and allow priority traffic to pass.',
    ),
    const _SignSeed(
      id: 'no_entry',
      title: 'No Entry',
      icon: '\u26D4',
      meaning: 'Do not enter from this direction.',
    ),
    const _SignSeed(
      id: 'one_way',
      title: 'One Way',
      icon: '\u27A1\uFE0F',
      meaning: 'Travel only in the indicated direction.',
    ),
    const _SignSeed(
      id: 'no_u_turn',
      title: 'No U-Turn',
      icon: '\u21A9\uFE0F',
      meaning: 'U-turns are prohibited here.',
    ),
    const _SignSeed(
      id: 'no_right_turn',
      title: 'No Right Turn',
      icon: '\u27A1\uFE0F',
      meaning: 'Right turns are prohibited here.',
    ),
    const _SignSeed(
      id: 'no_left_turn',
      title: 'No Left Turn',
      icon: '\u2B05\uFE0F',
      meaning: 'Left turns are prohibited here.',
    ),
    const _SignSeed(
      id: 'no_overtaking',
      title: 'No Overtaking',
      icon: '\u{1F6AB}',
      meaning: 'Overtaking is not allowed.',
    ),
    const _SignSeed(
      id: 'no_horn',
      title: 'No Horn',
      icon: '\u{1F507}',
      meaning: 'Use of horn is prohibited.',
    ),
    const _SignSeed(
      id: 'no_parking',
      title: 'No Parking',
      icon: '\u{1F17F}\uFE0F',
      meaning: 'Parking is prohibited.',
    ),
    const _SignSeed(
      id: 'no_stopping',
      title: 'No Stopping',
      icon: '\u{1F6AB}',
      meaning: 'Stopping your vehicle is prohibited.',
    ),
    const _SignSeed(
      id: 'no_pedestrians',
      title: 'No Pedestrians',
      icon: '\u{1F6B7}',
      meaning: 'Pedestrians are not allowed.',
    ),
    const _SignSeed(
      id: 'no_cycles',
      title: 'No Cycles',
      icon: '\u{1F6B3}',
      meaning: 'Bicycles are not allowed.',
    ),
    const _SignSeed(
      id: 'no_handcarts',
      title: 'No Hand Carts',
      icon: '\u{1F69A}',
      meaning: 'Hand carts are not allowed.',
    ),
    const _SignSeed(
      id: 'no_animal_drawn_vehicles',
      title: 'No Animal-Drawn Vehicles',
      icon: '\u{1F402}',
      meaning: 'Animal-drawn vehicles are not allowed.',
    ),
    const _SignSeed(
      id: 'no_bullock_carts',
      title: 'No Bullock Carts',
      icon: '\u{1F402}',
      meaning: 'Bullock carts are not allowed.',
    ),
    const _SignSeed(
      id: 'no_trucks',
      title: 'No Trucks',
      icon: '\u{1F69A}',
      meaning: 'Trucks are not allowed.',
    ),
    const _SignSeed(
      id: 'no_tractor_vehicles',
      title: 'No Tractors',
      icon: '\u{1F69C}',
      meaning: 'Tractors are not allowed.',
    ),
    const _SignSeed(
      id: 'no_motor_vehicles',
      title: 'No Motor Vehicles',
      icon: '\u{1F698}',
      meaning: 'Motor vehicles are not allowed.',
    ),
    const _SignSeed(
      id: 'axle_load_limit_10t',
      title: 'Axle Load Limit 10T',
      icon: '\u2696\uFE0F',
      meaning: 'Vehicles above 10 tonnes axle load are not allowed.',
    ),
    const _SignSeed(
      id: 'gross_weight_limit_20t',
      title: 'Gross Weight Limit 20T',
      icon: '\u2696\uFE0F',
      meaning: 'Vehicles above 20 tonnes gross weight are not allowed.',
    ),
    const _SignSeed(
      id: 'height_limit_3_5m',
      title: 'Height Limit 3.5m',
      icon: '\u2B06\uFE0F',
      meaning: 'Vehicles higher than 3.5 meters are not allowed.',
    ),
    const _SignSeed(
      id: 'width_limit_2_0m',
      title: 'Width Limit 2.0m',
      icon: '\u2194\uFE0F',
      meaning: 'Vehicles wider than 2.0 meters are not allowed.',
    ),
    const _SignSeed(
      id: 'length_limit_10m',
      title: 'Length Limit 10m',
      icon: '\u2195\uFE0F',
      meaning: 'Vehicles longer than 10 meters are not allowed.',
    ),
    ..._speedLimitSigns,
    const _SignSeed(
      id: 'end_speed_limit',
      title: 'End Speed Limit',
      icon: '\u2714\uFE0F',
      meaning: 'The previous speed restriction ends here.',
    ),
    const _SignSeed(
      id: 'compulsory_ahead',
      title: 'Compulsory Ahead',
      icon: '\u2B06\uFE0F',
      meaning: 'You must move straight ahead.',
    ),
    const _SignSeed(
      id: 'compulsory_turn_left',
      title: 'Compulsory Turn Left',
      icon: '\u2B05\uFE0F',
      meaning: 'You must turn left.',
    ),
    const _SignSeed(
      id: 'compulsory_turn_right',
      title: 'Compulsory Turn Right',
      icon: '\u27A1\uFE0F',
      meaning: 'You must turn right.',
    ),
    const _SignSeed(
      id: 'compulsory_keep_left',
      title: 'Compulsory Keep Left',
      icon: '\u2B05\uFE0F',
      meaning: 'Keep to the left side of the road.',
    ),
    const _SignSeed(
      id: 'compulsory_keep_right',
      title: 'Compulsory Keep Right',
      icon: '\u27A1\uFE0F',
      meaning: 'Keep to the right side of the road.',
    ),
    const _SignSeed(
      id: 'compulsory_cycle_track',
      title: 'Compulsory Cycle Track',
      icon: '\u{1F6B2}',
      meaning: 'Cyclists must use the cycle track.',
    ),
    const _SignSeed(
      id: 'compulsory_bus_lane',
      title: 'Compulsory Bus Lane',
      icon: '\u{1F68C}',
      meaning: 'Buses must use the designated lane.',
    ),
    const _SignSeed(
      id: 'compulsory_roundabout',
      title: 'Compulsory Roundabout',
      icon: '\u{1F503}',
      meaning: 'Follow the roundabout direction.',
    ),
    const _SignSeed(
      id: 'pedestrian_only_zone',
      title: 'Pedestrian Only Zone',
      icon: '\u{1F6B6}',
      meaning: 'Only pedestrians are allowed in this zone.',
    ),
    const _SignSeed(
      id: 'minimum_speed_30',
      title: 'Minimum Speed 30',
      icon: '\u23F1\uFE0F',
      meaning: 'Maintain at least 30 km/h when safe.',
    ),
    const _SignSeed(
      id: 'horn_compulsory',
      title: 'Horn Compulsory',
      icon: '\u{1F50A}',
      meaning: 'Use horn where mandatory for blind curves.',
    ),
    const _SignSeed(
      id: 'end_of_restrictions',
      title: 'End of Restrictions',
      icon: '\u2714\uFE0F',
      meaning: 'All previous restrictions end.',
    ),
    const _SignSeed(
      id: 'truck_lay_by',
      title: 'Truck Lay-By',
      icon: '\u{1F69B}',
      meaning: 'Heavy vehicles should use the lay-by area.',
    ),
  ];

  static const List<_SignSeed> _warningSigns = [
    _SignSeed(
      id: 'right_hand_curve',
      title: 'Right Hand Curve',
      icon: '\u26A0\uFE0F',
      meaning: 'Road curves to the right ahead.',
    ),
    _SignSeed(
      id: 'left_hand_curve',
      title: 'Left Hand Curve',
      icon: '\u26A0\uFE0F',
      meaning: 'Road curves to the left ahead.',
    ),
    _SignSeed(
      id: 'right_hairpin_bend',
      title: 'Right Hairpin Bend',
      icon: '\u26A0\uFE0F',
      meaning: 'Sharp right hairpin bend ahead.',
    ),
    _SignSeed(
      id: 'left_hairpin_bend',
      title: 'Left Hairpin Bend',
      icon: '\u26A0\uFE0F',
      meaning: 'Sharp left hairpin bend ahead.',
    ),
    _SignSeed(
      id: 'reverse_bend_right',
      title: 'Reverse Bend (Right First)',
      icon: '\u26A0\uFE0F',
      meaning: 'Series of bends starts with a right curve.',
    ),
    _SignSeed(
      id: 'reverse_bend_left',
      title: 'Reverse Bend (Left First)',
      icon: '\u26A0\uFE0F',
      meaning: 'Series of bends starts with a left curve.',
    ),
    _SignSeed(
      id: 'steep_ascent',
      title: 'Steep Ascent',
      icon: '\u26A0\uFE0F',
      meaning: 'Steep uphill section ahead.',
    ),
    _SignSeed(
      id: 'steep_descent',
      title: 'Steep Descent',
      icon: '\u26A0\uFE0F',
      meaning: 'Steep downhill section ahead.',
    ),
    _SignSeed(
      id: 'narrow_road_ahead',
      title: 'Narrow Road Ahead',
      icon: '\u26A0\uFE0F',
      meaning: 'Road width reduces ahead.',
    ),
    _SignSeed(
      id: 'road_widens_ahead',
      title: 'Road Widens Ahead',
      icon: '\u26A0\uFE0F',
      meaning: 'Road becomes wider ahead.',
    ),
    _SignSeed(
      id: 'narrow_bridge',
      title: 'Narrow Bridge',
      icon: '\u26A0\uFE0F',
      meaning: 'Bridge ahead is narrow.',
    ),
    _SignSeed(
      id: 'dangerous_dip',
      title: 'Dangerous Dip',
      icon: '\u26A0\uFE0F',
      meaning: 'Sudden dip in road ahead.',
    ),
    _SignSeed(
      id: 'hump_ahead',
      title: 'Hump Ahead',
      icon: '\u26A0\uFE0F',
      meaning: 'Speed hump ahead.',
    ),
    _SignSeed(
      id: 'uneven_road',
      title: 'Uneven Road',
      icon: '\u26A0\uFE0F',
      meaning: 'Uneven surface ahead.',
    ),
    _SignSeed(
      id: 'loose_gravel',
      title: 'Loose Gravel',
      icon: '\u26A0\uFE0F',
      meaning: 'Loose gravel on road ahead.',
    ),
    _SignSeed(
      id: 'slippery_road',
      title: 'Slippery Road',
      icon: '\u26A0\uFE0F',
      meaning: 'Road may be slippery ahead.',
    ),
    _SignSeed(
      id: 'falling_rocks',
      title: 'Falling Rocks',
      icon: '\u26A0\uFE0F',
      meaning: 'Falling rocks hazard ahead.',
    ),
    _SignSeed(
      id: 'side_wind',
      title: 'Side Wind',
      icon: '\u26A0\uFE0F',
      meaning: 'Strong side winds likely.',
    ),
    _SignSeed(
      id: 'cross_road',
      title: 'Cross Road',
      icon: '\u26A0\uFE0F',
      meaning: 'Cross intersection ahead.',
    ),
    _SignSeed(
      id: 't_intersection',
      title: 'T-Intersection',
      icon: '\u26A0\uFE0F',
      meaning: 'T-junction ahead.',
    ),
    _SignSeed(
      id: 'y_intersection',
      title: 'Y-Intersection',
      icon: '\u26A0\uFE0F',
      meaning: 'Y-junction ahead.',
    ),
    _SignSeed(
      id: 'staggered_intersection',
      title: 'Staggered Intersection',
      icon: '\u26A0\uFE0F',
      meaning: 'Offset junctions ahead.',
    ),
    _SignSeed(
      id: 'side_road_left',
      title: 'Side Road Left',
      icon: '\u26A0\uFE0F',
      meaning: 'Side road merges from left.',
    ),
    _SignSeed(
      id: 'side_road_right',
      title: 'Side Road Right',
      icon: '\u26A0\uFE0F',
      meaning: 'Side road merges from right.',
    ),
    _SignSeed(
      id: 'roundabout_ahead',
      title: 'Roundabout Ahead',
      icon: '\u26A0\uFE0F',
      meaning: 'Roundabout ahead.',
    ),
    _SignSeed(
      id: 'traffic_signal_ahead',
      title: 'Traffic Signal Ahead',
      icon: '\u26A0\uFE0F',
      meaning: 'Traffic signal ahead.',
    ),
    _SignSeed(
      id: 'pedestrian_crossing',
      title: 'Pedestrian Crossing',
      icon: '\u26A0\uFE0F',
      meaning: 'Pedestrian crossing ahead.',
    ),
    _SignSeed(
      id: 'school_ahead',
      title: 'School Ahead',
      icon: '\u26A0\uFE0F',
      meaning: 'School zone ahead; slow down.',
    ),
    _SignSeed(
      id: 'cycle_crossing',
      title: 'Cycle Crossing',
      icon: '\u26A0\uFE0F',
      meaning: 'Cycle crossing ahead.',
    ),
    _SignSeed(
      id: 'cattle_crossing',
      title: 'Cattle Crossing',
      icon: '\u26A0\uFE0F',
      meaning: 'Animals may cross ahead.',
    ),
    _SignSeed(
      id: 'men_at_work',
      title: 'Men at Work',
      icon: '\u26A0\uFE0F',
      meaning: 'Road work ahead.',
    ),
    _SignSeed(
      id: 'guarded_railway_crossing',
      title: 'Guarded Railway Crossing',
      icon: '\u26A0\uFE0F',
      meaning: 'Guarded railway crossing ahead.',
    ),
    _SignSeed(
      id: 'unguarded_railway_crossing',
      title: 'Unguarded Railway Crossing',
      icon: '\u26A0\uFE0F',
      meaning: 'Unguarded railway crossing ahead.',
    ),
    _SignSeed(
      id: 'ferry_ahead',
      title: 'Ferry Ahead',
      icon: '\u26A0\uFE0F',
      meaning: 'Ferry point ahead.',
    ),
    _SignSeed(
      id: 'low_flying_aircraft',
      title: 'Low Flying Aircraft',
      icon: '\u26A0\uFE0F',
      meaning: 'Low flying aircraft zone ahead.',
    ),
    _SignSeed(
      id: 'river_bank',
      title: 'River Bank',
      icon: '\u26A0\uFE0F',
      meaning: 'Road near unprotected river bank.',
    ),
    _SignSeed(
      id: 'road_narrows_left',
      title: 'Road Narrows Left',
      icon: '\u26A0\uFE0F',
      meaning: 'Road narrows on the left side.',
    ),
    _SignSeed(
      id: 'road_narrows_right',
      title: 'Road Narrows Right',
      icon: '\u26A0\uFE0F',
      meaning: 'Road narrows on the right side.',
    ),
    _SignSeed(
      id: 'merging_traffic_left',
      title: 'Merging Traffic Left',
      icon: '\u26A0\uFE0F',
      meaning: 'Traffic merges from left ahead.',
    ),
    _SignSeed(
      id: 'merging_traffic_right',
      title: 'Merging Traffic Right',
      icon: '\u26A0\uFE0F',
      meaning: 'Traffic merges from right ahead.',
    ),
    _SignSeed(
      id: 'two_way_traffic',
      title: 'Two-Way Traffic',
      icon: '\u26A0\uFE0F',
      meaning: 'Two-way traffic section ahead.',
    ),
    _SignSeed(
      id: 'gap_in_median',
      title: 'Gap in Median',
      icon: '\u26A0\uFE0F',
      meaning: 'Median opening ahead.',
    ),
    _SignSeed(
      id: 'lane_ends_ahead',
      title: 'Lane Ends Ahead',
      icon: '\u26A0\uFE0F',
      meaning: 'One lane ends ahead; merge safely.',
    ),
    _SignSeed(
      id: 'queue_likely',
      title: 'Queue Likely',
      icon: '\u26A0\uFE0F',
      meaning: 'Traffic queue likely ahead.',
    ),
    _SignSeed(
      id: 'accident_prone_area',
      title: 'Accident Prone Area',
      icon: '\u26A0\uFE0F',
      meaning: 'Accident-prone stretch; drive cautiously.',
    ),
  ];

  static const List<_SignSeed> _informatorySigns = [
    _SignSeed(
      id: 'parking',
      title: 'Parking',
      icon: '\u{1F17F}\uFE0F',
      meaning: 'Parking area is available.',
    ),
    _SignSeed(
      id: 'parking_two_wheelers',
      title: 'Two-Wheeler Parking',
      icon: '\u{1F6F5}',
      meaning: 'Parking for two-wheelers is available.',
    ),
    _SignSeed(
      id: 'taxi_stand',
      title: 'Taxi Stand',
      icon: '\u{1F695}',
      meaning: 'Taxi stand is available here.',
    ),
    _SignSeed(
      id: 'auto_rickshaw_stand',
      title: 'Auto-Rickshaw Stand',
      icon: '\u{1F6FA}',
      meaning: 'Auto-rickshaw stand is available here.',
    ),
    _SignSeed(
      id: 'bus_stop',
      title: 'Bus Stop',
      icon: '\u{1F68C}',
      meaning: 'Bus stop ahead.',
    ),
    _SignSeed(
      id: 'bus_bay',
      title: 'Bus Bay',
      icon: '\u{1F68C}',
      meaning: 'Bus bay available for boarding and alighting.',
    ),
    _SignSeed(
      id: 'railway_station',
      title: 'Railway Station',
      icon: '\u{1F686}',
      meaning: 'Railway station nearby.',
    ),
    _SignSeed(
      id: 'metro_station',
      title: 'Metro Station',
      icon: '\u{1F687}',
      meaning: 'Metro station nearby.',
    ),
    _SignSeed(
      id: 'airport',
      title: 'Airport',
      icon: '\u2708\uFE0F',
      meaning: 'Airport nearby.',
    ),
    _SignSeed(
      id: 'hospital',
      title: 'Hospital',
      icon: '\u{1F3E5}',
      meaning: 'Hospital nearby.',
    ),
    _SignSeed(
      id: 'first_aid_post',
      title: 'First Aid Post',
      icon: '\u{1FA79}',
      meaning: 'First aid facility nearby.',
    ),
    _SignSeed(
      id: 'fuel_station',
      title: 'Fuel Station',
      icon: '\u26FD',
      meaning: 'Fuel station nearby.',
    ),
    _SignSeed(
      id: 'ev_charging_station',
      title: 'EV Charging Station',
      icon: '\u26A1',
      meaning: 'Electric vehicle charging station nearby.',
    ),
    _SignSeed(
      id: 'restaurant',
      title: 'Restaurant',
      icon: '\u{1F37D}\uFE0F',
      meaning: 'Restaurant nearby.',
    ),
    _SignSeed(
      id: 'hotel_motel',
      title: 'Hotel / Motel',
      icon: '\u{1F3E8}',
      meaning: 'Hotel or motel nearby.',
    ),
    _SignSeed(
      id: 'public_toilet',
      title: 'Public Toilet',
      icon: '\u{1F6BB}',
      meaning: 'Public toilet facility nearby.',
    ),
    _SignSeed(
      id: 'drinking_water',
      title: 'Drinking Water',
      icon: '\u{1F6B0}',
      meaning: 'Drinking water available nearby.',
    ),
    _SignSeed(
      id: 'telephone_booth',
      title: 'Telephone Booth',
      icon: '\u260E\uFE0F',
      meaning: 'Public telephone facility nearby.',
    ),
    _SignSeed(
      id: 'police_station',
      title: 'Police Station',
      icon: '\u{1F46E}',
      meaning: 'Police station nearby.',
    ),
    _SignSeed(
      id: 'post_office',
      title: 'Post Office',
      icon: '\u{1F4EE}',
      meaning: 'Post office nearby.',
    ),
    _SignSeed(
      id: 'rest_area',
      title: 'Rest Area',
      icon: '\u{1F6CC}',
      meaning: 'Rest area ahead.',
    ),
    _SignSeed(
      id: 'picnic_spot',
      title: 'Picnic Spot',
      icon: '\u{1F9FA}',
      meaning: 'Picnic spot nearby.',
    ),
    _SignSeed(
      id: 'toll_plaza',
      title: 'Toll Plaza',
      icon: '\u{1F6A7}',
      meaning: 'Toll plaza ahead.',
    ),
    _SignSeed(
      id: 'city_center',
      title: 'City Center',
      icon: '\u{1F3D9}\uFE0F',
      meaning: 'City center direction.',
    ),
    _SignSeed(
      id: 'dead_end',
      title: 'Dead End',
      icon: '\u26D4',
      meaning: 'Road ends ahead.',
    ),
    _SignSeed(
      id: 'u_turn_permitted',
      title: 'U-Turn Permitted',
      icon: '\u21A9\uFE0F',
      meaning: 'U-turn is permitted here.',
    ),
    _SignSeed(
      id: 'route_diversion',
      title: 'Route Diversion',
      icon: '\u{1F6A7}',
      meaning: 'Follow diversion route.',
    ),
    _SignSeed(
      id: 'detour',
      title: 'Detour',
      icon: '\u{1F6A7}',
      meaning: 'Detour ahead due to closure or maintenance.',
    ),
    _SignSeed(
      id: 'truck_parking',
      title: 'Truck Parking',
      icon: '\u{1F69B}',
      meaning: 'Parking for trucks is available.',
    ),
    _SignSeed(
      id: 'emergency_escape_ramp',
      title: 'Emergency Escape Ramp',
      icon: '\u{1F6A8}',
      meaning: 'Emergency escape ramp available ahead.',
    ),
  ];
}
