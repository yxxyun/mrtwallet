import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/core.dart' show Live, StateConst;
import 'package:mrt_wallet/future/wallet/controller/controller.dart';
import 'package:mrt_wallet/future/state_managment/state_managment.dart';

import 'package:mrt_wallet/app/models/models/currencies.dart';
import 'package:mrt_wallet/wallet/wallet.dart'
    show BalanceCore, ChainAccount, IntegerBalance, Token;
import 'assets_image.dart';
import 'tooltip/widgets/tooltip.dart';
import 'widget_constant.dart';

class PriceTooltipWidget extends StatelessWidget {
  const PriceTooltipWidget(
      {super.key,
      required this.price,
      required this.symbol,
      required this.currencyName});
  final String price;
  final String symbol;
  final String currencyName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
        constraints: const BoxConstraints(maxWidth: 300),
        child: RichText(
            text: TextSpan(
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: theme.colorScheme.onTertiaryContainer),
                children: [
              TextSpan(text: price.to3Digits),
              const TextSpan(text: " "),
              TextSpan(
                  text: symbol,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onTertiaryContainer)),
              TextSpan(
                  text: " ($currencyName) ",
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onTertiaryContainer)),
            ])));
  }
}

class CoinPriceView extends StatelessWidget {
  const CoinPriceView({
    super.key,
    this.account,
    required this.token,
    this.balance,
    this.liveBalance,
    this.style,
    this.symbolColor,
    this.disableTooltip = false,
    this.showTokenImage = false,
    this.enableMarketPrice = true,
  }) : assert(
            (account != null) ||
                (account == null && (balance != null || liveBalance != null)),
            "use account or balance with coinName");

  final ChainAccount? account;
  final Token token;
  final BalanceCore? balance;
  final Live<BalanceCore>? liveBalance;
  final TextStyle? style;
  final Color? symbolColor;
  final bool disableTooltip;
  final bool showTokenImage;
  final bool enableMarketPrice;
  @override
  Widget build(BuildContext context) {
    final Token coin = token;
    final wallet = context.watch<WalletProvider>(StateConst.main);

    return LiveWidget(() {
      final price = balance?.price ??
          liveBalance?.value.price ??
          account!.address.viewBalance;
      final ta = wallet.amount(price, token);
      return ToolTipView(
        tooltipWidget: disableTooltip
            ? null
            : (c) => PriceTooltipWidget(
                currencyName: coin.name, price: price, symbol: coin.symbol),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showTokenImage) ...[
                    CircleTokenImageView(token, radius: 10),
                    WidgetConstant.width8,
                  ],
                  Flexible(
                    child: RichText(
                        textDirection: TextDirection.ltr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                            style: style ?? context.textTheme.labelLarge,
                            children: [
                              TextSpan(text: price.to3Digits),
                              const TextSpan(text: " "),
                            ])),
                  ),
                  Text(
                    coin.symbolView,
                    style: context.textTheme.labelSmall?.copyWith(
                        color: symbolColor ?? context.colors.primary),
                  ),
                ],
              ),
              if (enableMarketPrice)
                _CoinStringPriceView(
                  balance: ta,
                  token: wallet.currencyToken,
                  symbolColor: symbolColor,
                  disableTooltip: false,
                  style: null,
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _CoinStringPriceView extends StatelessWidget {
  const _CoinStringPriceView({
    required this.token,
    required this.balance,
    this.symbolColor,
    this.style,
    this.disableTooltip = false,
  });

  final Currency token;
  final IntegerBalance? balance;
  final TextStyle? style;
  final Color? symbolColor;
  final bool disableTooltip;
  @override
  Widget build(BuildContext context) {
    if (balance?.isZero ?? true) return WidgetConstant.sizedBox;
    return ToolTipView(
      tooltipWidget: disableTooltip
          ? null
          : (c) => PriceTooltipWidget(
              currencyName: token.name,
              price: balance!.price,
              symbol: token.name),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: RichText(
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                          style: style ??
                              context.textTheme.labelSmall
                                  ?.copyWith(color: symbolColor),
                          children: [
                            TextSpan(text: balance!.viewPrice),
                            const TextSpan(text: " "),
                          ])),
                ),
                Text(
                  token.name,
                  style: context.textTheme.labelSmall
                      ?.copyWith(color: symbolColor ?? context.colors.primary),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
