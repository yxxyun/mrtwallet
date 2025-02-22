import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/core.dart';
// import 'package:mrt_wallet/future/future.dart';
import 'package:mrt_wallet/future/wallet/account/pages/account_controller.dart';
import 'package:mrt_wallet/future/wallet/controller/controller.dart';
import 'package:mrt_wallet/future/wallet/global/pages/token_details_view.dart';
import 'package:mrt_wallet/future/widgets/custom_widgets.dart';
import 'package:mrt_wallet/wallet/wallet.dart';
import 'package:mrt_wallet/future/state_managment/state_managment.dart';
import 'package:stellar_dart/stellar_dart.dart';

class MonitorStellarTokenView extends StatelessWidget {
  const MonitorStellarTokenView({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<StellarChain>(
      title: "add_token".tr,
      childBulder: (wallet, account, switchRippleAccount) {
        return _MonitorStellarTokenView(chain: account, wallet: wallet);
      },
    );
  }
}

class _MonitorStellarTokenView extends StatefulWidget {
  const _MonitorStellarTokenView({required this.chain, required this.wallet});
  final StellarChain chain;
  final WalletProvider wallet;
  // final RippleClient provider;

  @override
  State<_MonitorStellarTokenView> createState() =>
      __MonitorStellarTokenViewState();
}

class __MonitorStellarTokenViewState extends State<_MonitorStellarTokenView>
    with SafeState {
  late final address = widget.chain.address;
  StellarClient get client => widget.chain.client;
  List<StellarIssueToken> addressTokens = [];
  final GlobalKey<PageProgressState> progressKey = GlobalKey<PageProgressState>(
      debugLabel: "__MonitorStellarTokenViewState");
  final Set<StellarIssueToken> tokens = {};
  void fetchingTokens() async {
    if (progressKey.isSuccess || progressKey.inProgress) return;
    final result = await MethodUtils.call(() async {
      final account =
          await client.getAccountFromIStellarAddress(address, widget.chain);
      if (account == null) return <StellarAssetBalanceResponse>[];
      return account.balances.whereType<StellarAssetBalanceResponse>().toList();
    });

    if (result.hasError) {
      progressKey.errorText(result.error!.tr, backToIdle: false);
    } else {
      final toRippleIssue = result.result.map((e) {
        return addressTokens.firstWhere(
            (i) =>
                i.assetCode == e.assetCode &&
                i.issuer == e.assetIssuer &&
                i.assetType == e.assetType.assetType,
            orElse: () => e.toIssueToken());
      }).toList();
      tokens.addAll(toRippleIssue);
      progressKey.success();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    addressTokens = address.tokens;
    fetchingTokens();
  }

  @override
  void dispose() {
    for (final i in tokens) {
      if (!addressTokens.contains(i)) i.balance.dispose();
    }
    super.dispose();
  }

  Future<void> add(StellarIssueToken token) async {
    final result = await widget.wallet.wallet
        .addNewToken(token: token, address: address, account: widget.chain);
    if (result.hasError) throw result.error!;
    return result.result;
  }

  Future<void> removeToken(StellarIssueToken token) async {
    final result = await widget.wallet.wallet.removeToken(
      token: token,
      address: address,
      account: widget.chain,
    );
    if (result.hasError) throw result.error!;
    return result.result;
  }

  Future<void> onTap(StellarIssueToken token, bool exist) async {
    try {
      if (exist) {
        await removeToken(token);
      } else {
        await add(token);
      }
    } finally {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageProgress(
      key: progressKey,
      initialStatus: PageProgressStatus.progress,
      backToIdle: APPConst.oneSecoundDuration,
      initialWidget:
          ProgressWithTextView(text: "fetching_account_token_please_wait".tr),
      child: (c) {
        return CustomScrollView(
          slivers: [
            EmptyItemSliverWidgetView(
              isEmpty: tokens.isEmpty,
              itemBuilder: () => SliverConstraintsBoxView(
                padding: WidgetConstant.padding20,
                sliver: SliverList.separated(
                  separatorBuilder: (context, index) => WidgetConstant.divider,
                  itemBuilder: (context, index) {
                    final token = tokens.elementAt(index);
                    final bool exist = address.tokens.contains(token);
                    return TokenDetailsView(
                      token: token,
                      onSelect: () {
                        context.openSliverDialog(
                            (ctx) => DialogTextView(
                                buttonWidget: AsyncDialogDoubleButtonView(
                                  firstButtonPressed: () => onTap(token, exist),
                                ),
                                text: exist
                                    ? "remove_token_from_account".tr
                                    : "add_token_to_your_account".tr),
                            exist ? "remove_token".tr : "add_token".tr);
                      },
                      onSelectWidget: APPCheckBox(
                        ignoring: true,
                        value: exist,
                        onChanged: (e) {},
                      ),
                    );
                  },
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  itemCount: tokens.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
