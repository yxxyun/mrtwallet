part of 'handler.dart';

@JS("#PINGREFRENCE")
external set _pingRefrence(JSFunction? f);
@JS("#PINGREFRENCE")
external JSFunction get pringRefrence;

@JS("#OnBackgroundListener")
external set _OnBackgroundListener(JSFunction? f);
@JS("#OnBackgroundListener")
external JSFunction get _OnBackgroundListener;

class _ExtentionWalletHandlerConst {
  static final openEvent = WalletEvent(
      clientId: "content_script",
      data: const [],
      requestId: "0",
      type: WalletEventTypes.openExtention);
  static final ping = WalletEvent(
      clientId: "content_script",
      data: const [],
      requestId: "0",
      type: WalletEventTypes.ping);
}

class ExtentionWalletHandler extends WalletHandler {
  final _portLock = SynchronizedLock();
  @override
  late ChainsHandler _chain;
  @override
  final String clientId;
  RuntimePort? _port;

  bool onMessage(
      JSWalletEvent message, MessageSender sender, JSFunction sendResponse) {
    _onResponse(message);
    return true;
  }

  ExtentionWalletHandler._(
      {required ChaCha20Poly1305 crypto,
      required ChainsHandler chain,
      required this.clientId})
      : _chain = chain,
        super._(crypto);

  static Future<ExtentionWalletHandler> initialize(
      WalletEvent activationEvent) async {
    final chacha = ChaCha20Poly1305(
        QuickCrypto.sha256Hash(StringUtils.encode(activationEvent.clientId)));
    final data = List<int>.from(activationEvent.data);
    final encryptedMessage = Web3EncryptedMessage.deserialize(bytes: data);
    final decode =
        chacha.decrypt(encryptedMessage.nonce, encryptedMessage.message);
    final message = Web3ChainMessage.deserialize(bytes: decode);
    final handler = ExtentionWalletHandler._(
        crypto: ChaCha20Poly1305(message.authenticated.token),
        chain: ChainsHandler.deserialize(bytes: message.message),
        clientId: activationEvent.clientId);
    handler._listenOnClients();
    extention.runtime.onMessage.addListener(handler.onMessage.toJS);
    handler._updateAuthenticated(message.authenticated, initChain: true);
    return handler;
  }

  void _onExtentionPortDiscounect(RuntimePort port) {
    _portLock.synchronized(() {
      _port = null;
    });
  }

  void _onExtentionPortMessage(JSWalletEvent event, RuntimePort port) {}
  static Future<RuntimePort?> _pingPort(RuntimePort? newPort) async {
    if (newPort == null) return null;
    final completer = Completer<RuntimePort>();

    try {
      void onEmitMessage(JSWalletEvent? message, RuntimePort port) {
        final event = message?.toEvent();
        if (event?.type != WalletEventTypes.ping) return;
        completer.complete(port);
      }

      _pingRefrence = onEmitMessage.toJS;
      newPort.postMessage(_ExtentionWalletHandlerConst.ping.toJsEvent());
      newPort.onMessage.addListener(pringRefrence);
      final result = await completer.future;
      return result;
    } finally {
      newPort.onMessage.removeListener(pringRefrence);
      _pingRefrence = null;
    }
  }

  Future<RuntimePort> _openPort() async {
    return _portLock.synchronized(() async {
      RuntimePort? port = await _pingPort(_port);
      if (port != null) return port;
      _port?.disconnect();
      _port = null;
      final newPort = await _pingPort(extention.runtime
          .connect(extention.runtime.id, ConnectConnectionInf(name: clientId)));
      if (newPort == null) {
        throw UnimplementedError();
      }
      _port = newPort;
      _port!.onDisconnect.addListener(_onExtentionPortDiscounect.toJS);
      _port!.onMessage.addListener(_onExtentionPortMessage.toJS);
      return _port!;
    });
  }

  static Future<WalletEvent> sendBackgroudMessage(WalletEvent message) async {
    bool hasListener = false;
    try {
      final Completer<WalletEvent> completer = Completer();
      bool onMessage(JSWalletEvent message, MessageSender sender,
          JSFunction sendResponse) {
        final event = message.toEvent();
        if (event?.type != WalletEventTypes.ping) {
          return false;
        }
        final result = extention.runtime.sendMessage_(message: event!);
        result.then((e) {
          completer.complete(e);
        });
        result.catchError((e) {
          completer.completeError(e);
          return null;
        });
        return true;
      }

      final result = extention.runtime.sendMessage_(message: message);
      result.then((e) {
        completer.complete(e);
      });
      result.catchError((e) {
        _OnBackgroundListener = onMessage.toJS;
        extention.runtime.onMessage.addListener(_OnBackgroundListener);
        hasListener = true;
        return null;
      });
      return await completer.future;
    } finally {
      if (hasListener) {
        extention.runtime.onMessage.removeListener(_OnBackgroundListener);
      }
    }
  }

  Future<void> _sendMessageToExtention(
      {required WalletEvent message, required String requestId}) async {
    final openWallet =
        await sendBackgroudMessage(_ExtentionWalletHandlerConst.openEvent);
    if (openWallet.type != WalletEventTypes.popup) {
      throw Exception("Open popup failed");
    }
    final port = await _openPort();
    void onDisconnect(RuntimePort port) {
      completer.complete(
          response: Web3RequestExceptionConst.rejectedByUser
              .toResponseMessage(requestId: requestId),
          requestId: requestId);
    }

    void onMessage(JSWalletEvent event, RuntimePort port) {
      if (event.clientId != clientId || event.requestId != requestId) return;
      _onResponse(event);
    }

    port.onDisconnect.addListener(onDisconnect.toJS);
    port.onMessage.addListener(onMessage.toJS);
    port.postMessage(message.toJsEvent());
  }

  @override
  Future<void> _sendMessageToWallet(
      {required Web3MessageCore message, required String requestId}) async {
    final encryptedMessage = _encryptMessage(message);
    final event = WalletEvent(
        clientId: clientId,
        data: encryptedMessage.toCbor().encode(),
        requestId: requestId,
        type: WalletEventTypes.message);
    await _sendMessageToExtention(message: event, requestId: requestId);
  }
}