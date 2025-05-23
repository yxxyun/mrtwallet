import 'package:flutter/material.dart';
import 'package:mrt_wallet/future/router/page_router.dart';
import 'package:mrt_wallet/future/state_managment/state_managment.dart';
import 'package:mrt_wallet/future/widgets/custom_widgets.dart';
import 'package:mrt_wallet/crypto/keys/import/import_keys.dart';

class ImportCustomKeyToWalletView extends StatefulWidget {
  const ImportCustomKeyToWalletView({required this.keypair, super.key});
  final ImportCustomKeys keypair;

  @override
  State<ImportCustomKeyToWalletView> createState() =>
      ImportCustomKeyToWalletViewState();
}

class ImportCustomKeyToWalletViewState
    extends State<ImportCustomKeyToWalletView> with SafeState {
  bool showKeys = false;
  late final String keyType = widget.keypair.coin.conf.type.name.camelCase;

  void onChangeShowKeys() {
    showKeys = !showKeys;
    updateState();
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitleSubtitle(
              title: "import_private_key".tr,
              body: LargeTextView([
                "import_private_key_desc".tr,
                "export_private_key_desc".tr,
              ])),
          Text("private_key".tr, style: context.textTheme.titleMedium),
          Text(keyType),
          WidgetConstant.height8,
          Stack(
            children: [
              Container(
                foregroundDecoration: showKeys
                    ? null
                    : BoxDecoration(
                        color: context.colors.secondary,
                        borderRadius: WidgetConstant.border8,
                      ),
                child: ContainerWithBorder(
                    child: CopyTextWithBarcode(
                  secureBarcode: true,
                  color: context.onPrimaryContainer,
                  barcodeWidget: ContainerWithBorder(
                      child: CopyTextIcon(
                          isSensitive: true,
                          color: context.onPrimaryContainer,
                          dataToCopy: widget.keypair.privateKey,
                          widget: ObscureTextView(widget.keypair.privateKey,
                              maxLine: 3,
                              style: context.onPrimaryTextTheme.bodyMedium))),
                  underBarcodeWidget: ErrorTextContainer(
                      margin: WidgetConstant.paddingVertical10,
                      error: "image_store_alert_keys".tr),
                  dataToCopy: widget.keypair.privateKey,
                  barcodeTitle: "private_key".tr,
                  widget: Text(widget.keypair.privateKey,
                      style: context.onPrimaryTextTheme.bodyMedium),
                )),
              ),
              Positioned.fill(
                child: APPAnimatedSwitcher(enable: showKeys, widgets: {
                  true: (context) => WidgetConstant.sizedBox,
                  false: (context) => FilledButton.icon(
                      onPressed: onChangeShowKeys,
                      icon: const Icon(Icons.remove_red_eye),
                      label: Text("show_private_key".tr))
                }),
              )
            ],
          ),
          WidgetConstant.height20,
          Text("public_key".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          ContainerWithBorder(
              child: CopyTextWithBarcode(
            secureBarcode: false,
            color: context.onPrimaryContainer,
            barcodeWidget: ContainerWithBorder(
                child: CopyTextIcon(
                    isSensitive: false,
                    dataToCopy: widget.keypair.publicKey,
                    color: context.onPrimaryContainer,
                    widget: Text(
                      widget.keypair.publicKey,
                      style: context.onPrimaryTextTheme.bodyMedium,
                    ))),
            dataToCopy: widget.keypair.publicKey,
            barcodeTitle: "public_key".tr,
            widget: SelectableText(widget.keypair.publicKey,
                style: context.onPrimaryTextTheme.bodyMedium),
          )),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                padding: WidgetConstant.paddingVertical40,
                onPressed: () {
                  context.to(PageRouter.importAccount,
                      argruments: widget.keypair);
                },
                child: Text("import_to_wallet".tr),
              ),
            ],
          )
        ],
      ),
    );
  }
}
