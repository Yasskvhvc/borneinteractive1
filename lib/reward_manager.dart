import 'package:flutter/material.dart';

class RewardManager {
  static final ValueNotifier<bool> hasReward = ValueNotifier<bool>(false);

  static void setReward(bool value) {
    hasReward.value = value;
  }

  static void clearReward() {
    hasReward.value = false;
  }
}