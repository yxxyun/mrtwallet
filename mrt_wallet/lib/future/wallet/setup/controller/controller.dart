import 'package:blockchain_utils/bip/bip/bip39/bip39.dart';
import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/utils/compare/compare.dart';
import 'package:flutter/material.dart';
import 'package:mrt_native_support/platform_interface.dart';
import 'package:mrt_wallet/app/core.dart';
import 'package:mrt_wallet/future/wallet/controller/controller.dart';
import 'package:mrt_wallet/future/widgets/widgets/progress_bar/progress.dart';
import 'package:mrt_wallet/wallet/models/models.dart';
import 'package:mrt_wallet/wallet/provider/wallet_provider.dart';

enum SetupWalletPage {
  password,
  mnemonic,
  confirm,
  extraOption,
  enterMnemonic,
  backup,
  setting
}

enum SetupWalletMode {
  generate,
  exist,
  backup;

  SetupWalletPage get walletPage {
    switch (this) {
      case SetupWalletMode.exist:
        return SetupWalletPage.enterMnemonic;
      case SetupWalletMode.backup:
        return SetupWalletPage.backup;
      default:
        return SetupWalletPage.mnemonic;
    }
  }
}

class SetupWalletController extends StateController {
  SetupWalletController(this.setupMode, this.walletProvider);
  final SetupWalletMode setupMode;
  final WalletProvider walletProvider;

  bool _legacyBackup = false;
  bool get lagacyBackup => _legacyBackup;
  Mnemonic? _mnemonic;
  Mnemonic? get mnemonic => _mnemonic;

  HDWallet? _wallet;
  HDWallet? get wallet => _wallet;
  WalletRestoreV2? _backup;
  int _mnemoicWord = 12;
  int get mnemonicWord => _mnemoicWord;

  bool get hasMnemonic => _mnemonic != null;

  Bip39Languages _language = Bip39Languages.english;
  Bip39Languages get language => _language;

  SetupWalletPage _page = SetupWalletPage.password;
  SetupWalletPage get page => _page;
  bool get inPassword => _page == SetupWalletPage.password;
  bool get inMnemonic => _page == SetupWalletPage.mnemonic;
  bool get inConfirm => _page == SetupWalletPage.confirm;
  bool get inExtraOption => _page == SetupWalletPage.extraOption;

  void toggleLegacy() {
    _legacyBackup = !_legacyBackup;
    notify();
  }

  void _reset() {
    _mnemonic = null;
    _mnemoicWord = 12;
    _language = Bip39Languages.english;
    _page = SetupWalletPage.password;
  }

  void backButton() {
    switch (page) {
      case SetupWalletPage.setting:
        _page = setupMode.walletPage;
        break;
      case SetupWalletPage.extraOption:
        _page = SetupWalletPage.confirm;
        break;
      case SetupWalletPage.confirm:
        _reset();
        break;
      case SetupWalletPage.mnemonic:
      case SetupWalletPage.enterMnemonic:
      case SetupWalletPage.backup:
        _mnemonic = null;
        _page = SetupWalletPage.password;
        _legacyBackup = false;
        break;
      default:
        break;
    }
    notify();
  }

  String _password = "";

  void setPassword(String password) {
    if (StrUtils.isStrongPassword(password)) {
      _password = password;
      _page = setupMode.walletPage;
      notify();
    }
  }

  void updateMnemonicCount(int? value) {
    if (value == null) return;
    _mnemoicWord = value;
    _mnemonic = null;
    notify();
  }

  void updateLanguage(Bip39Languages? language) {
    if (language == null) return;
    _language = language;
    _mnemonic = null;
    notify();
  }

  void regenerate() {
    _mnemonic = null;
    notify();
  }

  void _generate() {
    final wNum = Bip39WordsNum.values
        .firstWhere((element) => element.value == _mnemoicWord);
    final mne = Bip39MnemonicGenerator(language);
    _mnemonic = mne.fromWordsNumber(wNum);
  }

  void toConfirm() {
    if (_mnemonic == null) return;
    _page = SetupWalletPage.confirm;
    notify();
  }

  final GlobalKey<StreamWidgetState> generateMnemonicKey = GlobalKey();
  Future<void> generateMnemonic() async {
    if (mnemonic == null) {
      generateMnemonicKey.process();
      await Future.microtask(() => _generate());
      generateMnemonicKey.success();
      notify();
    } else {
      toConfirm();
    }
  }

  void toExtra(List<String> selectedMnemonic) {
    if (!CompareUtils.iterableIsEqual(selectedMnemonic, _mnemonic?.toList())) {
      return;
    }
    _page = SetupWalletPage.extraOption;
    notify();
  }

  Future<void> setupHDWallet(WalletUpdateInfosData walletInfos) async {
    if (wallet == null) {
      throw WalletExceptionConst.dataVerificationFailed;
    }
    MethodResult<void> result;
    if (_backup != null) {
      result = await walletProvider.setupBackup(
          backup: _backup!, password: _password, walletInfos: walletInfos);
    } else {
      result = await walletProvider.setup(
          hdWallet: wallet!, password: _password, walletInfos: walletInfos);
    }
    result.rethrowIfError();
  }

  Future<void> setup(String? passphrase, {Mnemonic? exitingMnemonic}) async {
    if (passphrase?.isEmpty ?? false) {
      throw WalletExceptionConst.invalidMnemonicPassphrase;
    }
    if (!StrUtils.isStrongPassword(_password)) {
      throw WalletExceptionConst.incorrectPassword;
    }
    exitingMnemonic ??= mnemonic!;
    _wallet = await walletProvider.createWallet(
        mnemonic: exitingMnemonic.toStr(),
        passphrase: passphrase,
        password: _password);
    _page = SetupWalletPage.setting;
    notify();
  }

  Future<WalletRestoreV2> restoreWalletBackup(List<int> walletBackupBytes,
      {String? passphrase}) async {
    if (passphrase?.isEmpty ?? false) {
      throw WalletExceptionConst.invalidMnemonicPassphrase;
    }
    if (!StrUtils.isStrongPassword(_password)) {
      throw WalletExceptionConst.incorrectPassword;
    }
    _backup = await walletProvider.restoreWalletBackup(
        backupBytes: walletBackupBytes,
        passhphrase: passphrase,
        password: _password);
    _wallet = _backup!.wallet;
    return _backup!;
  }

  Future<WalletRestoreV2> restoreWalletBackupV3(MRTBackup backup,
      {String? passphrase}) async {
    if (passphrase?.isEmpty ?? false) {
      throw WalletExceptionConst.invalidMnemonicPassphrase;
    }
    if (!StrUtils.isStrongPassword(_password)) {
      throw WalletExceptionConst.incorrectPassword;
    }
    _backup = await walletProvider.restoreWalletBackupV3(
        backup: backup, passhphrase: passphrase, password: _password);
    _wallet = _backup!.wallet;
    return _backup!;
  }

  void setupBackup(WalletRestoreV2 backup, {String? passphrase}) {
    _backup = backup;
    _page = SetupWalletPage.setting;
    notify();
  }

  @override
  String get repositoryId => "setup_wallet";

  @override
  void close() {
    PlatformInterface.interface.secureFlag(isSecure: false);
  }

  @override
  void init() {
    PlatformInterface.interface.secureFlag(isSecure: true);
    super.init();
  }
}