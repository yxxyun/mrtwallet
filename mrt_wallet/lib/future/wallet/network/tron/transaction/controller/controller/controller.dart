import 'dart:async';

import 'package:mrt_wallet/future/wallet/network/tron/transaction/controller/impl/fee_impl.dart';
import 'package:mrt_wallet/future/wallet/network/tron/transaction/controller/impl/memo_impl.dart';
import 'package:mrt_wallet/future/wallet/network/tron/transaction/controller/impl/network_impl.dart';
import 'package:mrt_wallet/future/wallet/network/tron/transaction/controller/impl/signer_impl.dart';
import 'package:mrt_wallet/future/wallet/network/tron/transaction/controller/impl/transaction.dart';
import 'package:mrt_wallet/wallet/wallet.dart';
import 'package:mrt_wallet/future/wallet/network/forms/forms.dart';
import 'package:on_chain/tron/src/models/contract/base_contract/transaction_type.dart';

class TronTransactionStateController extends TronTransactionImpl
    with
        TronMemoImpl,
        TronNetworkConditionImpl,
        TronTransactionFeeIMpl,
        TronSignerImpl {
  TronTransactionStateController(
      {required super.walletProvider,
      required super.account,
      required this.validator});
  final LiveTransactionForm<TronTransactionForm> validator;
  String? _error;

  String? get error => _error;
  bool _trIsReady = false;
  bool get trIsReady => _trIsReady;
  bool get showTxInfo => validator.validator.showTxInfo;

  IntegerBalance? _remindTokenAmount;
  late final IntegerBalance _remindAmount =
      IntegerBalance.zero(network.coinParam.decimal);
  late (BalanceCore, Token) remindAmount;

  bool _checkTransaction() {
    _error = validator.validator.validateError();
    final transactionValue = validator.validator.callValue;
    _remindAmount.updateBalance(account.address.address.currencyBalance -
        (transactionValue + (totalBurn?.balance ?? BigInt.zero)));
    if (validator.validator.type !=
        TransactionContractType.triggerSmartContract) {
      remindAmount = (_remindAmount, network.coinParam.token);
    } else {
      final tokenTransferFiled = validator.validator as TronTransferForm;
      final remindTokenAmounts =
          tokenTransferFiled.transferToken!.balance.value.balance -
              tokenTransferFiled.tokenValue;
      _remindTokenAmount!.updateBalance(remindTokenAmounts);
      if (_remindAmount.isNegative) {
        remindAmount = (_remindAmount, network.coinParam.token);
      } else {
        remindAmount = (_remindTokenAmount!, tokenTransferFiled.token);
      }
    }
    return _error == null &&
        !_remindAmount.isNegative &&
        !(_remindTokenAmount?.isNegative ?? false) &&
        consumedFee != null;
  }

  @override
  Future<void> onTapMemo(OnAddTronMemo onAddMemo) async {
    final currentMemo = memo;
    await super.onTapMemo(onAddMemo);
    _checkTransaction();
    if (currentMemo != memo && _error == null) {
      calculateFee();
    }
  }

  void _init() {
    if (validator.validator.type ==
        TransactionContractType.triggerSmartContract) {
      final tokenTransferFiled = validator.validator as TronTransferForm;
      _remindTokenAmount =
          IntegerBalance.zero(tokenTransferFiled.token.decimal!);
    }
    _trIsReady = _checkTransaction();
  }

  void sedTransaction() async {
    await signAndSendTransaction(
        validator.validator.toContract(owner: address));
  }

  void _onFormListener() {
    _trIsReady = _checkTransaction();
    notify();
  }

  void _onEstimateNeeded() {
    calculateFee();
  }

  @override
  void ready() {
    super.ready();
    initNetworkCondition();
  }

  @override
  Future<bool> initNetworkCondition() async {
    final isOK = await super.initNetworkCondition();
    _init();
    _error = validator.validator.validateError();
    if (_error == null) {
      calculateFee();
    }
    notify();
    return isOK;
  }

  @override
  TransactionContractType get type => validator.validator.type;

  @override
  TronTransactionForm get field => validator.validator;

  @override
  void onFeeChanged() {
    _trIsReady = _checkTransaction();
    notify();
  }

  @override
  void init() {
    super.init();
    validator.addListener(_onFormListener);
    validator.validator.onStimateChanged = _onEstimateNeeded;
  }

  @override
  void close() {
    validator.removeListener(_onFormListener);
    validator.validator.close();
    super.close();
  }
}
