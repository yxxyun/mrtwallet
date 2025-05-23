import 'package:mrt_wallet/app/error/exception.dart';
import 'package:mrt_wallet/wallet/wallet.dart';
import 'package:mrt_wallet/future/wallet/network/forms/core/core.dart';
import 'package:mrt_wallet/app/models/models/typedef.dart';
import 'package:mrt_wallet/wallet/web3/web3.dart';
import 'package:on_chain/on_chain.dart';

enum ETHTransactionMode { transfer, erc20Transfer, contract, callContract }

abstract class EthereumTransactionForm extends TransactionForm {
  BigInt get callValue;
  BigInt get tokenValue;
  @override
  String? validateError({IEthAddress? account});
  Map<String, dynamic> toEstimate(
      {required IEthAddress address,
      required WalletEthereumNetwork network,
      String? memo});
  ETHTransaction toTransaction(
      {required IEthAddress address,
      required WalletEthereumNetwork network,
      required EthereumFee fee,
      String? memo});
  ETHTransactionMode get mode;
  DynamicVoid? onStimateChanged;
}

abstract class EthereumWeb3Form<PARAMS extends Web3EthereumRequestParam>
    extends Web3Form<ETHAddress, EthereumChain, Web3EthereumChainAccount,
        Web3EthereumChain, PARAMS> {
  @override
  abstract final Web3EthereumRequest<dynamic, PARAMS> request;

  DynamicVoid? onStimateChanged;

  @override
  String get name => request.params.method.name;

  void confirmRequest({Object? response}) {
    onCompleteForm?.call(response);
  }

  ETHFORM cast<ETHFORM extends EthereumWeb3Form>() {
    if (this is! ETHFORM) {
      throw WalletException.invalidArgruments(["$ETHFORM", "$runtimeType"]);
    }
    return this as ETHFORM;
  }
}
