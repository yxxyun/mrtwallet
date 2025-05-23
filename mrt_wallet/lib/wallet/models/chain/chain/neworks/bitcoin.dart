part of 'package:mrt_wallet/wallet/models/chain/chain/chain.dart';

class BitcoinChain extends Chain<
    BaseBitcoinAPIProvider,
    BitcoinParams,
    BitcoinBaseAddress,
    TokenCore,
    NFTCore,
    IBitcoinAddress,
    WalletBitcoinNetwork,
    BitcoinClient,
    ChainStorageKey,
    DefaultChainConfig,
    WalletTransaction<BitcoinBaseAddress>> {
  BitcoinChain._({
    required super.network,
    required super.totalBalance,
    required super.addressIndex,
    required super.id,
    required super.config,
    required super.client,
    required super.contacts,
    required super.addresses,
    required super.status,
  }) : super._();
  @override
  BitcoinChain copyWith(
      {WalletBitcoinNetwork? network,
      Live<IntegerBalance>? totalBalance,
      List<IBitcoinAddress>? addresses,
      List<ContactCore<BitcoinBaseAddress>>? contacts,
      int? addressIndex,
      BitcoinClient? client,
      String? id,
      DefaultChainConfig? config,
      WalletChainStatus? status}) {
    return BitcoinChain._(
        network: network ?? this.network,
        totalBalance: totalBalance ?? this.totalBalance,
        addressIndex: addressIndex ?? _addressIndex,
        addresses: addresses ?? _addresses,
        contacts: contacts ?? _contacts,
        client: client ?? _client,
        id: id ?? this.id,
        config: config ?? this.config,
        status: status ?? _chainStatus);
  }

  factory BitcoinChain.setup(
      {required WalletBitcoinNetwork network,
      required String id,
      BitcoinClient? client}) {
    return BitcoinChain._(
        network: network,
        addressIndex: 0,
        id: id,
        totalBalance:
            Live(IntegerBalance.zero(network.coinParam.token.decimal!)),
        client: client,
        addresses: [],
        config: DefaultChainConfig.none,
        contacts: [],
        status: WalletChainStatus.ready);
  }

  factory BitcoinChain.deserialize(
      {required WalletBitcoinNetwork network,
      required CborListValue cbor,
      BitcoinClient? client}) {
    final int networkId = cbor.elementAt(0);
    if (networkId != network.value) {
      throw WalletExceptionConst.incorrectNetwork;
    }
    final List<CborObject> accounts = cbor.elementAt(1) ?? <CborObject>[];
    final List<IBitcoinAddress> toAccounts = [];
    for (final i in accounts) {
      final acc = MethodUtils.nullOnException(
          () => CryptoAddress.fromCbor(network, i).cast<IBitcoinAddress>());
      if (acc != null) {
        toAccounts.add(acc);
      }
    }
    int addressIndex = (cbor.elementAt(5) ?? 0);
    if (addressIndex >= toAccounts.length) {
      addressIndex = 0;
    }
    List<ContactCore<BitcoinBaseAddress>> contacts = [];
    final List? cborContacts = cbor.elementAt(3);
    if (cborContacts != null) {
      contacts = cborContacts
          .map((e) => ContactCore.fromCborBytesOrObject<BitcoinBaseAddress>(
              network,
              obj: e))
          .toList();
    }
    final BigInt? totalBalance = cbor.elementAt(4);

    return BitcoinChain._(
        network: network,
        addresses: toAccounts,
        addressIndex: addressIndex < 0 ? 0 : addressIndex,
        contacts: contacts,
        totalBalance: Live(IntegerBalance(
            totalBalance ?? BigInt.zero, network.coinParam.token.decimal!)),
        client: client,
        id: cbor.elementAt<String>(8),
        config: DefaultChainConfig.none,
        status: WalletChainStatus.ready);
  }

  BitcoinBaseAddress? findAddressFromScript(Script script) {
    return _addresses
        .firstWhereOrNull((e) => e.networkAddress.toScriptPubKey() == script)
        ?.networkAddress;
  }
}
