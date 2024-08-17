part of '../handler.dart';

enum JSEthereumStatus {
  conected,
}

mixin JsEthereumHandler on JSWalletAuthenticated {
  Web3EthereumChain? _ethereumPermission;
  EthereumClient? _client;
  late EthereumChain _ethereumChain;
  BigInt get currentEthereumChain =>
      _ethereumPermission?.currentChain ?? BigInt.one;
  ChainsHandler get _chain;
  List<String> _accounts = [];

  void _onSubscribe(EthereumSubscribeResult result) {
    _sendMessageToClient(WalletEthereumEventResponse(
        event: EthereumEvnetTypes.message, data: result.toJson()));
  }

  void _initChain() {
    _disconnect();
    _ethereumPermission =
        _auth.getChainFromNetworkType<Web3EthereumChain>(NetworkType.ethereum);
    _ethereumChain = _chain
        .chains()
        .whereType<EthereumChain>()
        .firstWhere((e) => e.chainId == currentEthereumChain);
    _client?.dispose();
    _client = _ethereumChain.provider();
    _client?.init();
    if (_client?.supportSubscribe ?? false) {
      _client?.addSubscriptionListener(_onSubscribe);
    }
    final accounts = _ethereumPermission
        ?.currentChainAccounts(_ethereumChain)
        .map((e) => e.address.address)
        .toList();
    _accounts = List<String>.unmodifiable(accounts ?? []);
    _toggleEthereum();
    _connect();
    _chainChanged();
    _accountChanged();
  }

  void _authChanged() {
    final BigInt chainId = currentEthereumChain;
    _ethereumPermission =
        _auth.getChainFromNetworkType<Web3EthereumChain>(NetworkType.ethereum);
    if (chainId == currentEthereumChain) {
      final accounts = _ethereumPermission
          ?.currentChainAccounts(_ethereumChain)
          .map((e) => e.address.address)
          .toList();
      bool changed = false;
      if (!CompareUtils.iterableIsEqual(accounts, _accounts)) {
        changed = true;
      }
      _accounts = List<String>.unmodifiable(accounts ?? []);
      if (changed) {
        _accountChanged();
      }
      return;
    }
    _initChain();
  }

  void _disconnect() async {
    _sendMessageToClient(WalletEthereumEventResponse(
        event: EthereumEvnetTypes.disconnect,
        data: Web3RequestExceptionConst.disconnectedChain.toJson()));
  }

  void _connect() async {
    _sendMessageToClient(WalletEthereumEventResponse(
        event: EthereumEvnetTypes.connect,
        data: <String, dynamic>{"chainId": currentEthereumChain.toRadix16}));
  }

  void _accountChanged() async {
    _sendMessageToClient(WalletEthereumEventResponse(
        event: EthereumEvnetTypes.accountsChanged, data: _accounts));
  }

  void _chainChanged() async {
    _sendMessageToClient(WalletEthereumEventResponse(
        event: EthereumEvnetTypes.chainChanged,
        data: currentEthereumChain.toRadix16));
  }

  void _toggleEthereum() {
    if (_auth.active) {
      _sendMessageToClient(WalletEthereumEventResponse(
          event: EthereumEvnetTypes.active, data: null));
    } else {
      _sendMessageToClient(WalletEthereumEventResponse(
          event: EthereumEvnetTypes.disable,
          data: Web3RequestExceptionConst.bannedHost.data));
    }
  }

  Web3EthreumRequestAccounts _requestAccount() {
    return Web3EthreumRequestAccounts();
  }

  Web3MessageCore _eventMessage(EthereumEvnetTypes type) {
    switch (type) {
      case EthereumEvnetTypes.accountsChanged:
        return Web3ResponseMessage(_accounts);
      case EthereumEvnetTypes.chainChanged:
        return Web3ResponseMessage(currentEthereumChain.toRadix16);
      case EthereumEvnetTypes.connect:
        return Web3ResponseMessage(
            <String, dynamic>{"chainId": currentEthereumChain.toRadix16});
      case EthereumEvnetTypes.disconnect:
        return Web3ResponseMessage(
            Web3RequestExceptionConst.disconnectedChain.toJson());
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }

  Future<Web3MessageCore> _buildEthereumRequest(
      ClientEthereumRequest params) async {
    final isEvent = EthereumEvnetTypes.fromName(params.method);
    if (isEvent != null) {
      return _eventMessage(isEvent);
    }
    final method = Web3EthereumRequestMethods.fromName(params.method);
    if (method == null) return _rpcCall(params);
    switch (method) {
      case Web3EthereumRequestMethods.requestAccounts:
        if (_accounts.isNotEmpty) {
          return Web3ResponseMessage(_accounts);
        }
        return _requestAccount();
      case Web3EthereumRequestMethods.switchEthereumChain:
        final parse = _parseSwitchEthereumChain(params);
        if (parse.chainId == currentEthereumChain) {
          return Web3ResponseMessage(parse.chainId.toRadix16);
        }
        final chain = _chain
            .chains()
            .whereType<EthereumChain>()
            .firstWhereOrNull((e) => e.chainId == parse.chainId);
        if (chain == null) {
          throw Web3RequestExceptionConst.ethereumNetworkDoesNotExist;
        }
        return parse;
      case Web3EthereumRequestMethods.persoalSign:
        return _personalSign(params);
      case Web3EthereumRequestMethods.addEthereumChain:
        return _parseAddEthereumChain(params);
      case Web3EthereumRequestMethods.typedData:
        return _parseTypedData(params, currentEthereumChain);
      case Web3EthereumRequestMethods.sendTransaction:
        final transaction = _parseTransaction(params, currentEthereumChain);
        if (transaction.transactionType == ETHTransactionType.eip1559 &&
            !_ethereumChain.network.coinParam.supportEIP1559) {
          throw Web3RequestExceptionConst.invalidParameters(
              Web3RequestExceptionConst.eip1559NotSupported);
        }
        return transaction;
      case Web3EthereumRequestMethods.ethAccounts:
        return Web3ResponseMessage(_accounts);
      case Web3EthereumRequestMethods.ethChainId:
        return Web3ResponseMessage(currentEthereumChain.toRadix16);
      default:
        throw UnimplementedError();
    }
  }

  Future<Web3MessageCore> _rpcCall(ClientEthereumRequest params) async {
    final cl = _client;
    if (cl == null) {
      throw Web3RequestExceptionConst.disconnected();
    }
    await cl.init();
    if (!cl.isConnect) {
      throw Web3RequestExceptionConst.disconnectedChain;
    }

    final method = EthereumMethods.fromName(params.method);
    if (method == null) {
      throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    try {
      if (method == EthereumMethods.subscribe) {
        final result = await cl.subscribe(params: params.params);
        return Web3ResponseMessage(result);
      }
      final call = await cl.dynamicCall(method.value, params.params);
      return Web3ResponseMessage(call);
    } on RPCError catch (e) {
      throw Web3RequestException(
          message: e.message,
          code: e.errorCode,
          data: StringUtils.tryFromJson(e.data),
          walletCode: "WALLET-2000");
    } on ApiProviderException catch (e) {
      if (e.isTimeout) {
        throw Web3RequestExceptionConst.disconnected(
            message: Web3RequestExceptionConst.requestTimeoutMessage);
      } else {
        throw Web3RequestExceptionConst.disconnected();
      }
    } catch (e) {
      throw Web3RequestExceptionConst.disconnected();
    }
  }

  static EIP712Version _typedDataVersion(String methodName) {
    final version = int.tryParse(methodName[methodName.length - 1]) ?? 1;
    return EIP712Version.fromVersion(version);
  }

  static Web3EthreumTypdedData _parseTypedData(
      ClientEthereumRequest params, BigInt chainId) {
    try {
      final toList = params.paramsAsList(length: 2);
      if (toList == null) {
        throw Web3RequestExceptionConst.ethTypedData;
      }
      final EIP712Version version = _typedDataVersion(params.method);
      final String address;
      EIP712Base data;
      if (version == EIP712Version.v1) {
        address = toList[1];
        data = EIP712Legacy.fromJson(JsUtils.toList(toList[0])
            .map((e) => Map<String, dynamic>.from(e))
            .toList());
      } else {
        address = toList[0];
        data = Eip712TypedData.fromJson(JsUtils.toMap(toList[1]),
            version: version);
      }
      final typdedDataParams = Web3EthreumTypdedData.fromJson({
        "address": address,
        "typedData": StringUtils.fromJson(data.toJson())
      });

      return typdedDataParams;
    } on Web3RequestException {
      rethrow;
    } catch (e) {
      throw Web3RequestExceptionConst.ethTypedData;
    }
  }

  static Web3EthreumSwitchChain _parseSwitchEthereumChain(
      ClientEthereumRequest params) {
    final toList = params.paramsAsList(length: 1);
    if (toList == null) {
      throw Web3RequestExceptionConst.invalidList(params.method);
    }
    final toObject = JsUtils.toMap<String, dynamic>(toList[0],
        error:
            Web3RequestExceptionConst.invalidMethodArgruments(params.method));
    return Web3EthreumSwitchChain.fromJson(toObject);
  }

  Future<Web3EthereumAddNewChain> _parseAddEthereumChain(
      ClientEthereumRequest params) async {
    final toList = params.paramsAsList(length: 1);
    if (toList == null) {
      throw Web3RequestExceptionConst.invalidMethodArgruments(params.method);
    }
    final toObject = JsUtils.toMap<String, dynamic>(toList[0],
        error:
            Web3RequestExceptionConst.invalidMethodArgruments(params.method));

    final newChain = Web3EthereumAddNewChain.fromJson(toObject);
    final network = newChain.toNewNetwork();
    List<String> rpcsUrls = [];
    bool hasWrongChainId = false;
    for (final i in network.coinParam.providers) {
      final chainId = await MethodUtils.call(() async {
        final client = APIUtils.buildEthereumProvider(i, network);
        return await client.getChainId();
      });

      if (chainId.hasResult) {
        if (chainId.result == newChain.newChainId) {
          rpcsUrls.add(i.callUrl);
        } else {
          hasWrongChainId = true;
        }
      }
    }
    if (rpcsUrls.isEmpty) {
      if (hasWrongChainId) {
        throw Web3RequestExceptionConst.ethereumRpcWrongChainId;
      } else {
        throw Web3RequestExceptionConst.rpcConnection;
      }
    }
    return newChain.updateRpcUrl(rpcsUrls);
  }

  static Web3EthreumSendTransaction _parseTransaction(
      ClientEthereumRequest params, BigInt chainId) {
    final toList = params.paramsAsList(length: 1);
    if (toList == null) {
      throw Web3RequestExceptionConst.invalidMethodArgruments(params.method);
    }
    final transactionParam = toList[0];
    final Map<String, dynamic>? toJson = MethodUtils.nullOnException(() {
      if (transactionParam is String) {
        return StringUtils.tryToJson(transactionParam);
      } else {
        return Map<String, dynamic>.from(transactionParam);
      }
    });
    if (toJson == null) {
      throw Web3RequestExceptionConst.invalidMethodArgruments(params.method);
    }
    return Web3EthreumSendTransaction.fromJson(toJson);
  }

  Web3EthreumPersonalSign _personalSign(ClientEthereumRequest params) {
    final toList = params.paramsAsList(length: 2);
    if (toList == null) {
      throw Web3RequestExceptionConst.invalidMethodArgruments(params.method);
    }
    final Map<String, dynamic> message = {
      "address": toList[0],
      "challeng": toList[1]
    };
    message["chainId"] = currentEthereumChain.toString();
    return Web3EthreumPersonalSign.fromJson(message);
  }

  void _onDone(ClientRequest request) {
    final method = Web3EthereumRequestMethods.fromName(request.method);
    switch (method) {
      case Web3EthereumRequestMethods.addEthereumChain:
      case Web3EthereumRequestMethods.switchEthereumChain:
      case Web3EthereumRequestMethods.ethChainId:
        _chainChanged();
        break;
      case Web3EthereumRequestMethods.requestAccounts:
      case Web3EthereumRequestMethods.ethAccounts:
        _accountChanged();
        break;
      default:
    }
  }
}