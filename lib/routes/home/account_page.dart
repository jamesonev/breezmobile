import 'package:breez/bloc/account/account_bloc.dart';
import 'package:breez/bloc/account/account_model.dart';
import 'package:breez/bloc/blocs_provider.dart';
import 'package:breez/bloc/connect_pay/connect_pay_bloc.dart';
import 'package:breez/bloc/lsp/lsp_bloc.dart';
import 'package:breez/bloc/lsp/lsp_model.dart';
import 'package:breez/bloc/user_profile/breez_user_model.dart';
import 'package:breez/bloc/user_profile/currency.dart';
import 'package:breez/bloc/user_profile/user_profile_bloc.dart';
import 'package:breez/theme_data.dart' as theme;
import 'package:breez/utils/date.dart';
import 'package:breez/widgets/fixed_sliver_delegate.dart';
import 'package:flutter/material.dart';

import 'payments_filter.dart';
import 'payments_list.dart';
import 'status_text.dart';
import 'wallet_dashboard.dart';

const DASHBOARD_MAX_HEIGHT = 176.25;
const DASHBOARD_MIN_HEIGHT = 70.0;
const FILTER_MAX_SIZE = 56.0;
const FILTER_MIN_SIZE = 0.0;
const PAYMENT_LIST_ITEM_HEIGHT = 72.0;

class AccountPage extends StatefulWidget {
  final GlobalKey firstPaymentItemKey;
  final ScrollController scrollController;

  AccountPage(this.firstPaymentItemKey, this.scrollController);

  @override
  State<StatefulWidget> createState() {
    return AccountPageState();
  }
}

class AccountPageState extends State<AccountPage>
    with SingleTickerProviderStateMixin {
  final List<String> currencyList =
      Currency.currencies.map((c) => c.tickerSymbol).toList();

  AccountBloc _accountBloc;
  UserProfileBloc _userProfileBloc;
  ConnectPayBloc _connectPayBloc;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    if (!_isInit) {
      _accountBloc = AppBlocsProvider.of<AccountBloc>(context);
      _userProfileBloc = AppBlocsProvider.of<UserProfileBloc>(context);
      _connectPayBloc = AppBlocsProvider.of<ConnectPayBloc>(context);
      //a listener that rebuilds our widget tree when payment filter changes
      _accountBloc.paymentFilterStream.listen((event) {
        widget.scrollController.position
            .restoreOffset(widget.scrollController.offset + 1);
        Future.delayed(Duration(milliseconds: 150), () => {setState(() {})});
      });
      _isInit = true;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AccountSettings>(
        stream: _accountBloc.accountSettingsStream,
        builder: (settingCtx, settingSnapshot) {
          return StreamBuilder<AccountModel>(
              stream: _accountBloc.accountStream,
              builder: (context, snapshot) {
                AccountModel account = snapshot.data;
                return StreamBuilder<PaymentsModel>(
                    stream: _accountBloc.paymentsStream,
                    builder: (context, snapshot) {
                      PaymentsModel paymentsModel =
                          snapshot.data ?? PaymentsModel.initial();
                      return Container(
                        color: paymentsModel.paymentsList.length % 2 == 1 &&
                                paymentsModel.paymentsList.length != 0
                            ? theme.customData[theme.themeId]
                                .paymentListAlternateBgColor
                            : theme
                                .customData[theme.themeId].paymentListBgColor,
                        child: _buildBalanceAndPayments(paymentsModel, account),
                      );
                    });
              });
        });
  }

  Widget _buildBalanceAndPayments(
      PaymentsModel paymentsModel, AccountModel account) {
    LSPBloc lspBloc = AppBlocsProvider.of<LSPBloc>(context);

    double listHeightSpace = MediaQuery.of(context).size.height -
        DASHBOARD_MIN_HEIGHT -
        kToolbarHeight -
        FILTER_MAX_SIZE -
        25.0;
    double dateFilterSpace = paymentsModel?.filter?.startDate != null &&
            paymentsModel?.filter?.endDate != null
        ? 0.65
        : 0.0;
    double bottomPlaceholderSpace = paymentsModel.paymentsList == null ||
            paymentsModel.paymentsList.length == 0
        ? 0.0
        : (listHeightSpace -
                PAYMENT_LIST_ITEM_HEIGHT *
                    (paymentsModel.paymentsList.length + 1 + dateFilterSpace))
            .clamp(0.0, listHeightSpace);

    String message;
    bool showMessage = account?.syncUIState != SyncUIState.BLOCKING &&
        (account != null && !account.initial);

    List<Widget> slivers = List<Widget>();
    slivers.add(SliverPersistentHeader(
        floating: false,
        delegate: WalletDashboardHeaderDelegate(_accountBloc, _userProfileBloc),
        pinned: true));
    if (paymentsModel.nonFilteredItems.length > 0) {
      slivers.add(PaymentFilterSliver(widget.scrollController, FILTER_MIN_SIZE,
          FILTER_MAX_SIZE, _accountBloc, paymentsModel));
    }
    if (paymentsModel?.filter?.startDate != null &&
        paymentsModel?.filter?.endDate != null) {
      slivers.add(SliverAppBar(
        pinned: true,
        elevation: 0.0,
        expandedHeight: 32.0,
        automaticallyImplyLeading: false,
        backgroundColor: theme.customData[theme.themeId].paymentListBgColor,
        flexibleSpace: _buildDateFilterChip(paymentsModel.filter),
      ));
    }

    if (paymentsModel.nonFilteredItems.length > 0) {
      slivers.add(PaymentsList(
          paymentsModel.paymentsList,
          PAYMENT_LIST_ITEM_HEIGHT,
          widget.firstPaymentItemKey,
          widget.scrollController));
      slivers.add(SliverPersistentHeader(
          pinned: true,
          delegate:
              FixedSliverDelegate(bottomPlaceholderSpace, child: Container())));
    } else if (showMessage) {
      slivers.add(SliverPersistentHeader(
        delegate: FixedSliverDelegate(250.0,
            builder: (context, shrinkedHeight, overlapContent) {
          return StreamBuilder<LSPStatus>(
              stream: lspBloc.lspStatusStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data.selectionRequired) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 120.0),
                    child: NoLSPWidget(
                      error: snapshot.data.lastConnectionError,
                    ),
                  );
                }
                return Container(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: 120.0, left: 40.0, right: 40.0),
                    child: StatusText(account, message: message),
                  ),
                );
              });
        }),
      ));
    }

    return Stack(
      key: Key("account_sliver"),
      fit: StackFit.expand,
      children: [
        paymentsModel.nonFilteredItems.length == 0
            ? CustomPaint(painter: BubblePainter(context))
            : SizedBox(),
        CustomScrollView(controller: widget.scrollController, slivers: slivers),
      ],
    );
  }

  _buildDateFilterChip(PaymentFilterModel filter) {
    return (filter.startDate != null && filter.endDate != null)
        ? _filterChip(filter)
        : Container();
  }

  Widget _filterChip(PaymentFilterModel filter) {
    return Container(
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  width: 1,
                  color:
                      theme.customData[theme.themeId].paymentListDividerColor)),
          color: theme.customData[theme.themeId].paymentListBgColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              bottom: 8,
            ),
            child: Chip(
              backgroundColor: Theme.of(context).bottomAppBarColor,
              label: Text(BreezDateUtils.formatFilterDateRange(
                  filter.startDate, filter.endDate)),
              onDeleted: () => _accountBloc.paymentFilterSink
                  .add(PaymentFilterModel(filter.paymentType, null, null)),
            ),
          )
        ],
      ),
    );
  }
}

