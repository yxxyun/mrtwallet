import 'package:flutter/material.dart';
import 'package:mrt_wallet/future/wallet/global/pages/address_details.dart';
import 'package:mrt_wallet/future/wallet/security/pages/password_checker.dart';
import 'package:mrt_wallet/future/wallet/web3/controller/controller.dart';
import 'package:mrt_wallet/future/widgets/custom_widgets.dart';
import 'package:mrt_wallet/future/state_managment/state_managment.dart';
import 'package:mrt_wallet/wallet/models/access/wallet_access.dart';
import 'package:mrt_wallet/wallet/web3/core/request/web_request.dart';

import 'appbar_action.dart';
import 'client_info.dart';
import 'page_progress.dart';

typedef Web3PageChainBuilder<T extends Web3RequestControllerState>
    = List<Widget> Function(BuildContext context, T controller);

class Web3PageRequestControllerView<T extends Web3RequestControllerState>
    extends StatelessWidget {
  const Web3PageRequestControllerView({
    super.key,
    required this.request,
    required this.builder,
    required this.controller,
  });
  final Web3PageChainBuilder<T> builder;
  final T Function() controller;
  final Web3Request request;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        request.reject();
      },
      child: PasswordCheckerView(
        appbar: AppBar(
          title: Text(request.params.method.name),
          actions: [
            Web3PermissionAppbarActionView(request: request),
            WidgetConstant.width8,
          ],
        ),
        accsess: WalletAccsessType.unlock,
        subtitle: Web3ClientInfoView(
            permission: request.authenticated, info: request.info),
        onAccsess: (_, __, ___) {
          return MrtViewBuilder(
              controller: controller,
              builder: (controller) => Web3PageProgress(
                  key: controller.progressKey,
                  initialStatus: Web3ProgressStatus.progress,
                  // initialWidget: ProgressWithTextView(text: text),
                  child: (c) => CustomScrollView(slivers: [
                        SliverConstraintsBoxView(
                            padding: WidgetConstant.paddingHorizontal20,
                            sliver: SliverMainAxisGroup(slivers: [
                              SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (controller.permissionAccount !=
                                        null) ...[
                                      Text("account".tr,
                                          style: context.textTheme.titleLarge),
                                      Text("web3_request_account_desc".tr),
                                      WidgetConstant.height8,
                                      ContainerWithBorder(
                                          child: AddressDetailsView(
                                              address: controller
                                                  .permissionAccount!)),
                                      WidgetConstant.height20,
                                    ],
                                  ],
                                ),
                              ),
                              ...builder(context, controller)
                            ])),
                      ])),
              repositoryId: request.info.request.requestId);
        },
      ),
    );
  }
}