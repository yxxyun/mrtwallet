import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:mrt_wallet/app/error/exception/wallet_ex.dart';
import 'package:mrt_wallet/app/serialization/serialization.dart';
import 'package:mrt_wallet/wroker/keys/access/private_key_response.dart';
import 'package:mrt_wallet/wroker/constant/const.dart';
import 'package:mrt_wallet/wroker/keys/models/seed.dart';
import 'package:mrt_wallet/wroker/derivation/derivation.dart';
import 'imported.dart';

class WalletMasterKeys with CborSerializable {
  final Mnemonic mnemonic;
  final List<int> seed;
  final List<int> entopySeed;
  final List<int> cardanoLegacyByronSeed;
  final List<int> cardanoIcarusSeed;
  final List<int> checksum;
  WalletMasterKeys._({
    required this.mnemonic,
    required List<int> seedBytes,
    required this.customKeys,
    required List<int> entropySeedBytes,
    required List<int> cardanoLegacyByronSeed,
    required List<int> cardanoIcarusSeed,
    required List<int> checksum,
  })  : seed = BytesUtils.toBytes(seedBytes, unmodifiable: true),
        cardanoLegacyByronSeed =
            BytesUtils.toBytes(cardanoLegacyByronSeed, unmodifiable: true),
        cardanoIcarusSeed =
            BytesUtils.toBytes(cardanoIcarusSeed, unmodifiable: true),
        checksum = BytesUtils.toBytes(checksum, unmodifiable: true),
        entopySeed = BytesUtils.toBytes(entropySeedBytes, unmodifiable: true);
  List<int> getSeed(SeedTypes type) {
    switch (type) {
      case SeedTypes.bip39:
        return seed;
      case SeedTypes.bip39Entropy:
        return entopySeed;
      case SeedTypes.icarus:
        return cardanoIcarusSeed;
      default:
        return cardanoLegacyByronSeed;
    }
  }

  WalletMasterKeys addKey(List<ImportedKeyStorage> newKey) {
    return WalletMasterKeys._(
        mnemonic: mnemonic,
        seedBytes: seed,
        customKeys: List.unmodifiable([...newKey, ...customKeys]),
        cardanoLegacyByronSeed: cardanoLegacyByronSeed,
        cardanoIcarusSeed: cardanoIcarusSeed,
        checksum: checksum,
        entropySeedBytes: entopySeed);
  }

  WalletMasterKeys removeKey(String keyId) {
    final accounts = customKeys.where((element) => element.checksum != keyId);
    return WalletMasterKeys._(
        mnemonic: mnemonic,
        seedBytes: seed,
        customKeys: List.unmodifiable(accounts),
        cardanoLegacyByronSeed: cardanoLegacyByronSeed,
        cardanoIcarusSeed: cardanoIcarusSeed,
        checksum: checksum,
        entropySeedBytes: entopySeed);
  }

  static WalletMasterKeys setup({
    required String mnemonic,
    required List<int> seed,
    required List<int> entropySeed,
    required List<int> icarus,
    required List<int> cardanoLegacy,
    required List<int> checksum,
    List<ImportedKeyStorage> customKeys = const [],
  }) {
    return WalletMasterKeys._(
        mnemonic: Mnemonic.fromString(mnemonic),
        seedBytes: seed,
        customKeys: List.unmodifiable(customKeys),
        cardanoLegacyByronSeed: cardanoLegacy,
        cardanoIcarusSeed: icarus,
        checksum: checksum,
        entropySeedBytes: entropySeed);
  }

  factory WalletMasterKeys.fromCborBytesOrObject(
      {List<int>? bytes, CborObject? obj}) {
    try {
      final CborListValue cbor =
          CborSerializable.decodeCborTags(bytes, obj, CryptoKeyConst.mnemonic);
      final String mnemonic = cbor.elementAt(0);
      final List<int> seed = cbor.elementAt(1);
      final CborListValue customKeys = cbor.value[2];
      final cardanoLegacy = cbor.elementAt<List<int>>(4);
      final icarus = cbor.elementAt<List<int>>(5);
      final entropySeed = cbor.elementAt<List<int>>(7);
      return WalletMasterKeys._(
          mnemonic: Mnemonic.fromString(mnemonic),
          seedBytes: seed,
          customKeys: List<ImportedKeyStorage>.unmodifiable(customKeys.value
              .map((e) => ImportedKeyStorage.fromCborBytesOrObject(obj: e))
              .toList()),
          cardanoLegacyByronSeed: cardanoLegacy,
          cardanoIcarusSeed: icarus,
          checksum: cbor.elementAt<List<int>>(6),
          entropySeedBytes: entropySeed);
    } catch (e) {
      throw WalletExceptionConst.invalidMnemonic;
    }
  }

  List<String> get toList => mnemonic.toList();
  final List<ImportedKeyStorage> customKeys;
  @override
  CborTagValue toCbor([bool withSeed = true]) {
    return CborTagValue(
        CborListValue.fixedLength([
          mnemonic.toStr(),
          if (withSeed) CborBytesValue(seed) else const CborBytesValue([]),
          CborListValue.fixedLength(customKeys.map((e) => e.toCbor()).toList()),
          const CborNullValue(),
          if (withSeed) ...[
            CborBytesValue(cardanoLegacyByronSeed),
            CborBytesValue(cardanoIcarusSeed)
          ] else ...[
            const CborBytesValue([]),
            const CborBytesValue([]),
          ],
          checksum,
          CborBytesValue(entopySeed)
        ]),
        CryptoKeyConst.mnemonic);
  }

  ImportedKeyStorage? getKeyById(String keyId) {
    try {
      return customKeys.firstWhere((element) => element.checksum == keyId);
    } on StateError {
      return null;
    }
  }

  PrivateKeyData toKey(AddressDerivationIndex key,
      {Bip44Levels maxLevel = Bip44Levels.addressIndex}) {
    if (key.isMultiSig) {
      throw WalletExceptionConst.multiSigDerivationNotSuported;
    }
    if (key.isImportedKey) {
      final customKey = getKeyById(key.importedKeyId!);
      if (customKey == null) {
        throw WalletExceptionConst.privateKeyIsNotAvailable;
      }
      return customKey.toKey(key, maxLevel: maxLevel);
    }
    final seedBytes = getSeed(key.seedGeneration);
    final bip32Key = PrivateKeyData.fromSeed(
        seedBytes: seedBytes, coin: key.currencyCoin, keyName: key.name);
    return key.derive(bip32Key, maxLevel: maxLevel);
  }
}
