import 'package:breez/bloc/user_profile/currency.dart';
import 'package:breez/bloc/user_profile/security_model.dart';
import 'business_adress.dart';

class BreezUserModel {
  final String userID;
  final Currency currency;
  final String fiatCurrency;
  final String token;
  final String name;
  final String color;
  final String animal;
  final String image;
  final SecurityModel securityModel;
  final String themeId;
  final bool locked;
  final bool registrationRequested;
  final bool isPOS;
  final bool hideBalance;
  final double cancellationTimeoutValue;
  final bool hasAdminPassword;
  final BusinessAddress businessAddress;
  final String posCurrencyShortName;
  final List<String> preferredCurrencies;

  BreezUserModel._(this.userID, this.name, this.color, this.animal,
      {this.currency = Currency.SAT,
      this.fiatCurrency = "USD",
      this.image,
      this.securityModel,
      this.locked,
      this.token = '',
      this.themeId = "BLUE",
      this.registrationRequested = false,
      this.isPOS = false,
      this.hideBalance = false,
      this.cancellationTimeoutValue = 90.0,
      this.hasAdminPassword = false,
      this.businessAddress,
      this.posCurrencyShortName = "SAT",
      this.preferredCurrencies});

  BreezUserModel copyWith(
      {String name,
      String color,
      String animal,
      Currency currency,
      String fiatCurrency,
      String image,
      SecurityModel securityModel,
      bool locked,
      String token,
      String userID,
      String themeId,
      bool registrationRequested,
      bool isPOS,
      bool hideBalance,
      double cancellationTimeoutValue,
      bool hasAdminPassword,
      BusinessAddress businessAddress,
      String posCurrencyShortName,
      List<String> preferredCurrencies}) {
    return BreezUserModel._(
      userID ?? this.userID,
      name ?? this.name,
      color ?? this.color,
      animal ?? this.animal,
      currency: currency ?? this.currency,
      fiatCurrency: fiatCurrency ?? this.fiatCurrency,
      image: image ?? this.image,
      securityModel: securityModel ?? this.securityModel,
      locked: locked ?? this.locked,
      token: token ?? this.token,
      themeId: themeId ?? this.themeId,
      registrationRequested:
          registrationRequested ?? this.registrationRequested,
      isPOS: isPOS ?? this.isPOS,
      hideBalance: hideBalance ?? this.hideBalance,
      cancellationTimeoutValue:
          cancellationTimeoutValue ?? this.cancellationTimeoutValue,
      hasAdminPassword: hasAdminPassword ?? this.hasAdminPassword,
      businessAddress: businessAddress ?? this.businessAddress,
      posCurrencyShortName: posCurrencyShortName ?? this.posCurrencyShortName,
      preferredCurrencies: preferredCurrencies ?? this.preferredCurrencies,
    );
  }

  bool get registered {
    return userID != null;
  }

  String get avatarURL => image == null || image.isEmpty
      ? 'breez://profile_image?animal=$animal&color=$color'
      : image;

  BreezUserModel.fromJson(Map<String, dynamic> json)
      : userID = json['userID'],
        token = json['token'],
        currency = json['currency'] == null
            ? Currency.SAT
            : Currency.fromTickerSymbol(json['currency']),
        fiatCurrency =
            json['fiatCurrency'] == null ? "USD" : json['fiatCurrency'],
        name = json['name'],
        color = json['color'],
        animal = json['animal'],
        image = json['image'],
        locked = true,
        securityModel = json['securityModel'] == null
            ? SecurityModel.initial()
            : SecurityModel.fromJson(
                json['securityModel'],
              ),
        themeId = json['themeId'] == null ? "BLUE" : json['themeId'],
        registrationRequested =
            json['registrationRequested'] ?? json['token'] != null,
        isPOS = json['isPOS'] ?? false,
        hideBalance = json['hideBalance'] ?? false,
        cancellationTimeoutValue = json['cancellationTimeoutValue'] == null
            ? 90.0
            : json['cancellationTimeoutValue'],
        hasAdminPassword = json['hasAdminPassword'] ?? false,
        businessAddress = json['businessAddress'] == null
            ? BusinessAddress.initial()
            : BusinessAddress.fromJson(json['businessAddress']),
        posCurrencyShortName = json['posCurrencyShortName'] ?? "SAT",
        preferredCurrencies =
            (json['preferredCurrencies'] as List<dynamic>)?.cast<String>() ??
                <String>['USD', 'EUR', 'GBP', 'JPY'];

  Map<String, dynamic> toJson() => {
        'userID': userID,
        'token': token,
        'currency': currency.tickerSymbol,
        'fiatCurrency': fiatCurrency,
        'name': name,
        'color': color,
        'animal': animal,
        'image': image,
        'securityModel': securityModel?.toJson(),
        'themeId': themeId,
        'registrationRequested': registrationRequested,
        'cancellationTimeoutValue': cancellationTimeoutValue,
        'isPOS': isPOS,
        'hideBalance': hideBalance,
        'hasAdminPassword': hasAdminPassword,
        'posCurrencyShortName': posCurrencyShortName,
        'businessAddress': businessAddress,
        'preferredCurrencies': preferredCurrencies,
      };
}
