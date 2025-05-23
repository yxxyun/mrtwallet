import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/future/router/page_router.dart';
import 'package:mrt_wallet/future/state_managment/state_managment.dart';
import 'package:mrt_wallet/future/wallet/global/pages/wallet_signing_password.dart';
import 'package:mrt_wallet/future/widgets/custom_widgets.dart';
import 'package:mrt_wallet/wallet/api/provider/core/provider.dart';
import 'package:mrt_wallet/wallet/models/models.dart';
import 'package:mrt_wallet/wallet/provider/wallet_provider.dart';
import 'package:mrt_wallet/wallet/web3/core/request/web_request.dart';
import 'package:mrt_wallet/crypto/derivation/core/derivation.dart';
import 'package:mrt_wallet/wallet/web3/networks/global/params/core/core.dart';

abstract class UIWallet extends WalletCore {
  UIWallet({
    required this.navigatorKey,
    required this.storageVersion,
  });
  final GlobalKey<NavigatorState> navigatorKey;
  @override
  final int storageVersion;

  DynamicVoid? onNotify;
  bool get isolate => true;

  @override
  void onChange() {
    onNotify?.call();
  }

  void close() {
    onNotify = null;
  }

  Future<void> changeProvider<PROVIDER extends APIProvider>(
      {required ProviderIdentifier? provider,
      required APPCHAINNETWORKPROVIDER account}) async {
    if (provider == null) return;
    await changeCurrentNetworkProvider(account: account, provider: provider);
    _cancelabe.cancel();
  }

  Future<String> _getPassword(
      {required Set<AddressDerivationIndex> keys,
      required Set<ChainAccount> addresses}) async {
    final pw = await navigatorKey.currentContext?.openSliverBottomSheet<String>(
      "sign_transaction".tr,
      bodyBuilder: (controller) => WalletSigningPassword(
        addresses: addresses,
        keys: keys,
        controller: controller,
        onPasswordForm: (password) async {
          final result = await login(password);
          return result.hasResult;
        },
      ),
    );
    if (pw == null) {
      throw WalletExceptionConst.rejectSigning;
    }
    return pw;
  }

  Future<MethodResult<T>> signTransaction<T>(
      {required WalletSigningRequest<T> request, Duration? timeout}) async {
    return await MethodUtils.call(() async {
      late final Set<ChainAccount> addresses = request.addresses.toSet();
      late final Set<AddressDerivationIndex> keys =
          addresses.map((e) => e.signerKeyIndexes()).expand((e) => e).toSet();
      if (wallet.protectWallet) {
        final password = await _getPassword(addresses: addresses, keys: keys);
        final r = (await super.signRequest(
            request: request, password: password, timeout: timeout));
        return r.result;
      }
      return (await super.signRequest(request: request, timeout: timeout))
          .result;
    });
  }

  final GlobalKey<RefreshIndicatorState> refreshState =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<PageProgressBaseState<StatefulWidget>> pageStatusHandler =
      GlobalKey();
  final Cancelable _cancelabe = Cancelable();
  Future<void> updateBalance() async {
    if (!isOpen) return;
    _cancelabe.dispose();
    refreshState.currentState?.show();
    await MethodUtils.call(() async {
      return await updateCurrentAccountBalance();
    }, cancelable: _cancelabe, timeout: const Duration(seconds: 10));
  }

  @override
  void onChangeStatus(WalletPageStatus status, {String? message}) {
    switch (status) {
      case WalletPageStatus.refesh:
        navigatorKey.currentContext?.popToHome();
        if (pageStatusHandler.inProgress) {
          pageStatusHandler.success();
        }
        break;
      case WalletPageStatus.progress:
        if (message != null) {
          pageStatusHandler.progressText(message.tr);
        } else {
          pageStatusHandler.progress();
        }
        _cancelabe.cancel();
        break;
      case WalletPageStatus.error:
        pageStatusHandler.error();
        break;
      default:
        if (pageStatusHandler.inProgress) {
          pageStatusHandler.success();
        }

        break;
    }
  }

  @override
  bool onWeb3Request(Web3Request request) {
    String? page;
    if (request is Web3NetworkRequest) {
      page = PageRouter.web3Page(request.chain.network);
    } else if (request is Web3GlobalRequest) {
      page = PageRouter.web3Global;
    }
    if (page == null) return false;
    return navigatorKey.currentContext?.toSync(page, argruments: request) ??
        false;
  }

  Future<void> init(DynamicVoid onNotification) async {
    onNotify = onNotification;
    await initWallet();
  }
}
