import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';

class RetionalConst {
  static BigRational bigR8 = BigRational(BigInt.from(10).pow(8));
  static BigRational bigR18 = BigRational(BigInt.from(10).pow(18));
  static BigRational bigR6 = BigRational(BigInt.from(10).pow(6));
  static BigRational bigR12 = BigRational(BigInt.from(10).pow(12));
  static BigRational bigR10 = BigRational(BigInt.from(10).pow(10));
  static BigRational fromDecimalNumber(int decimal) {
    switch (decimal) {
      case 8:
        return bigR8;
      case 18:
        return bigR18;
      case 6:
        return bigR6;
      case 12:
        return bigR12;
      case 10:
        return bigR10;
      default:
        return BigRational(BigInt.from(10).pow(decimal));
    }
  }
}
