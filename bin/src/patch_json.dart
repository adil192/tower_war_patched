import 'dart:convert';
import 'dart:io';

typedef JsonMap = Map<String, dynamic>;

Future<void> patchGameSettingsJson(String? gameSettingsJson) async {
  if (gameSettingsJson == null) {
    print('Could not patch getGameSettingsJson()');
    return;
  }

  final smaliFile = await Process.run('grep', [
    '--include=*.smali',
    '-Rl',
    'original/',
    '-e',
    // '".method public final getGameSettingsJson()Ljava/lang/String;"',
    'method public final getGameSettingsJson',
  ]).then((result) => File(result.stdout.trim()));
  print('Patching getGameSettingsJson in $smaliFile...');

  final lines = await smaliFile.readAsLines();
  int bodyStart = -1;
  int bodyEnd = -1;
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    if (line.trim() ==
        '.method public final getGameSettingsJson()Ljava/lang/String;') {
      bodyStart = i + 1;
    } else if (line.trim() == '.end method' && bodyStart != -1) {
      bodyEnd = i;
      break;
    }
  }

  if (bodyStart == -1 || bodyEnd == -1) {
    print('Failed to find getGameSettingsJson in $smaliFile');
    return;
  }

  lines.removeRange(bodyStart, bodyEnd);
  lines.insertAll(bodyStart, [
    '    .locals 1',
    '    ',
    // Here we jsonEncode the string to wrap it in quotes
    '    const-string v0, ${jsonEncode(gameSettingsJson)}',
    '    ',
    '    return-object v0',
  ]);

  await smaliFile.writeAsString(lines.join('\n'));
  print('Patched getGameSettingsJson in $smaliFile');
}

/// Returns the game_settings json as a string
Future<String?> patchJson() async {
  final File jsonFile;
  try {
    jsonFile = await _findJsonFile();
  } catch (e) {
    print(e);
    return null;
  }
  final json = await jsonFile.readAsString().then(jsonDecode) as JsonMap;

  json['game_settings']['ad_banner_enable'] = 0;

  final arenaConfig =
      jsonDecode(json['game_settings']['arenaConfig']) as JsonMap;
  _patchArenaConfig(arenaConfig);
  json['game_settings']['arenaConfig'] = jsonEncode(arenaConfig);

  final battlePassRewards =
      jsonDecode(json['game_settings']['battle_pass_rewards']) as JsonMap;
  _patchBattlePassRewards(battlePassRewards);
  json['game_settings']['battle_pass_rewards'] = jsonEncode(battlePassRewards);

  final goldChest = jsonDecode(json['game_settings']['gold_chest']) as JsonMap;
  goldChest['ChestPrice'] = 6; // from 60
  goldChest['TimeForFreeChest'] = 43200; // 12 hours from never
  json['game_settings']['gold_chest'] = jsonEncode(goldChest);
  json['game_settings']['open_ten_chests_price'] = 54; // from 540

  json['game_settings']['level_interstitial_first_level'] = 1000000; // from 14
  json['game_settings']['level_interstitial_max_per_level'] = 1; // from 2
  json['game_settings']['level_interstitial_progress_min'] = 0.0; // from 0.2
  json['game_settings']['level_interstitial_progress_max'] = 0.1; // from 0.8
  json['game_settings']['level_interstitial_show_adbrake_screen'] = 0; // from 1

  final personalizationIcons =
      jsonDecode(json['game_settings']['personalization_unique_icons']) as List;
  for (final icon in personalizationIcons) {
    icon['Price'] = (int.parse(icon['Price']) ~/ 10).toString();
  }
  json['game_settings']['personalization_unique_icons'] =
      jsonEncode(personalizationIcons);

  final rarityUpgradeData =
      jsonDecode(json['game_settings']['rarity_upgrade_data']) as List;
  for (final upgrade in rarityUpgradeData) {
    upgrade['StartPrice'] = (int.parse(upgrade['StartPrice']) ~/ 10).toString();
    upgrade['AddPriceByLevel'] =
        (int.parse(upgrade['AddPriceByLevel']) ~/ 10).toString();
  }
  json['game_settings']['rarity_upgrade_data'] = jsonEncode(rarityUpgradeData);

  json['game_settings']['rate_us_level_delay'] = 1000000; // from 50
  json['game_settings']['show_offers_delay'] = 1000000; // from 300
  json['game_settings']['show_rateus_after_level'] = 1000000; // from 6
  json['game_settings']['show_bomb_button_free_count'] = 1000000; // from 0
  json['game_settings']['show_bomb_price'] = 50; // from 250

  final itemsOffer =
      jsonDecode(json['game_settings']['show_items_offer_in_shop']) as JsonMap;
  itemsOffer['IsEnable'] = 1; // from 0
  for (final offer in itemsOffer['ArtefactsOfferConfigJsonData']) {
    offer['GoldPrice'] = (offer['GoldPrice'] as int) ~/ 10;
    offer['RubyPrice'] = (offer['RubyPrice'] as int) ~/ 10;
  }
  json['game_settings']['show_items_offer_in_shop'] = jsonEncode(itemsOffer);

  final itemsOfferPacks =
      jsonDecode(json['game_settings']['show_items_offer_packs']) as JsonMap;
  itemsOfferPacks['IsEnable'] = 1; // from 0
  json['game_settings']['show_items_offer_packs'] = jsonEncode(itemsOfferPacks);

  final silverChest =
      jsonDecode(json['game_settings']['silver_chest']) as JsonMap;
  silverChest['ChestPrice'] = 2; // from 15
  silverChest['TimeForFreeChest'] = 3600; // 1 hour from 24 hours
  json['game_settings']['silver_chest'] = jsonEncode(silverChest);

  final spinRewardList =
      (jsonDecode(json['game_settings']['spin_reward_list']) as List)
          .where((reward) {
    if (reward['Type'] == 'Gold') return false;
    if (reward['Type'] == 'Ruby') reward['Count'] *= 10;
    return true;
  }).toList();
  jsonEncode(spinRewardList);

  final summonList = (jsonDecode(json['game_settings']['summon_list']) as List)
      .where((summon) => summon['RarityType'] != 'Grey')
      .toList();
  json['game_settings']['summon_list'] = jsonEncode(summonList);

  json['game_settings']['summon_unit_price'] = 3; // from 25

  final tokensUpgradeList =
      jsonDecode(json['game_settings']['tokens_upgrade_list']) as List;
  for (final upgrade in tokensUpgradeList) {
    upgrade['NeedToken'] = 0;
  }
  json['game_settings']['tokens_upgrade_list'] = jsonEncode(tokensUpgradeList);

  print('Patching game_settings in $jsonFile...');
  await jsonFile.writeAsString(jsonEncode(json));

  return jsonEncode(json['game_settings']);
}

