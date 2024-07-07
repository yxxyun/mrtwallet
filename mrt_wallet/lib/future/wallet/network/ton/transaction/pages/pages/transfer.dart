import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/wallet/wallet.dart';
import 'package:mrt_wallet/future/wallet/network/forms/forms.dart';
import 'transaction.dart';

class TonTransferTransactionView extends StatelessWidget {
  const TonTransferTransactionView({super.key});

  @override
  Widget build(BuildContext context) {
    final ChainHandler chain = context.getArgruments();
    return TonTransactionFieldsView(
        field: LiveTransactionForm(
            validator: TonTransferForm(network: chain.network.toNetwork())));
  }
}