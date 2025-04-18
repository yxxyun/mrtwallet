import 'package:mrt_wallet/future/wallet/network/solana/transaction/controller/imp/memo_impl.dart';
import 'package:mrt_wallet/future/widgets/widgets/progress_bar/progress.dart';
import 'package:mrt_wallet/wallet/wallet.dart';
import 'package:mrt_wallet/future/wallet/network/forms/solana/solana.dart';
import 'package:mrt_wallet/future/wallet/network/solana/transaction/controller/imp/fee_impl.dart';
import 'package:mrt_wallet/future/wallet/network/solana/transaction/controller/imp/signer_impl.dart';
import 'package:mrt_wallet/future/wallet/network/solana/transaction/controller/imp/transaction_impl.dart';

class SolanaTransactionStateController extends SolanaTransactionImpl
    with SolanaTransactionFeeImpl, SolanaSignerImpl, SolanaMemoImpl {
  SolanaTransactionStateController(
      {required super.walletProvider,
      required super.account,
      required super.network,
      required super.address,
      required super.apiProvider,
      required super.validator});
  IntegerBalance? _remindTokenAmount;
  late final IntegerBalance _remindAmount =
      IntegerBalance.zero(network.coinParam.decimal);
  late (BalanceCore, Token) remindAmount;
  String? _error;
  String? get error => _error;
  bool _trReady = false;
  bool get transactionIsReady => _trReady;

  Future<void> _init() async {
    await walletProvider.wallet
        .updateAccountBalance(account, addresses: [address]);
    if (validator.validator.mode == SolanaTransactionType.spl) {
      final tokenTransferFiled = validator.validator as SolanaTransferForm;
      _remindTokenAmount =
          IntegerBalance.zero(tokenTransferFiled.token.decimal!);
    }
    _trReady = _checkTransaction();
    progressKey.backToIdle();
  }

  bool _checkTransaction() {
    _error = validator.validator.validateError();
    _remindAmount
        .updateBalance(account.address.address.currencyBalance - fee.balance);
    if (validator.validator.mode != SolanaTransactionType.spl) {
      final transactionValue = validator.validator.transferValue + fee.balance;
      _remindAmount.updateBalance(
          account.address.address.currencyBalance - transactionValue);
      remindAmount = (_remindAmount, network.coinParam.token);
    } else {
      final tokenTransferFiled = validator.validator as SolanaTransferForm;
      final remindTokenAmounts =
          tokenTransferFiled.splToken!.balance.value.balance -
              (tokenTransferFiled.transferValue);
      _remindTokenAmount!.updateBalance(remindTokenAmounts);
      if (_remindAmount.isNegative ||
          validator.validator.mode != SolanaTransactionType.spl) {
        remindAmount = (_remindAmount, network.coinParam.token);
      } else {
        remindAmount = (_remindTokenAmount!, tokenTransferFiled.token);
      }
    }

    return _error == null &&
        !_remindAmount.isNegative &&
        !(_remindTokenAmount?.isNegative ?? false);
  }

  @override
  void checkTransaction() {
    _trReady = _checkTransaction();
    notify();
  }

  void sendTransaction() async {
    checkTransaction();
    if (!_trReady) {
      return;
    }
    await buildAndSignTransaction();
  }

  @override
  Future<void> onTapMemo(OnSetMemo onTapMemo) async {
    final m = memoStr;
    await super.onTapMemo(onTapMemo);
    if (m != memoStr) {
      calculateFees();
    }
  }

  void onChange() {
    checkTransaction();
    if (_trReady || (error == null && feeError != null)) {
      calculateFees();
    }
  }

  @override
  void ready() {
    validator.addListener(onChange);
    validator.validator.initForm(account: account, address: address);
    super.ready();
  }

  @override
  void init() {
    super.init();
    _init();
  }

  @override
  void close() {
    validator.removeListener(onChange);
    validator.validator.close();

    super.close();
  }
}