Future<File> _findJsonFile() async {
  final expectedFile = File('original/assets/saykit_mlltrna_1.23.3.json');
  if (expectedFile.existsSync()) return expectedFile;

  await for (var entity in Directory('original/assets/').list()) {
    if (entity is! File) continue;

    final fileName = entity.path.split('/').last;
    if (fileName.startsWith('saykit_mlltrna_') && fileName.endsWith('.json')) {
      print('Warning: $expectedFile not found! '
          'Using $fileName instead.');
      return entity;
    }
  }

  throw '$expectedFile not found!';
}

void _patchArenaConfig(JsonMap arenaConfig) {
  arenaConfig['challengeAttemptsCount'] = 50; // from 5
  for (final rewardGroup in [
    ...(arenaConfig['dailyArenaRewards'] as List),
    ...(arenaConfig['seasonArenaRewards'] as List),
  ]) {
    final rewards = rewardGroup['rewards'] as List;
    for (final reward in rewards) {
      // { "key": "currency", "amount": 2000, "rarity": 1, "currencyType": 7 }
      reward['amount'] = (reward['amount'] as int) * 10;
    }
    if (!rewards.any((r) => r['currencyType'] == 5)) {
      // Add some keys
      rewards.add(
          {"key": "currency", "amount": 1, "rarity": 1, "currencyType": 5});
    }
    if (!rewards.any((r) => r['currencyType'] == 2)) {
      // Add some gems
      rewards.add(
          {"key": "currency", "amount": 25, "rarity": 1, "currencyType": 2});
    }
  }
}

void _patchBattlePassRewards(JsonMap battlePassRewards) {
  final freeRewards = battlePassRewards['FreeRewards'] as List;
  final paidRewards = battlePassRewards['PaidRewards'] as List;
  assert(freeRewards.length == paidRewards.length);

  final newRewards = [];

  /// VIP rewards will be interspersed with the new rewards.
  const vipReward = {
    "RewardType": "Vip",
    "Highlighted": 0,
    "RewardColor": "Gold",
    "RewardCount": 259200, // 3 days
  };

  void addReward(JsonMap reward) {
    const boringRewardTypes = ['Gold', 'Ruby', 'Vip'];
    final rewardType = reward['RewardType'] as String;
    if (boringRewardTypes.contains(rewardType)) return;

    newRewards.add(vipReward);
    newRewards.add(reward);
  }

  for (var i = 0; i < freeRewards.length; i++) {
    final freeReward = freeRewards[i] as JsonMap;
    final paidReward = paidRewards[i] as JsonMap;

    addReward(freeReward);
    addReward(paidReward);
  }

  while (newRewards.length < paidRewards.length) {
    newRewards.add(newRewards.last);
  }
  while (paidRewards.length < newRewards.length) {
    paidRewards.add(paidRewards.last);
  }

  battlePassRewards['FreeRewards'] = newRewards;
}
