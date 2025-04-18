import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/future/state_managment/state_managment.dart';
import 'package:mrt_wallet/future/wallet/web3/web3.dart';
import 'package:mrt_wallet/wallet/models/models.dart';
import 'package:mrt_wallet/wallet/web3/web3.dart';

abstract class Web3StateContoller<WEB3REQUEST extends Web3Request>
    extends StateController {
  WEB3REQUEST get web3Request;

  final GlobalKey<Web3PageProgressState> progressKey =
      GlobalKey<Web3PageProgressState>();
  StreamSubscription<dynamic>? onRequestError;
  Future<void> initWeb3();
  bool get web3Closed => web3Request.info.isClosed;

  void _onChangeStatus(Web3RequestCompleterErrorType status) {
    switch (status) {
      case Web3RequestCompleterErrorType.success:
        progressKey.successRequest();
        break;
      case Web3RequestCompleterErrorType.closed:
        progressKey.closedRequest();
        break;
      default:
    }
  }

  @override
  void close() {
    onRequestError?.cancel();
    onRequestError = null;
    super.close();
  }
}

mixin Web3GlobalRequestControllerState<WEB3REQUEST extends Web3GlobalRequest>
    on Web3StateContoller<WEB3REQUEST> {
  Future<void> _readyWeb3() async {
    notify();
    final isReady = await MethodUtils.after(() async => _init());
    if (isReady) {
      await initWeb3();
    }
  }

  Future<bool> _init() async {
    if (web3Closed) {
      progressKey.closedRequest();
    } else {
      onRequestError =
          web3Request.info.stream.asBroadcastStream().listen(_onChangeStatus);
      return true;
    }

    return false;
  }

  @override
  void ready() {
    super.ready();
    _readyWeb3();
  }
}

mixin Web3NetworkRequestControllerState<WEB3REQUEST extends WEB3CHAINREQUEST>
    on Web3StateContoller<WEB3REQUEST> {
  bool get clientRequired => true;
  NETWORKCHAINACCOUNT? permissionAccount;
  @override
  WEB3REQUEST get web3Request;

  Future<bool> _init() async {
    if (web3Closed) {
      progressKey.closedRequest();
    } else {
      onRequestError =
          web3Request.info.stream.asBroadcastStream().listen(_onChangeStatus);
      if (clientRequired) {
        progressKey.process(text: 'node_connectiong_please_wait'.tr);
        final init = await web3Request.chain.client.init();
        if (!init) {
          progressKey.errorResponse(
              message: "web3_client_connection_failed".tr);
          web3Request.error(Web3RequestExceptionConst.disconnectedChain);
          return false;
        }
      }
      return true;
    }

    return false;
  }

  Future<void> _readyWeb3() async {
    permissionAccount = web3Request.accountPermission();
    notify();
    final isReady = await MethodUtils.after(() async => _init());
    if (isReady) {
      await initWeb3();
    }
  }

  @override
  void ready() {
    super.ready();
    _readyWeb3();
  }
}
