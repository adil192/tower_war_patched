import 'dart:convert';
import 'dart:io';

typedef JsonMap = Map<String, dynamic>;

Future<void> patchJson() async {
  final jsonFile = await _findJsonFile();
  final json = await jsonFile.readAsString().then(jsonDecode) as JsonMap;

  json['game_settings']['ad_banner_enable'] = 0;

  final battlePassRewards =
      jsonDecode(json['game_settings']['battle_pass_rewards']) as JsonMap;
  _patchBattlePassRewards(battlePassRewards);
  json['game_settings']['battle_pass_rewards'] = jsonEncode(battlePassRewards);

  final goldChest = jsonDecode(json['game_settings']['gold_chest']) as JsonMap;
  goldChest['ChestPrice'] = 6; // from 60
  json['game_settings']['gold_chest'] = jsonEncode(goldChest);
  json['game_settings']['open_ten_chests_price'] = 54; // from 540

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

  json['summon_unit_price'] = 3; // from 25

  final tokensUpgradeList =
      jsonDecode(json['game_settings']['tokens_upgrade_list']) as List;
  for (final upgrade in tokensUpgradeList) {
    upgrade['NeedToken'] = 0;
  }
  json['game_settings']['tokens_upgrade_list'] = jsonEncode(tokensUpgradeList);

  print('Patching game_settings in $jsonFile...');
  await jsonFile.writeAsString(jsonEncode(json));
}

Future<File> _findJsonFile() async {
  final expectedFile = File('original/assets/saykit_mlltrna_1.19.1.json');
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
