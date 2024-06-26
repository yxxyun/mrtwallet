import 'dart:async';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/string/string.dart';
import 'package:mrt_wallet/models/api/api_provider_tracker.dart';
import 'package:mrt_wallet/provider/api/api_provider.dart';
import 'package:mrt_wallet/provider/api/models/request_completer.dart';

class ElectrumWebsocketService extends WebSocketProvider
    implements ElectrumService {
  ElectrumWebsocketService({
    required super.url,
    required ApiProviderTracker<ElectrumApiProviderService> super.provider,
    this.defaultRequestTimeOut = const Duration(seconds: 30),
  });
  final Duration defaultRequestTimeOut;

  @override
  Future<Map<String, dynamic>> call(ElectrumRequestDetails params,
      [Duration? timeout]) async {
    final SocketRequestCompeleter message =
        SocketRequestCompeleter(StringUtils.fromJson(params.params), params.id);
    return await addMessage(message, timeout ?? defaultRequestTimeOut);
  }

  @override
  ApiProviderTracker<ElectrumApiProviderService> get provider =>
      super.provider as ApiProviderTracker<ElectrumApiProviderService>;
}
