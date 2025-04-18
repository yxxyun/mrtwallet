import 'package:mrt_wallet/wallet/web3/networks/solana/methods/methods.dart';
import 'package:mrt_wallet/wallet/web3/networks/solana/params/models/sign_message.dart';
import 'package:mrt_wallet/wallet/web3/networks/solana/params/models/transaction.dart';
import 'package:mrt_wallet/wallet/web3/networks/solana/permission/models/account.dart';
import 'package:mrt_wallet/wallet/web3/networks/solana/permission/models/permission.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:mrt_wallet/app/serialization/cbor/cbor.dart';
import 'package:mrt_wallet/wallet/models/chain/account.dart';
import 'package:mrt_wallet/wallet/web3/constant/constant/exception.dart';
import 'package:mrt_wallet/wallet/web3/core/core.dart';
import 'package:on_chain/solana/solana.dart';

abstract class Web3SolanaRequestParam<RESPONSE> extends Web3RequestParams<
    RESPONSE,
    SolAddress,
    SolanaChain,
    Web3SolanaChainAccount,
    Web3SolanaChain> {
  @override
  abstract final Web3SolanaRequestMethods method;
  @override
  Web3SolanaChainAccount? get account => null;

  Web3SolanaRequestParam();

  @override
  Web3SolanaRequest<RESPONSE, Web3SolanaRequestParam<RESPONSE>> toRequest(
      {required Web3RequestApplicationInformation request,
      required Web3APPAuthentication authenticated,
      required List<APPCHAIN> chains}) {
    final SolanaChain chain = super.findRequestChain(
        request: request, authenticated: authenticated, chains: chains);
    return Web3SolanaRequest<RESPONSE, Web3SolanaRequestParam<RESPONSE>>(
      params: this,
      authenticated: authenticated,
      chain: chain,
      info: request,
    );
  }

  factory Web3SolanaRequestParam.deserialize(
      {List<int>? bytes, CborObject? object, String? hex}) {
    final CborListValue values = CborSerializable.cborTagValue(
        cborBytes: bytes,
        object: object,
        hex: hex,
        tags: Web3MessageTypes.walletRequest.tag);
    final method = Web3NetworkRequestMethods.fromTag(values.elementAt(0));
    final Web3SolanaRequestParam param;
    switch (method) {
      case Web3SolanaRequestMethods.signTransaction:
      case Web3SolanaRequestMethods.signAndSendAllTransactions:
      case Web3SolanaRequestMethods.sendTransaction:
        param = Web3SolanaSendTransaction.deserialize(
            bytes: bytes, object: object, hex: hex);
      case Web3SolanaRequestMethods.signIn:
      case Web3SolanaRequestMethods.signMessage:
        param = Web3SolanaSignMessage.deserialize(
            bytes: bytes, object: object, hex: hex);
      default:
        throw Web3RequestExceptionConst.internalError;
    }
    if (param is! Web3SolanaRequestParam<RESPONSE>) {
      throw Web3RequestExceptionConst.internalError;
    }
    return param;
  }
}

class Web3SolanaRequest<RESPONSE,
        PARAMS extends Web3SolanaRequestParam<RESPONSE>>
    extends Web3NetworkRequest<RESPONSE, SolAddress, SolanaChain,
        Web3SolanaChainAccount, Web3SolanaChain, PARAMS> {
  Web3SolanaRequest(
      {required super.params,
      required super.info,
      required super.authenticated,
      required super.chain});

  Web3SolanaRequest<R, P> cast<R, P extends Web3SolanaRequestParam<R>>() {
    return this as Web3SolanaRequest<R, P>;
  }
}
