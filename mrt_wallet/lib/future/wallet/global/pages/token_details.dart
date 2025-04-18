import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/future/wallet/controller/controller.dart';
import 'package:mrt_wallet/future/wallet/global/global.dart';
import 'package:mrt_wallet/future/widgets/custom_widgets.dart';
import 'package:mrt_wallet/future/state_managment/extension/extension.dart';

import 'package:mrt_wallet/wallet/wallet.dart';

enum TokenAction { delete, transfer }

class TokenDetailsModalView<NETWORKADDRESS, TOKEN extends TokenCore,
        CHAINACCOUNT extends ChainAccount<NETWORKADDRESS, TOKEN, NFTCore>>
    extends StatelessWidget {
  const TokenDetailsModalView(
      {super.key,
      required this.token,
      required this.address,
      required this.transferPath,
      required this.account,
      this.transferArgruments});
  final TOKEN token;
  final CHAINACCOUNT address;
  final APPCHAINACCOUNT<CHAINACCOUNT> account;
  final String transferPath;
  final Object? transferArgruments;
  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>(StateConst.main);
    final addr = wallet.wallet.network.getAccountExplorer(token.issuer);
    return CustomScrollView(
      shrinkWrap: true,
      slivers: [
        SliverAppBar(
          title: Text("token_info".tr),
          leading: WidgetConstant.sizedBox,
          leadingWidth: 0,
          pinned: true,
          actions: [
            if (addr != null)
              LaunchBrowserIcon(url: addr, size: APPConst.double20),
            IconButton(
                onPressed: () {
                  context
                      .openSliverBottomSheet<bool>("update_token".tr,
                          bodyBuilder: (scrollController) =>
                              UpdateTokenDetailsView(
                                  token: token.token,
                                  accountToken: token,
                                  account: account,
                                  address: address,
                                  scrollController: scrollController),
                          centerContent: false)
                      .then((v) {
                    if (v == true) context.pop();
                  });
                },
                icon: const Icon(Icons.edit)),
            IconButton(
                onPressed: () {
                  context.openSliverDialog(
                      (ctx) => DialogTextView(
                          buttonWidget: AsyncDialogDoubleButtonView(
                            firstButtonPressed: () => wallet.wallet
                                .removeToken(
                                    token: token,
                                    address: address,
                                    account: account)
                                .then((value) {
                              if (value.hasError) return;
                              context.pop();
                            }),
                          ),
                          text: "remove_token_from_account".tr),
                      "remove_token".tr);
                },
                icon: Icon(Icons.delete, color: context.colors.error)),
            const CloseButton(),
            WidgetConstant.width8,
          ],
        ),
        SliverToBoxAdapter(
          child: ConstraintsBoxView(
            padding: WidgetConstant.padding20,
            child: _TokenDetailsView(
              token: token,
              address: address,
              wallet: wallet,
              transferPath: transferPath,
              transferArgruments: transferArgruments,
            ),
          ),
        ),
      ],
    );
  }
}

class _TokenDetailsView extends StatelessWidget {
  const _TokenDetailsView(
      {required this.token,
      required this.address,
      required this.wallet,
      required this.transferPath,
      this.transferArgruments});
  final TokenCore token;
  final ChainAccount address;
  final WalletProvider wallet;
  final String transferPath;
  final Object? transferArgruments;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child:
                    AddressDetailsView(address: address, showBalance: false)),
          ],
        ),
        WidgetConstant.divider,
        CircleTokenImageView(token.token, radius: 60),
        WidgetConstant.height8,
        Text(token.token.nameView, style: context.textTheme.labelLarge),
        WidgetConstant.height8,
        CoinPriceView(
            liveBalance: token.balance,
            token: token.token,
            style: context.textTheme.titleLarge),
        WidgetConstant.height20,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              onPressed: () {
                context.offTo(transferPath,
                    argruments: transferArgruments ?? token);
              },
              child: const Icon(Icons.upload),
            ),
            WidgetConstant.width8,
            FloatingActionButton(
              onPressed: () {
                context.openSliverDialog(
                    (ctx) => BarcodeView(
                        secure: false,
                        title: AddressDetailsView(
                            address: address, showBalance: false),
                        barcodeData: address.address.toAddress),
                    "account_qr_code".tr);
              },
              child: const Icon(Icons.download),
            )
          ],
        )
      ],
    );
  }
}