class BubblePainter extends CustomPainter {
  BuildContext context;

  BubblePainter(this.context);

  @override
  void paint(Canvas canvas, Size size) {
    var bubblePaint = Paint()
      ..color = theme.themeId == "BLUE"
          ? Color(0xFF0085fb).withOpacity(0.1)
          : Color(0xff4D88EC).withOpacity(0.1)
      ..style = PaintingStyle.fill;
    double bubbleRadius = 12;
    double height = (MediaQuery.of(context).size.height - kToolbarHeight);
    canvas.drawCircle(
        Offset(MediaQuery.of(context).size.width / 2, height * 0.34),
        bubbleRadius,
        bubblePaint);
    canvas.drawCircle(
        Offset(MediaQuery.of(context).size.width * 0.39, height * 0.56),
        bubbleRadius * 1.5,
        bubblePaint);
    canvas.drawCircle(
        Offset(MediaQuery.of(context).size.width * 0.65, height * 0.68),
        bubbleRadius * 1.25,
        bubblePaint);
    canvas.drawCircle(
        Offset(MediaQuery.of(context).size.width / 2, height * 0.77),
        bubbleRadius * 0.75,
        bubblePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class WalletDashboardHeaderDelegate extends SliverPersistentHeaderDelegate {
  final AccountBloc accountBloc;
  final UserProfileBloc _userProfileBloc;

  WalletDashboardHeaderDelegate(this.accountBloc, this._userProfileBloc);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return StreamBuilder<BreezUserModel>(
        stream: _userProfileBloc.userStream,
        builder: (settingCtx, userSnapshot) {
          return StreamBuilder<AccountModel>(
              stream: accountBloc.accountStream,
              builder: (context, snapshot) {
                double height =
                    (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);
                double heightFactor =
                    (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

                return Stack(overflow: Overflow.visible, children: <Widget>[
                  WalletDashboard(
                    userSnapshot.data,
                    snapshot.data,
                    height,
                    heightFactor,
                    _userProfileBloc.currencySink.add,
                    _userProfileBloc.fiatConversionSink.add,
                    (hideBalance) => _userProfileBloc.userSink.add(
                      userSnapshot.data.copyWith(hideBalance: hideBalance),
                    ),
                  )
                ]);
              });
        });
  }

  @override
  double get maxExtent => DASHBOARD_MAX_HEIGHT;

  @override
  double get minExtent => DASHBOARD_MIN_HEIGHT;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class NoLSPWidget extends StatelessWidget {
  final String error;

  const NoLSPWidget({Key key, this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> buttons = [
      Container(
        height: 24.0,
        child: OutlineButton(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.0)),
            borderSide: BorderSide(
                style: BorderStyle.solid, color: Theme.of(context).buttonColor),
            child: Text("SELECT...", style: TextStyle(fontSize: 12.3)),
            onPressed: () {
              Navigator.of(context).pushNamed("/select_lsp");
            }),
      )
    ];

    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text("In order to activate Breez, please select a provider:")
            ],
          ),
          SizedBox(height: 24),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: buttons)
        ]);
  }
}
