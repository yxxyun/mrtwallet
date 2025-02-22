import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:mrt_wallet/app/error/exception.dart';
import 'package:mrt_wallet/app/serialization/cbor/cbor.dart';
import 'package:mrt_wallet/crypto/coins/coins.dart';
import 'package:mrt_wallet/crypto/derivation/derivation.dart';
import 'package:mrt_wallet/crypto/keys/keys.dart';
import 'package:mrt_wallet/wallet/models/chain/address/networks/networks.dart';
import 'package:mrt_wallet/wallet/models/chain/address/creation_params/core/core.dart';
import 'package:mrt_wallet/wallet/models/network/network.dart';

class BitcoinCashNewAddressParams
    implements NewAccountParams<BitcoinBaseAddress> {
  @override
  bool get isMultiSig => false;
  @override
  final AddressDerivationIndex deriveIndex;
  final BitcoinAddressType bitcoinAddressType;
  @override
  final CryptoCoins coin;
  final PubKeyModes keyType;

  BitcoinCashNewAddressParams(
      {required this.deriveIndex,
      required this.bitcoinAddressType,
      required this.coin,
      required this.keyType});
  factory BitcoinCashNewAddressParams.deserialize(
      {List<int>? bytes, CborObject? object, String? hex}) {
    final CborListValue values = CborSerializable.cborTagValue(
        cborBytes: bytes,
        object: object,
        hex: hex,
        tags: NewAccountParamsType.bitcoinCashNewAddressParams.tag);
    return BitcoinCashNewAddressParams(
        deriveIndex: AddressDerivationIndex.fromCborBytesOrObject(
            obj: values.getCborTag(0)),
        bitcoinAddressType: BitcoinAddressType.fromValue(values.elementAt(1)),
        coin: CustomCoins.getSerializationCoin(values.elementAt(2)),
        keyType: PubKeyModes.fromValue(values.elementAs(3),
            defaultValue: PubKeyModes.compressed));
  }

  @override
  IBitcoinCashAddress toAccount(
      WalletNetwork network, CryptoPublicKeyData? publicKey) {
    if (publicKey == null) {
      throw WalletExceptionConst.pubkeyRequired;
    }
    return IBitcoinCashAddress.newAccount(
        accountParams: this,
        publicKey: publicKey.keyBytes(mode: keyType),
        network: network as WalletBitcoinNetwork);
  }

  @override
  CborTagValue toCbor() {
    return CborTagValue(
        CborListValue.dynamicLength([
          deriveIndex.toCbor(),
          bitcoinAddressType.value,
          coin.toCbor(),
          keyType.value
        ]),
        type.tag);
  }

  @override
  NewAccountParamsType get type =>
      NewAccountParamsType.bitcoinCashNewAddressParams;
}

class BitcoinCashMultiSigNewAddressParams
    implements BitcoinCashNewAddressParams {
  @override
  final BitcoinAddressType bitcoinAddressType;
  final BitcoinMultiSignatureAddress multiSignatureAddress;

  @override
  final AddressDerivationIndex deriveIndex;
  @override
  PubKeyModes get keyType =>
      throw UnsupportedError("key type must be implements on signers.");
  @override
  bool get isMultiSig => true;

  @override
  final CryptoCoins coin;
  const BitcoinCashMultiSigNewAddressParams(
      {required this.bitcoinAddressType,
      required this.multiSignatureAddress,
      required this.coin})
      : deriveIndex = const MultiSigAddressIndex();
  factory BitcoinCashMultiSigNewAddressParams.deserialize(
      {List<int>? bytes, CborObject? object, String? hex}) {
    final CborListValue values = CborSerializable.cborTagValue(
        cborBytes: bytes,
        object: object,
        hex: hex,
        tags: NewAccountParamsType.bitcoinCashMultiSigNewAddressParams.tag);
    return BitcoinCashMultiSigNewAddressParams(
      bitcoinAddressType: BitcoinAddressType.fromValue(values.elementAt(0)),
      multiSignatureAddress: BitcoinMultiSignatureAddress.fromCborBytesOrObject(
          obj: values.getCborTag(1)),
      coin: CustomCoins.getSerializationCoin(values.elementAt(2)),
    );
  }

  @override
  IBitcoinCashAddress toAccount(
      WalletNetwork network, CryptoPublicKeyData? publicKey) {
    return IBitcoinCashMultiSigAddress.newAccount(
        accountParam: this, network: network.toNetwork());
  }

  @override
  CborTagValue toCbor() {
    return CborTagValue(
        CborListValue.dynamicLength([
          bitcoinAddressType.value,
          multiSignatureAddress.toCbor(),
          coin.toCbor()
        ]),
        type.tag);
  }

  @override
  NewAccountParamsType get type =>
      NewAccountParamsType.bitcoinCashMultiSigNewAddressParams;
}
