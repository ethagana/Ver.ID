import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:asn1lib/asn1lib.dart';
import 'package:connectivity/connectivity.dart';
import 'package:diff_image/diff_image.dart';
import 'package:emoji_feedback/emoji_feedback.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:file/memory.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:gradient_app_bar/gradient_app_bar.dart';
import 'package:gradient_widgets/gradient_widgets.dart';
import 'package:hand_signature/signature.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:path_provider/path_provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:pointycastle/api.dart' as pc_api;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/signers/rsa_signer.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:line_icons/line_icons.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_gauges/gauges.dart' as sf_gauge;
import 'package:tflite/tflite.dart';
import 'package:time_machine/time_machine.dart' as tm;
import 'package:image/image.dart' as img;
import 'package:timeline_list/timeline.dart';
import 'package:timeline_list/timeline_model.dart';
import 'package:charts_flutter/flutter.dart' as charts;

final String url = 'https://blueviolet.tech/ver_id/websrvc.php';

bool isDark = false;

Database db;

ProgressDialog pr;

String db_path;

String usr_img =
    'https://icons.iconarchive.com/icons/bokehlicia/captiva/256/user-icon.png';

String usr_name;

String usr_curr = '';

String bank_logo;

String fid;

double total_amt = 0.0;

int _selectedIndex = 0;

TextEditingController bankController = new TextEditingController();

TextEditingController accController = new TextEditingController();

TextEditingController accDescController = new TextEditingController();

TextEditingController pinController = new TextEditingController();

TextEditingController amtController = new TextEditingController();

TextEditingController u_dteController = new TextEditingController();

TextEditingController l_dteController = new TextEditingController();

TextEditingController fdbkController = new TextEditingController();

TextEditingController rtelController = new TextEditingController();

TextEditingController escrw_rej_Controller = new TextEditingController();

List<Map> lstBanks = new List<Map>();

List<Map> lstAccs = new List<Map>();

List<Map> lstTrans = new List<Map>();

List<Map> lstEscrws = new List<Map>();

List<Map> lstAnaChrt = new List<Map>();

List<Map> lstAnaFChrt = new List<Map>();

List<Map> lstFtrans = new List<Map>();

bool hasError = false;

bool escrow = false;

final curr_format = new NumberFormat("#,##0.00", "en_KE");

final FirebaseMessaging fcm = FirebaseMessaging();

String client_sig;

BuildContext bcntx;

BuildContext c_cntx;

int touchedIndex;

class MyHome extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<MyHome> with WidgetsBindingObserver {
  @override
  void initState() {
    //intialize Database
    iniDB();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => getData());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).platformBrightness == Brightness.dark) {
      isDark = true;
    } else {
      isDark = false;
    }

    final _tabs = [HomeTab(context), AccTab(context), AnaTab(context)];
    final _titles = ['Home', 'Accounts', 'Analytics'];

    bcntx = context;

    return Scaffold(
        appBar: GradientAppBar(
          centerTitle: true,
          title: Text(_titles[_selectedIndex]),
          gradient: !isDark ? Gradients.rainbowBlue : Gradients.cosmicFusion,
          leading: Visibility(
              visible: _selectedIndex == 2 ? true : false,
              child: IconButton(
                padding: EdgeInsets.all(5),
                iconSize: 21,
                icon: FaIcon(FontAwesomeIcons.calendarWeek),
                onPressed: () {
                  u_dteController.text = '';
                  l_dteController.text = '';
                  showDPT(null);
                },
              )),
          actions: <Widget>[
            Container(
                child: CircleAvatar(
              child: ClipOval(
                child: Image.network(usr_img),
              ),
              maxRadius: 19,
            ))
          ],
        ),
        body: _tabs[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.white,
              boxShadow: [
                BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1))
              ]),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
              child: GNav(
                gap: 8,
                activeColor: Colors.white,
                iconSize: 24,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                duration: Duration(milliseconds: 800),
                tabBackgroundColor:
                    isDark ? Colors.purple[800] : Colors.blue[800],
                tabs: [
                  GButton(
                    icon: LineIcons.home,
                    text: 'Home',
                  ),
                  GButton(
                    icon: LineIcons.bank,
                    text: 'Accounts',
                  ),
                  GButton(
                    icon: LineIcons.bar_chart_o,
                    text: 'Analytics',
                  ),
                ],
                selectedIndex: _selectedIndex,
                onTabChange: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
            ),
          ),
        ),
        floatingActionButton: Visibility(
          visible: _selectedIndex == 1 ? true : false,
          child: FloatingActionButton(
            tooltip: 'Add New Account',
            child: Icon(LineIcons.plus),
            onPressed: () => regAccDialog(),
          ),
        ));
  }

  Future<void> iniDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    db_path = documentsDirectory.path + "/ver_id.db3";
    db = await openDatabase(db_path);
  }

  void iniFCM() {
    fcm.configure(
        onMessage: (Map<String, dynamic> message) async {
          print("onMessage_AppActive: $message");
          proMsg(message);
          //proMsg(message['data']['list_name'], message['data']['message']);
        },
        onLaunch: (Map<String, dynamic> message) async {
          print("onLaunch_AppActive: $message");
          proMsg(message);
          //proMsg(message['data']['list_name'], message['data']['message']);
        },
        onResume: (Map<String, dynamic> message) async {
          print("onResume_AppResume: $message");
          proMsg(message);
          //proMsg(message['title'], message['data']['message']);
        },
        onBackgroundMessage:
            Platform.isAndroid ? myBackgroundMessageHandler : null);
  }

  Future<void> proMsg(Map<String, dynamic> message) async {
    print(jsonEncode(message['data']));
    if (await fcmProcessed(message)) {
      return;
    }
    if (message['data']['Msg'].toString().startsWith('Auto Approved')) {
      regAutoApprvlTrans(message);
    } else if (message['data']['Msg']
        .toString()
        .startsWith('Release Amount of')) {
      final LocalAuthentication auth = LocalAuthentication();
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: Text(
                'Request Authentication',
                style: TextStyle(fontFamily: 'Montserrat'),
              ),
              content: Text(message['data']['Msg'],
                  style: TextStyle(fontFamily: 'Montserrat')),
              actions: [
                CupertinoDialogAction(
                  child: Text('Release',
                      style: TextStyle(fontFamily: 'Montserrat')),
                  onPressed: () async {
                    bool connAvail = await valConn();
                    if (connAvail) {
                      try {
                        //Process Approval
                        bool didAuthenticate =
                            await auth.authenticateWithBiometrics(
                                localizedReason:
                                    'Please authenticate to verify release',
                                useErrorDialogs: false);
                        if (didAuthenticate) {
                          Navigator.pop(context);
                          updteEscrow(true, message);
                        } else {
                          custMsg('Escrow Release',
                              'Unable to process release - Authentication Failure');
                        }
                      } on PlatformException catch (e) {
                        if (e.code == auth_error.permanentlyLockedOut) {
                          custMsg('Authentication',
                              'VerID Locked awaiting PIN/Password/Pattern Input');
                        }
                      }
                    } else {
                      custMsg('Network Connection', 'No Internet Connection ');
                    }
                  },
                ),
                CupertinoDialogAction(
                  child: Text('Decline',
                      style: TextStyle(fontFamily: 'Montserrat')),
                  onPressed: () async {
                    bool connAvail = await valConn();
                    if (connAvail) {
                      bool didAuthenticate = await auth.authenticateWithBiometrics(
                          localizedReason:
                              'Please authenticate to verify Escrow release decline ',
                          useErrorDialogs: false);
                      if (didAuthenticate) {
                        shwEscrwTerms(context, message);
                        //TODO:Update Escrow to decline expect rejection reason
                        //reqEscrowRegReason(message);
                      } else {
                        //Declare transaction fraudulent
                        custMsg(
                            'Request Authentication', 'Authentication Failure');
                      }
                    } else {
                      custMsg('Network Connection', 'No Internet Connection ');
                    }
                  },
                )
              ],
            );
          });
    } else {
      final LocalAuthentication auth = LocalAuthentication();
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: Text(
                'Request Authentication',
                style: TextStyle(fontFamily: 'Montserrat'),
              ),
              content: Text(
                  'Approve Removal of ' +
                      message['data']['Curr'] +
                      ' ' +
                      curr_format.format(double.parse(message['data']['Amt'])) +
                      ' from your ' +
                      message['data']['Sent By'] +
                      ' Acc ' +
                      message['data']['Acc'] +
                      ' On ' +
                      message['data']['Sent On'],
                  style: TextStyle(fontFamily: 'Montserrat')),
              actions: [
                CupertinoDialogAction(
                  child: Text('Approve',
                      style: TextStyle(fontFamily: 'Montserrat')),
                  onPressed: () async {
                    bool connAvail = await valConn();
                    if (connAvail) {
                      try {
                        //Process Approval
                        bool didAuthenticate =
                            await auth.authenticateWithBiometrics(
                                localizedReason:
                                    'Please authenticate to verify transaction from ' +
                                        message['data']['Sent By'],
                                useErrorDialogs: false);
                        Navigator.pop(context);
                        if (didAuthenticate) {
                          reqEscrow(message);
                          //regTrans(true, 'N/A', message);
                        } else {
                          //Declare transaction fraudulent
                          regTrans(false, 'Failed Biometric Authentication',
                              message);
                        }
                      } on PlatformException catch (e) {
                        if (e.code == auth_error.permanentlyLockedOut) {
                          custMsg('Authentication',
                              'VerID Locked awaiting PIN/Password/Pattern Input');
                        }
                      }
                    } else {
                      custMsg('Network Connection', 'No Internet Connection ');
                    }
                  },
                ),
                CupertinoDialogAction(

                  child: Text('Decline',
                      style: TextStyle(fontFamily: 'Montserrat')),
                  onPressed: () async {
                    bool connAvail = await valConn();
                    if (connAvail) {
                      Navigator.pop(context);
                      //TODO: Capture decline reason
                      bool didAuthenticate = await auth.authenticateWithBiometrics(
                          localizedReason:
                              'Please authenticate to verify transaction from ' +
                                  message['data']['Sent By'],
                          useErrorDialogs: false);
                      if (didAuthenticate) {
                        getRejReason(message);
                      } else {
                        //Declare transaction fraudulent
                        regTrans(
                            false, 'Failed Biometric Authentication', message);
                      }
                    } else {
                      custMsg('Network Connection', 'No Internet Connection ');
                    }
                  },
                )
              ],
            );
          });
    }
  }

  getData() async {
    //Get the User Icon
    final storage = FlutterSecureStorage();
    usr_img = await storage.read(key: 'usr_pic');
    usr_name = await storage.read(key: 'usr_nme');
    usr_curr = await storage.read(key: 'currency');
    //usr_img = usr_img.replaceAll('s128', 's512');
    setState(() {
      //Update UI
    });

    await getFraudAggs();

    await chkAAValid();

    //Check if any accounts registered
    //Database db = await openDatabase(db_path);

    //List<Map> lstq = await db.rawQuery('SELECT * FROM verifications ORDER BY reg_on DESC');

    //print('Ver data - '+jsonEncode(lstq));

    //await db.rawDelete('DELETE FROM transactions WHERE id = (SELECT MAX(id) FROM transactions)');

    /*await db.rawQuery(
        'CREATE TABLE IF NOT EXISTS "escrow" ( "id" INTEGER PRIMARY KEY AUTOINCREMENT, '
        '"tid" INTEGER, "recpt" TEXT, "approved" INTEGER DEFAULT 0, "reg_on" TEXT )');*/

    /* await db.rawQuery('CREATE TABLE IF NOT EXISTS "fcm_log" '
        '( "id" INTEGER PRIMARY KEY AUTOINCREMENT, "gid" TEXT, '
        '"g_sent_time" TEXT, "reg_on" TEXT )');*/

    //await db.rawQuery('DELETE FROM accs_auto_trans');

    //await db.rawQuery('ALTER TABLE transactions ADD COLUMN curr_denom TEXT');

    /*await db.rawQuery('CREATE TABLE IF NOT EXISTS "accs_auto_trans" '
        '( "id" INTEGER PRIMARY KEY AUTOINCREMENT, "aid" INTEGER, "dur" TEXT, '
        '"trans_limit" INTEGER DEFAULT 1, "amt_limit" INTEGER, "reg_on" TEXT )');*/

    /*await db.rawDelete('DELETE FROM transactions');

    await db.rawQuery('DELETE FROM verifications');
*/
    //await db.rawDelete('DELETE FROM accs_auto_trans WHERE id = ?',[2]);

    //await db.rawQuery('ALTER TABLE my_accs ADD COLUMN fid INTEGER DEFAULT 0');

    /*await db.transaction((txn) async {
      db.rawQuery('UPDATE my_accs SET fid = 1 WHERE id = 2');

      db.rawQuery('UPDATE my_accs SET fid = 2 WHERE id = 1');
    });*/

    List<Map> lstRslt = await db.rawQuery('SELECT * FROM my_accs');

    //await db.close();

    print(jsonEncode(lstRslt));

    if (lstRslt.isEmpty) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext cxt) {
            return CupertinoAlertDialog(
              title: Text(
                'Accounts',
                style: TextStyle(fontFamily: 'Montserrat'),
              ),
              content: Text('Add an Account for Monitoring ?',
                  style: TextStyle(fontFamily: 'Montserrat')),
              actions: [
                CupertinoDialogAction(
                  child:
                      Text('Yes', style: TextStyle(fontFamily: 'Montserrat')),
                  onPressed: () {
                    Navigator.pop(context);
                    regAccDialog();
                  },
                ),
                CupertinoDialogAction(
                  child: Text('No', style: TextStyle(fontFamily: 'Montserrat')),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ],
            );
          });
    } else {
      //Prep FCM
      iniFCM();

      if (await storage.read(key: 'key_public') == null) {
        genKeys(storage);
      }

      //await storage.delete(key: 'sign');

      if (!await storage.containsKey(key: 'sign')) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return CupertinoAlertDialog(
                title: Text(
                  'Signature Capture',
                  style: TextStyle(fontFamily: 'Montserrat'),
                ),
                content: Text(
                    'For additional Security We request your Signature to authorize all transactions',
                    style: TextStyle(fontFamily: 'Montserrat')),
                actions: [
                  CupertinoDialogAction(
                    child:
                        Text('Ok', style: TextStyle(fontFamily: 'Montserrat')),
                    onPressed: () async {
                      bool connAvail = await valConn();
                      if (connAvail) {
                        Navigator.pop(context);
                        //Capture Signature
                        captureSignature();
                      } else {
                        custMsg(
                            'Network Connection', 'No Internet Connection ');
                      }
                    },
                  )
                ],
              );
            });
      }

      //Generate Client Signature

      String prv_key = await storage.read(key: 'key_private');

      String sig = await storage.read(key: 'sign');

      RSAPrivateKey p_key = parsePrivateKeyFromPem(prv_key);

      client_sig = sign(sig, p_key);

      String trans_state = sign('Yes', p_key);

      print('Digital Signature - ' + client_sig);

      print('Trans State - ' + trans_state);

      //Get the total amt
      await getTotalAmt();

      //Get all the registered accounts
      setState(() {
        lstAccs = lstRslt;
      });

      //shwAlertMsg(true, 'Testing', 'Testing 123');
    }
  }

  Future<void> getTotalAmt() async {
    if (!db.isOpen) {
      db = await openDatabase(db_path);
    }

    List<Map> lstTamt = new List<Map>();

    if (u_dteController.text.isNotEmpty && l_dteController.text.isNotEmpty) {
      //print("SELECT SUM(trans_amt) AS total_amt FROM transactions WHERE curr_denom = 'KES' AND DATE(date_req) BETWEEN "+u_dteController.text+" AND "+l_dteController.text);

      await db.transaction((txn) async {
        lstTamt = await txn.rawQuery(
            "SELECT SUM(trans_amt) AS total_amt FROM transactions JOIN verifications "
            "ON transactions.id = verifications.tid WHERE curr_denom = 'KES' AND DATE(date_req) BETWEEN ? AND ?",
            [u_dteController.text, l_dteController.text]);

        lstTrans = await txn.rawQuery(
            'SELECT * FROM transactions JOIN verifications ON transactions.id = verifications.tid '
            'WHERE curr_denom = ? AND DATE(date_req) BETWEEN ? AND ? ORDER BY id DESC LIMIT 20',
            ['KES', u_dteController.text, l_dteController.text]);

        lstEscrws = await txn.rawQuery(
            'SELECT tid,recpt,approved FROM transactions JOIN escrow ON transactions.id = escrow.tid '
            'WHERE approved = 0 AND DATE(date_req) BETWEEN ? AND ?',
            [u_dteController.text, l_dteController.text]);
      });

      print(jsonEncode(lstTamt));
    } else {
      lstTamt = await db.rawQuery(
          "SELECT SUM(trans_amt) AS total_amt FROM transactions WHERE curr_denom = 'KES'");

      lstTrans = await db.rawQuery(
          'SELECT * FROM transactions JOIN verifications ON transactions.id = verifications.tid ORDER BY id DESC LIMIT 20');

      lstEscrws = await db.rawQuery(
          'SELECT tid,recpt,approved FROM transactions JOIN escrow ON transactions.id = escrow.tid WHERE approved = 0');

      //print(jsonEncode(lstTrans));

      print(jsonEncode(lstEscrws));
    }

    //await db.close();

    if (lstTamt.isNotEmpty) {
      setState(() {
        total_amt = double.parse(lstTamt[0]['total_amt'].toString());
      });
    }
  }

  Widget HomeTab(BuildContext context) {
    return ListView(
      children: <Widget>[
        homeCard(),
        getFeedback(),
        sectionHeader(u_dteController.text.isEmpty
            ? 'Recent Transactions'
            : 'Recent Transactions\nBetween ' +
                u_dteController.text +
                ' And ' +
                l_dteController.text),
        Container(
            height: MediaQuery.of(context).size.width * 0.80,
            child: recentTransactions()),
      ],
    );
  }

  Widget homeCard() {
    return GradientCard(
        gradient: isDark ? Gradients.cosmicFusion : Gradients.rainbowBlue,
        shadowColor: isDark
            ? Gradients.cosmicFusion.colors.last.withOpacity(0.25)
            : Gradients.rainbowBlue.colors.last.withOpacity(0.25),
        elevation: 8,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  u_dteController.text.isEmpty
                      ? 'Total Amount Authenticated'
                      : 'Total Amount Authenticated\nBetween ' +
                          u_dteController.text +
                          ' And ' +
                          l_dteController.text,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                      color: Colors.black),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  usr_curr + ' ' + curr_format.format(total_amt),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Montserrat',
                      color: Colors.black),
                ),
                SizedBox(
                  height: 5,
                ),
                Divider(
                  height: 15,
                  thickness: 1,
                  color: Colors.white,
                ),
                ButtonBar(
                  alignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                        child: Text(
                          'Tell Me More',
                          style: TextStyle(
                              color: !isDark ? Colors.white : Colors.black),
                        ),
                        //color: !isDark ? Colors.white : Colors.black,
                        onPressed: () async {
                          if (total_amt > 0.0) {
                            showBreakdown();
                          } else {
                            custMsg('Total Amount Authenticated',
                                'No Transaction Authenticated');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                            foregroundColor:
                                !isDark ? Colors.white : Colors.black,
                            side: BorderSide(
                                color: !isDark ? Colors.white : Colors.black,
                                style: BorderStyle.solid,
                                width: 0.8)))
                  ],
                ),
              ]),
        ));
  }

  Widget getFeedback() {
    return GradientCard(
        gradient: isDark ? Gradients.byDesign : Gradients.tameer,
        shadowColor: isDark
            ? Gradients.byDesign.colors.last.withOpacity(0.25)
            : Gradients.tameer.colors.last.withOpacity(0.25),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 10, top: 10, bottom: 10),
                    child: Text('Let us know what you think',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700)),
                  ),
                  Image.asset(
                    'assets/feedback.png',
                    height: 60,
                    width: 60,
                  )
                ],
              ),
              Divider(
                height: 8,
                thickness: 1,
                color: Colors.white,
              ),
              ButtonBar(
                alignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                      child: Text(
                        'Give Feedback',
                        style: TextStyle(
                            color: !isDark ? Colors.white : Colors.black),
                      ),
                      //color: !isDark ? Colors.white : Colors.black,
                      onPressed: () async {
                        capFeedback();
                      },
                      style: OutlinedButton.styleFrom(
                          foregroundColor:
                              !isDark ? Colors.white : Colors.black,
                          side: BorderSide(
                              color: !isDark ? Colors.white : Colors.black,
                              style: BorderStyle.solid,
                              width: 0.8))),
                ],
              ),
            ],
          ),
        ));
  }

  void capFeedback() {
    int mood = 2;
    fdbkController.text = '';
    showDialog(
        context: this.context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final _formKey = GlobalKey<FormState>();
          return AlertDialog(
            title: Text(
              'Feedback Collection',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
            content: Stack(
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'How do we make you feel?',
                        style: TextStyle(fontFamily: 'Montserrat'),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      FittedBox(
                        child: EmojiFeedback(
                          onChange: (index) {
                            mood = index;
                          },
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      TextField(
                          controller: fdbkController,
                          maxLength: 200,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Color(0xFF159e39), width: 1.0)),
                              border: OutlineInputBorder(),
                              //errorText: valTel(),
                              labelText: "Let us know how we can improve"),
                          keyboardType: TextInputType.multiline),
                      SizedBox(
                        height: 10,
                      ),
                      GradientButton(
                        child: Text('Send Feedback'),
                        callback: () {
                          if (fdbkController.text.length > 2) {
                            Navigator.pop(context);
                            regFdbk(mood);
                          } else {
                            custMsg('Feedback',
                                'Kindly let us know how we can improve');
                          }
                        },
                        gradient: isDark
                            ? Gradients.cosmicFusion
                            : Gradients.rainbowBlue,
                        shadowColor: isDark
                            ? Gradients.cosmicFusion.colors.last
                                .withOpacity(0.25)
                            : Gradients.rainbowBlue.colors.last
                                .withOpacity(0.25),
                        increaseHeightBy: 10,
                        increaseWidthBy: double.maxFinite,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      GradientButton(
                        child: Text('Close'),
                        callback: () {
                          Navigator.pop(context);
                        },
                        gradient: Gradients.backToFuture,
                        shadowColor: Gradients.backToFuture.colors.last
                            .withOpacity(0.25),
                        increaseHeightBy: 10,
                        increaseWidthBy: double.maxFinite,
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }

  Widget sectionHeader(String headerTitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(left: 10, top: 10, bottom: 10),
          child: Text(headerTitle,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget recentTransactions() {
    if (lstTrans.isNotEmpty) {
      return ListView(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        children: [for (var itm in lstTrans) RTrans(itm)],
      );
    }
    return ListView(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      children: [noRT()],
    );
  }

  //
  Widget noRT() {
    return Container(
        padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: ExpansionTileCard(
          leading: FadeInImage.assetNetwork(
            placeholder: 'assets/loading.gif',
            image:
                "https://icons.iconarchive.com/icons/designcontest/ecommerce-business/256/bank-icon.png",
            fit: BoxFit.fill,
          ),
          title: Text('No Transactions'),
          subtitle: Text('...'),
        ));
  }

  //Image.network(itm['fi_logo'], fit: BoxFit.fill)

  Widget RTrans(var itm) {
    return Container(
        padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: ExpansionTileCard(
          leading: CircleAvatar(
            child: ClipOval(
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/loading.gif',
                image: itm['fi_logo'],
                fit: BoxFit.fill,
              ),
            ),
            backgroundColor: Colors.white,
          ),
          title: RichText(
            text: TextSpan(
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Montserrat',
                    fontSize: 16.0),
                children: [
                  TextSpan(text: 'Transaction of '),
                  TextSpan(
                      text: itm['curr_denom'] +
                          ' ' +
                          curr_format.format(itm['trans_amt']),
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  TextSpan(text: ' on acc ' + obscAccNo(itm['acc']))
                ]),
          ),
          subtitle: Text('Tap to see more!'),
          children: [
            Divider(
              thickness: 2.0,
              height: 1.0,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  itm['approved'] == 1
                      ? itm['trans_nme'] + ' - Approved'
                      : itm['trans_nme'] + ' - Rejected',
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2
                      .copyWith(fontSize: 16),
                ),
              ),
            ),
            isEscrowValid(itm)
                ? ButtonBar(
                    alignment: MainAxisAlignment.spaceAround,
                    buttonHeight: 52.0,
                    buttonMinWidth: 90.0,
                    children: [
                      TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0)),
                          ),
                          onPressed: () {
                            showDPT(itm);
                          },
                          child: Column(
                            children: <Widget>[
                              FaIcon(FontAwesomeIcons.receipt),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2.0),
                              ),
                              Text(
                                'Show me More',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )),
                      TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0)),
                          ),
                          onPressed: () {
                            //TODO:Process the Escrow release
                          },
                          child: Column(
                            children: <Widget>[
                              FaIcon(FontAwesomeIcons.lockOpen),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2.0),
                              ),
                              Text(
                                'Release Escrow',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ))
                    ],
                  )
                : ButtonBar(
                    alignment: MainAxisAlignment.spaceAround,
                    buttonHeight: 52.0,
                    buttonMinWidth: 90.0,
                    children: [
                      TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0)),
                          ),
                          onPressed: () {
                            showDPT(itm);
                          },
                          child: Column(
                            children: <Widget>[
                              FaIcon(FontAwesomeIcons.receipt),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2.0),
                              ),
                              Text(
                                'Show me More',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )),
                    ],
                  )
          ],
        ));
  }

  bool isEscrowValid(itm) {
    for (var s_itm in lstEscrws) {
      if (s_itm['tid'] == itm['id']) {
        print(jsonEncode(s_itm));
        print(jsonEncode(itm));
        print('Tid ' + s_itm['tid'].toString() + ' Id ' + itm['id'].toString());
        return true;
      }
    }
    return false;
  }

  String obscAccNo(String acc) {
    String acc_no = acc.substring(0, 4) +
        acc.substring(4, acc.length - 3).replaceAll(RegExp(r"."), "*") +
        acc.substring(acc.length - 3);

    return acc_no;
  }

  Widget AccTab(BuildContext context) {
    if (lstAccs.isNotEmpty) {
      return ListView(
        children: [for (var itm in lstAccs) Accs(itm)],
      );
    }
    return ListView(
      children: [noAccs()],
    );
  }

  Widget AnaTab(BuildContext cntx) {
    if (lstTrans.isNotEmpty) {
      return ListView(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        children: [
          shwYearlyTotal(),
          SizedBox(
            height: 5,
          ),
          FutureBuilder(
            future: loadAnaData(),
            builder: (cntx, snapshot) {
              if (snapshot.hasData) {
                return shwAnaTotal();
              } else {
                return noRT();
              }
            },
          ),
          SizedBox(
            height: 5,
          ),
          shwApprvVals(),
          SizedBox(
            height: 5,
          ),
          shwRejVals(),
          SizedBox(
            height: 5,
          ),
          shwAnaFraud(),
          SizedBox(
            height: 5,
          ),
          shwFraudMetr(),
          SizedBox(
            height: 2,
          ),
          shwFraudBD(),
          SizedBox(
            height: 5,
          ),
          FutureBuilder(
            future: getFraudAggs(),
            builder: (cntx, snapshot) {
              return shwHotFraudList();
            },
          ),
        ],
      );
    }
    return ListView(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      children: [noRT()],
    );
  }

  String getMonthName(String cde) {
    switch (int.parse(cde)) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
    }
    return '';
  }

  Widget shwYearlyTotal() {
    int total = 0;
    for (var itm in lstAnaChrt) {
      total = total + double.parse(itm['trans_amt'].toString()).toInt();
    }
    return GradientCard(
        gradient: isDark ? Gradients.byDesign : Gradients.tameer,
        shadowColor: isDark
            ? Gradients.byDesign.colors.last.withOpacity(0.25)
            : Gradients.tameer.colors.last.withOpacity(0.25),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 10, top: 10, bottom: 10),
                    child: Text(
                        u_dteController.text.isEmpty
                            ? 'Total Amount\nAuthenticated for the Year\n\nKES ' +
                                curr_format.format(total)
                            : 'Total Amount Authenticated\nBetween ' +
                                u_dteController.text +
                                ' And\n' +
                                l_dteController.text +
                                '\n\nKES ' +
                                curr_format.format(total),
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700)),
                  ),
                  Image.asset(
                    'assets/sum.png',
                    height: 60,
                    width: 60,
                  )
                ],
              ),
              Divider(
                height: 8,
                thickness: 1,
                color: Colors.white,
              ),
              ButtonBar(
                alignment: MainAxisAlignment.end,
                children: [
                  /* OutlineButton(
                      child: Text(
                        'Show Local Activity',
                        style: TextStyle(
                            color: !isDark ? Colors.white : Colors.black),
                      ),
                      color: !isDark ? Colors.white : Colors.black,
                      onPressed: () async {
                        //capFeedback();
                      },
                      borderSide: BorderSide(
                          color: !isDark ? Colors.white : Colors.black,
                          style: BorderStyle.solid,
                          width: 0.8))*/
                ],
              ),
            ],
          ),
        ));
  }

  Widget shwApprvVals() {
    int apprv_total = 0;

    for (var itm in lstAnaChrt) {
      if (itm['approved'] == 1) {
        apprv_total =
            apprv_total + double.parse(itm['trans_amt'].toString()).toInt();
      }
    }
    return GradientCard(
        gradient: isDark ? Gradients.byDesign : Gradients.tameer,
        shadowColor: isDark
            ? Gradients.byDesign.colors.last.withOpacity(0.25)
            : Gradients.tameer.colors.last.withOpacity(0.25),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 10, top: 10, bottom: 10),
                    child: Text(
                        u_dteController.text.isEmpty
                            ? 'Total Amount\nApproved for the Year\n\nKES ' +
                                curr_format.format(apprv_total)
                            : 'Total Amount Approved\nBetween ' +
                                u_dteController.text +
                                '\nAnd ' +
                                l_dteController.text +
                                '\n\nKES ' +
                                curr_format.format(apprv_total),
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700)),
                  ),
                  Image.asset(
                    'assets/apprv.png',
                    height: 60,
                    width: 60,
                  )
                ],
              ),
              Divider(
                height: 8,
                thickness: 1,
                color: Colors.white,
              ),
            ],
          ),
        ));
  }

  Widget shwRejVals() {
    int rej_total = 0;
    for (var itm in lstAnaChrt) {
      if (itm['approved'] == 0) {
        rej_total =
            rej_total + double.parse(itm['trans_amt'].toString()).toInt();
      }
    }
    return GradientCard(
        gradient: isDark ? Gradients.byDesign : Gradients.tameer,
        shadowColor: isDark
            ? Gradients.byDesign.colors.last.withOpacity(0.25)
            : Gradients.tameer.colors.last.withOpacity(0.25),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 10, top: 10, bottom: 10),
                    child: Text(
                        u_dteController.text.isEmpty
                            ? 'Total Amount\nRejected for the Year\n\nKES ' +
                                curr_format.format(rej_total)
                            : 'Total Amount Rejected\nBetween ' +
                                u_dteController.text +
                                ' And\n' +
                                l_dteController.text +
                                '\n\nKES ' +
                                curr_format.format(rej_total),
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700)),
                  ),
                  Image.asset(
                    'assets/fraud.png',
                    height: 60,
                    width: 60,
                  )
                ],
              ),
              Divider(
                height: 8,
                thickness: 1,
                color: Colors.white,
              ),
            ],
          ),
        ));
  }

  Widget shwFraudMetr() {
    int apprv_total = 0;
    int rej_total = 0;
    int frd_perc = 0;
    if (lstAnaChrt.isNotEmpty) {
      for (var itm in lstAnaChrt) {
        if (itm['approved'] == 0) {
          rej_total =
              rej_total + double.parse(itm['trans_amt'].toString()).toInt();
        } else {
          apprv_total =
              apprv_total + double.parse(itm['trans_amt'].toString()).toInt();
        }
      }
      frd_perc = ((rej_total / (apprv_total + rej_total)) * 100).round();
    }

    return AspectRatio(
        aspectRatio: 1.23,
        child: Padding(
          padding: EdgeInsets.all(5),
          child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.greenAccent
                    /*Color(0xff2c274c),
                  Color(0xff46426c),*/
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      const Text(
                        'Fraudometer',
                        style: TextStyle(
                            //color: Colors.white,
                            fontFamily: 'Montserrat',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        u_dteController.text.isEmpty
                            ? 'For the Year ' + DateTime.now().year.toString()
                            : 'Between ' +
                                u_dteController.text +
                                ' And ' +
                                l_dteController.text,
                        style: TextStyle(
                          //color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 32,
                      ),
                      Expanded(
                          child: Padding(
                              padding:
                                  const EdgeInsets.only(right: 10.0, left: 6.0),
                              child: sf_gauge.SfRadialGauge(
                                enableLoadingAnimation: true,
                                animationDuration: 4500,
                                axes: [
                                  sf_gauge.RadialAxis(
                                      minimum: 0,
                                      maximum: 100,
                                      ranges: <sf_gauge.GaugeRange>[
                                        sf_gauge.GaugeRange(
                                            startValue: 0,
                                            endValue: 50,
                                            label: 'Good',
                                            color: Colors.green,
                                            startWidth: 20,
                                            endWidth: 20),
                                        sf_gauge.GaugeRange(
                                            startValue: 50,
                                            endValue: 100,
                                            label: 'Bad',
                                            color: Colors.red,
                                            startWidth: 20,
                                            endWidth: 20)
                                      ],
                                      pointers: <sf_gauge.GaugePointer>[
                                        sf_gauge.NeedlePointer(
                                            value: frd_perc.toDouble())
                                      ],
                                      annotations: <sf_gauge.GaugeAnnotation>[
                                        sf_gauge.GaugeAnnotation(
                                            widget: Container(
                                                child: Text(
                                                    frd_perc.toString() + '%',
                                                    style: TextStyle(
                                                        fontSize: 25,
                                                        fontWeight:
                                                            FontWeight.bold))),
                                            angle: 90,
                                            positionFactor: 0.5)
                                      ])
                                ],
                              ))),
                    ],
                  )
                ],
              )),
        ));
  }

  Widget shwAnaTotal() {
    List<charts.Series> seriesList =
        new List<charts.Series<AuthTrans, String>>();
    List<String> accnmes = new List();
    List<AuthTrans> ref_chrtvals = new List();
    for (var itm in lstAnaChrt) {
      String sid = obscAccNo(itm['acc']);
      List<AuthTrans> chrtvals = new List();
      if (accnmes.contains(itm['acc'] + '*' + itm['mnth_req'])) {
        int pos = accnmes.indexOf(itm['acc'] + '*' + itm['mnth_req']);
        AuthTrans at = ref_chrtvals[pos];
        int n_amt = at.amt + double.parse(itm['trans_amt'].toString()).toInt();
        //print('New Amt'+n_amt.toString());
        ref_chrtvals.removeAt(pos);
        ref_chrtvals.insert(pos, new AuthTrans(at.acc, at.month, n_amt));
        chrtvals.add(ref_chrtvals[pos]);
        seriesList.removeAt(pos);
        seriesList.insert(
            pos,
            new charts.Series<AuthTrans, String>(
                id: sid,
                data: chrtvals,
                domainFn: (AuthTrans at, _) => at.month,
                measureFn: (AuthTrans at, _) => at.amt));
      } else {
        accnmes.add(itm['acc'] + '*' + itm['mnth_req']);
        ref_chrtvals.add(new AuthTrans(sid, getMonthName(itm['mnth_req']),
            double.parse(itm['trans_amt'].toString()).toInt().round()));
        chrtvals.add(ref_chrtvals.last);
        seriesList.add(new charts.Series<AuthTrans, String>(
            id: sid,
            data: chrtvals,
            domainFn: (AuthTrans at, _) => at.month,
            measureFn: (AuthTrans at, _) => at.amt));
      }
    }

    return AspectRatio(
        aspectRatio: 1.23,
        child: Padding(
          padding: EdgeInsets.all(5),
          child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.greenAccent
                    /*Color(0xff2c274c),
                  Color(0xff46426c),*/
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      const Text(
                        'Authenticated Transactions',
                        style: TextStyle(
                            //color: Colors.white,
                            fontFamily: 'Montserrat',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        u_dteController.text.isEmpty
                            ? 'For the Year ' + DateTime.now().year.toString()
                            : 'From ' +
                                u_dteController.text +
                                ' To ' +
                                l_dteController.text,
                        style: TextStyle(
                          //color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 32,
                      ),
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.only(right: 10.0, left: 6.0),
                        child: charts.BarChart(
                          seriesList,
                          animate: true,
                          barGroupingType: charts.BarGroupingType.grouped,
                          behaviors: [
                            new charts.SeriesLegend(
                              showMeasures: true,
                            )
                          ],
                        ),
                      )),
                    ],
                  )
                ],
              )),
        ));
  }

  Widget shwAnaFraud() {
    bool has_fraud = false;
    for (var itm in lstAnaChrt) {
      if (itm['approved'] == 0) {
        has_fraud = true;
        break;
      }
    }
    if (has_fraud) {
      List<charts.Series> seriesList =
          new List<charts.Series<AuthAppvl, String>>();
      List<String> accnmes = new List();
      List<AuthAppvl> ref_chrtvals = new List();
      for (var itm in lstAnaChrt) {
        //String sid = obscAccNo(itm['acc']);
        String sid = itm['approved'] == 1 ? 'Approved' : 'Rejected';
        List<AuthAppvl> chrtvals = new List();
        if (accnmes.contains(itm['acc'] + '*' + itm['approved'].toString())) {
          int pos =
              accnmes.indexOf(itm['acc'] + '*' + itm['approved'].toString());
          AuthAppvl at = ref_chrtvals[pos];
          //sid = at.status;
          int n_amt = at.amt +
              double.parse(itm['trans_amt'].toString()).toInt().round();
          //print('New Amt'+n_amt.toString());
          ref_chrtvals.removeAt(pos);
          ref_chrtvals.insert(pos, new AuthAppvl(at.acc, at.status, n_amt));
          chrtvals.add(ref_chrtvals[pos]);
          seriesList.removeAt(pos);
          seriesList.insert(
              pos,
              new charts.Series<AuthAppvl, String>(
                  id: sid,
                  seriesCategory: at.status,
                  seriesColor: at.status == 'Approved'
                      ? charts.MaterialPalette.blue.shadeDefault
                      : charts.MaterialPalette.red.shadeDefault,
                  data: chrtvals,
                  domainFn: (AuthAppvl at, _) => at.acc,
                  measureFn: (AuthAppvl at, _) => at.amt));
        } else {
          accnmes.add(itm['acc'] + '*' + itm['approved'].toString());
          ref_chrtvals.add(new AuthAppvl(
              obscAccNo(itm['acc']),
              itm['approved'] == 1 ? 'Approved' : 'Rejected',
              double.parse(itm['trans_amt'].toString()).toInt().round()));
          chrtvals.add(ref_chrtvals.last);
          seriesList.add(new charts.Series<AuthAppvl, String>(
              id: sid,
              seriesCategory: itm['approved'] == 1 ? 'Approved' : 'Rejected',
              seriesColor: itm['approved'] == 1
                  ? charts.MaterialPalette.blue.shadeDefault
                  : charts.MaterialPalette.red.shadeDefault,
              data: chrtvals,
              domainFn: (AuthAppvl at, _) => at.acc,
              measureFn: (AuthAppvl at, _) => at.amt));
        }
      }
      return AspectRatio(
          aspectRatio: 1.23,
          child: Padding(
            padding: EdgeInsets.all(5),
            child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.greenAccent
                      /*Color(0xff2c274c),
                  Color(0xff46426c),*/
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 10,
                        ),
                        const Text(
                          'Approved/Rejected Transactions',
                          style: TextStyle(
                              //color: Colors.white,
                              fontFamily: 'Montserrat',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          'For the Year ' + DateTime.now().year.toString(),
                          style: TextStyle(
                            //color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 32,
                        ),
                        Expanded(
                            child: Padding(
                          padding:
                              const EdgeInsets.only(right: 10.0, left: 6.0),
                          child: charts.BarChart(
                            seriesList,
                            animate: true,
                            barGroupingType: charts.BarGroupingType.stacked,
                            behaviors: [
                              new charts.SeriesLegend(
                                position: charts.BehaviorPosition.end,
                                showMeasures: true,
                              )
                            ],
                          ),
                        )),
                      ],
                    )
                  ],
                )),
          ));
    }
    return GradientCard(
        gradient: isDark ? Gradients.byDesign : Gradients.tameer,
        shadowColor: isDark
            ? Gradients.byDesign.colors.last.withOpacity(0.25)
            : Gradients.tameer.colors.last.withOpacity(0.25),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 10, top: 10, bottom: 10),
                    child: Text('None reported on your transactions',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700)),
                  ),
                  Image.asset(
                    'assets/fraud.png',
                    height: 60,
                    width: 60,
                  )
                ],
              ),
              Divider(
                height: 8,
                thickness: 1,
                color: Colors.white,
              ),
              ButtonBar(
                alignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                      child: Text(
                        'Show Local Activity',
                        style: TextStyle(
                            color: !isDark ? Colors.white : Colors.black),
                      ),
                      //color: !isDark ? Colors.white : Colors.black,
                      onPressed: () async {
                        //capFeedback();
                      },
                      style: OutlinedButton.styleFrom(
                          foregroundColor:
                              !isDark ? Colors.white : Colors.black,
                          side: BorderSide(
                              color: !isDark ? Colors.white : Colors.black,
                              style: BorderStyle.solid,
                              width: 0.8))),
                ],
              ),
            ],
          ),
        ));
  }

  Widget shwFraudBD() {
    List<Map> lstFtrans = new List<Map>();

    for (var itm in lstTrans) {
      if (itm['approved'] == 0) {
        lstFtrans.add(itm);
      }
    }

    if (lstFtrans.isNotEmpty) {
      return Container(
          height: MediaQuery.of(context).size.width * 0.60,
          child: ListView(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            children: [
              sectionHeader('Fraudulent Transactions'),
              for (var itm in lstFtrans) fraudList(itm)
            ],
          ));
    } else {
      return GradientCard(
          gradient: isDark ? Gradients.byDesign : Gradients.tameer,
          shadowColor: isDark
              ? Gradients.byDesign.colors.last.withOpacity(0.25)
              : Gradients.tameer.colors.last.withOpacity(0.25),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(left: 10, top: 10, bottom: 10),
                      child: Text(
                          u_dteController.text.isEmpty
                              ? 'No fraudulent transactions\non your accounts'
                              : 'No fraudulent transactions\non your accounts\nBetween ' +
                                  u_dteController.text +
                                  ' And\n' +
                                  l_dteController.text,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700)),
                    ),
                    Image.asset(
                      'assets/high_risk.png',
                      height: 60,
                      width: 60,
                    )
                  ],
                ),
                Divider(
                  height: 8,
                  thickness: 1,
                  color: Colors.white,
                ),
              ],
            ),
          ));
    }
  }

  Widget fraudList(var itm) {
    DateTime dt_curr =
        new DateFormat("yyyy-MM-dd hh:mm:ss").parse(itm['reg_on']);

    return Container(
        padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: ExpansionTileCard(
          leading: CircleAvatar(
            child: ClipOval(
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/loading.gif',
                image: itm['fi_logo'],
                fit: BoxFit.fill,
              ),
            ),
            backgroundColor: Colors.white,
          ),
          title: RichText(
            text: TextSpan(
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Montserrat',
                    fontSize: 16.0),
                children: [
                  TextSpan(text: 'Rejection of '),
                  TextSpan(
                      text: itm['curr_denom'] +
                          ' ' +
                          curr_format.format(itm['trans_amt']),
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  TextSpan(
                      text: ' on acc ' +
                          obscAccNo(itm['acc']) +
                          ' on ' +
                          DateFormat('dd MMM yyyy hh:mm:ss').format(dt_curr))
                ]),
          ),
          subtitle: Text('Tap to see more!'),
          children: [
            Divider(
              thickness: 2.0,
              height: 1.0,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  'Rejection Reason - ' + itm['reason'],
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2
                      .copyWith(fontSize: 16),
                ),
              ),
            )
          ],
        ));
  }

  Future<void> getFraudAggs() async {
    if (!db.isOpen) {
      db = await openDatabase(db_path);
    }
    if (u_dteController.text.isEmpty) {
      lstFtrans = await db.rawQuery(
          'SELECT acc,fi_logo,reason,count(reason) AS r_occ FROM transactions '
          'JOIN verifications ON transactions.id = verifications.tid WHERE approved = 0 GROUP BY acc');
    } else {
      lstFtrans = await db.rawQuery(
          'SELECT acc,fi_logo,reason,count(reason) AS r_occ FROM transactions '
          'JOIN verifications ON transactions.id = verifications.tid WHERE approved = 0 AND DATE(date_req) BETWEEN ? AND ? '
          'GROUP BY acc',
          [u_dteController.text, l_dteController.text]);
    }
    if (lstFtrans.isNotEmpty) {
      print('Fraud Agg - ' + jsonEncode(lstFtrans));
    }
    //await db.close();
  }

  Widget shwHotFraudList() {
    if (lstFtrans.isNotEmpty) {
      List<charts.Series> seriesList =
          new List<charts.Series<AuthTopFraud, String>>();

      for (var itm in lstFtrans) {
        String sid = itm['reason'];
        List<AuthTopFraud> chrtvals = new List();
        chrtvals.add(new AuthTopFraud(
            obscAccNo(itm['acc']), itm['reason'], itm['r_occ']));
        seriesList.add(new charts.Series<AuthTopFraud, String>(
            id: sid,
            seriesCategory: itm['reason'],
            seriesColor: charts.MaterialPalette.red.shadeDefault,
            data: chrtvals,
            domainFn: (AuthTopFraud at, _) => at.acc,
            measureFn: (AuthTopFraud at, _) => at.count));
      }
      return AspectRatio(
          aspectRatio: 1.23,
          child: Padding(
            padding: EdgeInsets.all(5),
            child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.greenAccent
                      /*Color(0xff2c274c),
                  Color(0xff46426c),*/
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 10,
                        ),
                        const Text(
                          'Top Fraud Reasons',
                          style: TextStyle(
                              //color: Colors.white,
                              fontFamily: 'Montserrat',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          u_dteController.text.isEmpty
                              ? 'For the Year ' + DateTime.now().year.toString()
                              : 'Between ' +
                                  u_dteController.text +
                                  ' And ' +
                                  l_dteController.text,
                          style: TextStyle(
                            //color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 32,
                        ),
                        Expanded(
                            child: Padding(
                          padding:
                              const EdgeInsets.only(right: 10.0, left: 6.0),
                          child: charts.BarChart(
                            seriesList,
                            animate: true,
                            barGroupingType: charts.BarGroupingType.stacked,
                            behaviors: [
                              new charts.SeriesLegend(
                                position: charts.BehaviorPosition.end,
                                showMeasures: true,
                              )
                            ],
                          ),
                        )),
                      ],
                    )
                  ],
                )),
          ));
    } else {
      return GradientCard(
          gradient: isDark ? Gradients.byDesign : Gradients.tameer,
          shadowColor: isDark
              ? Gradients.byDesign.colors.last.withOpacity(0.25)
              : Gradients.tameer.colors.last.withOpacity(0.25),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(left: 10, top: 10, bottom: 10),
                      child: Text(
                          u_dteController.text.isEmpty
                              ? 'No fraudulent transactions\non your accounts'
                              : 'No fraudulent transactions\non your accounts\nBetween ' +
                                  u_dteController.text +
                                  ' And\n' +
                                  l_dteController.text,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700)),
                    ),
                    Image.asset(
                      'assets/high_risk.png',
                      height: 60,
                      width: 60,
                    )
                  ],
                ),
                Divider(
                  height: 8,
                  thickness: 1,
                  color: Colors.white,
                ),
              ],
            ),
          ));
    }
  }

  /*LineChart(
  getanaChartData(),
  swapAnimationDuration:
  const Duration(milliseconds: 250),
  ),*/

  LineChartData getanaChartData() {
    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
        ),
        touchCallback: (LineTouchResponse touchResponse) {},
        handleBuiltInTouches: true,
      ),
      gridData: FlGridData(
        show: false,
      ),
      titlesData: FlTitlesData(
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          getTextStyles: (value) => const TextStyle(
            color: Color(0xff72719b),
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
          margin: 10,
          getTitles: (value) {
            switch (value.toInt()) {
              case 1:
                return 'Jan';
              case 2:
                return 'Feb';
              case 3:
                return 'Mar';
              case 4:
                return 'Apr';
              case 5:
                return 'May';
              case 6:
                return 'Jun';
              case 7:
                return 'Jul';
              case 8:
                return 'Aug';
              case 9:
                return 'Sep';
              case 10:
                return 'Oct';
              case 11:
                return 'Nov';
              case 12:
                return 'Dec';
            }
            return '';
          },
        ),
        leftTitles: SideTitles(
          showTitles: true,
          getTextStyles: (value) => const TextStyle(
            color: Color(0xff75729e),
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 8,
          ),
          getTitles: (value) {
            switch (value.toInt()) {
              case 0:
                return '00';
              case 1:
                return '5,000';
              case 2:
                return '10,000';
              case 3:
                return '15,000';
              case 4:
                return '20,000';
              case 6:
                return '3,000';
              case 7:
                return '3,500';
              case 8:
                return '4,000';
              case 9:
                return '4,500';
              case 10:
                return '5,000';
              case 11:
                return '5,500';
              case 12:
                return '6,000';
              case 13:
                return '6,500';
              case 14:
                return '7,000';
              case 15:
                return '7,500';
              case 16:
                return '8,000';
              case 17:
                return '8,500';
              case 18:
                return '9,000';
              case 19:
                return '9,500';
              case 20:
                return '10,500';
            }

            return '0';
          },
          /*getTitles: (value) {
            switch (value.toInt()) {
              case 1:
                return '1m';
              case 2:
                return '2m';
              case 3:
                return '3m';
              case 4:
                return '5m';
            }
            return '';
          },*/
          margin: 8,
          reservedSize: 30,
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(
            color: Color(0xff4e4965),
            width: 4,
          ),
          left: BorderSide(
            color: Colors.transparent,
          ),
          right: BorderSide(
            color: Colors.transparent,
          ),
          top: BorderSide(
            color: Colors.transparent,
          ),
        ),
      ),
      minX: 0,
      maxX: 14,
      maxY: 4,
      minY: 0,
      lineBarsData: linesBarData(),
    );
  }

  Future<List> loadAnaData() async {
    if (!db.isOpen) {
      db = await openDatabase(db_path);
    }
    if (u_dteController.text.isNotEmpty || l_dteController.text.isNotEmpty) {
      lstAnaChrt = await db.rawQuery(
          "SELECT fi_name,acc,strftime('%m',DATE(date_req)) AS mnth_req,trans_amt,approved,reason,verifications.reg_on FROM transactions "
          "JOIN verifications ON transactions.id = verifications.tid WHERE DATE(date_req) BETWEEN ? AND ? ORDER BY date_req ASC",
          [u_dteController.text, l_dteController.text]);
    } else {
      lstAnaChrt = await db.rawQuery(
          "SELECT fi_name,acc,strftime('%m',DATE(date_req)) AS mnth_req,trans_amt,approved,reason FROM transactions "
          "JOIN verifications ON transactions.id = verifications.tid WHERE DATE(date_req) LIKE ? ORDER BY date_req ASC",
          [DateTime.now().year.toString() + '%']);
    }
    print('Ana Data' + jsonEncode(lstAnaChrt));
    //await db.close();
    return lstAnaChrt;
  }

  Future<List> loadFraudAnaData() async {
    /*Database db = await openDatabase(db_path);
    lstAnaFChrt = await db.rawQuery('SELECT fi_name,acc');*/
  }

  int gen_int(int min, int max) {
    final _random = new Random();

    return min + _random.nextInt(max - min);
  }

  List<LineChartBarData> linesBarData() {
    List<FlSpot> spot_vals = new List();

    for (var itm in lstAnaChrt) {
      double v_amt = double.parse(((itm['trans_amt'] / 10000)).toString());

      spot_vals.add(FlSpot(double.parse(itm['mnth_req'].toString()),
          double.parse(v_amt.toStringAsFixed(0))));

      print('Month ' + double.parse(itm['mnth_req'].toString()).toString());

      print('Amount ' + v_amt.toStringAsFixed(0));

      /*double mnth = gen_int(1, 11).toDouble();

      spot_vals.add(FlSpot(mnth, gen_int(1, 5).toDouble()));

      */
    }

    LineChartBarData lineChartBarData1 = LineChartBarData(
      spots: spot_vals,
      isCurved: true,
      colors: [
        const Color(0xff4af699),
      ],
      barWidth: 8,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: false,
      ),
      belowBarData: BarAreaData(
        show: false,
      ),
    );
    return [lineChartBarData1];
  }

  List<LineChartBarData> linesBarData1() {
    final LineChartBarData lineChartBarData1 = LineChartBarData(
      spots: [
        FlSpot(1, 1),
        FlSpot(3, 1.5),
        FlSpot(5, 1.4),
        FlSpot(7, 3.4),
        FlSpot(10, 2),
        FlSpot(12, 2.2),
        FlSpot(13, 1.8),
      ],
      isCurved: true,
      colors: [
        const Color(0xff4af699),
      ],
      barWidth: 8,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: false,
      ),
      belowBarData: BarAreaData(
        show: false,
      ),
    );
    final LineChartBarData lineChartBarData2 = LineChartBarData(
      spots: [
        FlSpot(1, 1),
        FlSpot(3, 2.8),
        FlSpot(7, 1.2),
        FlSpot(10, 2.8),
        FlSpot(12, 2.6),
        FlSpot(13, 3.9),
      ],
      isCurved: true,
      colors: [
        const Color(0xffaa4cfc),
      ],
      barWidth: 8,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: false,
      ),
      belowBarData: BarAreaData(show: false, colors: [
        const Color(0x00aa4cfc),
      ]),
    );
    final LineChartBarData lineChartBarData3 = LineChartBarData(
      spots: [
        FlSpot(1, 2.8),
        FlSpot(3, 1.9),
        FlSpot(6, 3),
        FlSpot(10, 1.3),
        FlSpot(13, 2.5),
      ],
      isCurved: true,
      colors: const [
        Color(0xff27b6fc),
      ],
      barWidth: 8,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: false,
      ),
      belowBarData: BarAreaData(
        show: false,
      ),
    );
    return [
      lineChartBarData1,
      lineChartBarData2,
      lineChartBarData3,
    ];
  }

  Widget Accs(var itm) {
    //print(jsonEncode(itm));
    String acc_no = obscAccNo(itm['acc_no']);
    return GradientCard(
        gradient: isDark
            ? itm['del'] == 0
                ? Gradients.cosmicFusion
                : Gradients.haze
            : itm['del'] == 0
                ? Gradients.rainbowBlue
                : Gradients.deepSpace,
        shadowColor: isDark
            ? Gradients.cosmicFusion.colors.last.withOpacity(0.25)
            : Gradients.rainbowBlue.colors.last.withOpacity(0.25),
        elevation: 8,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                //margin: EdgeInsets.symmetric(vertical: 14),
                //alignment: FractionalOffset.topLeft,
                ListTile(
                  leading: CircleAvatar(
                    child: ClipOval(
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/loading.gif',
                        image: itm['f_logo'],
                        fit: BoxFit.fill,
                      ),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  title: Text(
                    itm['f_nme'],
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                        color: !isDark
                            ? itm['del'] == 0
                                ? Colors.black
                                : Colors.white
                            : itm['del'] == 0
                                ? Colors.white
                                : Colors.black),
                  ),
                  subtitle: Text(
                    acc_no,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Montserrat',
                        color: !isDark
                            ? itm['del'] == 0
                                ? Colors.black
                                : Colors.white
                            : itm['del'] == 0
                                ? Colors.white
                                : Colors.black),
                  ),
                ),
                Divider(
                  height: 10,
                  thickness: 1,
                  color: Colors.white,
                ),
                ButtonBar(
                  alignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      child: Text(
                        'Set Auto Approval',
                        style: TextStyle(
                            color: !isDark ? Colors.white : Colors.black),
                      ),
                      //color: !isDark ? Colors.white : Colors.black,
                      onPressed: () async {
                        final LocalAuthentication auth = LocalAuthentication();
                        try {
                          bool didAuthenticate =
                              await auth.authenticateWithBiometrics(
                                  localizedReason:
                                      'Please authenticate to Continue',
                                  useErrorDialogs: false);
                          if (didAuthenticate) {
                            itm['del'] == 1
                                ? showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return CupertinoAlertDialog(
                                        title: Text(
                                          'Accounts',
                                          style: TextStyle(
                                              fontFamily: 'Montserrat'),
                                        ),
                                        content: Text(
                                            'You need to Activate this Account first',
                                            style: TextStyle(
                                                fontFamily: 'Montserrat')),
                                        actions: [
                                          CupertinoDialogAction(
                                            child: Text('Ok',
                                                style: TextStyle(
                                                    fontFamily: 'Montserrat')),
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                          )
                                        ],
                                      );
                                    })
                                : shwAccDetails(itm);
                          }
                        } on PlatformException catch (e) {
                          if (e.code == auth_error.permanentlyLockedOut) {
                            custMsg('Authentication',
                                'VerID Locked awaiting PIN/Password/Pattern Input');
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                          foregroundColor:
                              !isDark ? Colors.white : Colors.black,
                          side: BorderSide(
                              color: !isDark ? Colors.white : Colors.black,
                              style: BorderStyle.solid,
                              width: 0.8)),
                    ),
                    OutlinedButton(
                        child: Text(
                          itm['del'] == 0
                              ? 'Deactivate Account'
                              : 'Reactivate Account',
                          style: TextStyle(
                              color: !isDark ? Colors.white : Colors.black),
                        ),
                        //color: !isDark ? Colors.white : Colors.black,
                        onPressed: () {
                          final LocalAuthentication auth =
                              LocalAuthentication();
                          showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return CupertinoAlertDialog(
                                  title: Text(
                                    itm['del'] == 0
                                        ? 'Deactivate Account'
                                        : 'Reactivate Account',
                                    style: TextStyle(fontFamily: 'Montserrat'),
                                  ),
                                  content: Text(
                                      itm['del'] == 0
                                          ? 'Do you wish to deactivate\n'
                                          : 'Do you wish to Reactivate\n' +
                                              itm['f_nme'] +
                                              ' Account\n' +
                                              acc_no,
                                      style:
                                          TextStyle(fontFamily: 'Montserrat')),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: Text('Yes',
                                          style: TextStyle(
                                              fontFamily: 'Montserrat')),
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        try {
                                          bool didAuthenticate = await auth
                                              .authenticateWithBiometrics(
                                                  localizedReason:
                                                      'Please authenticate to Continue',
                                                  useErrorDialogs: false);

                                          if (didAuthenticate) {
                                            itm['del'] == 0
                                                ? delAcc(itm, 1)
                                                : delAcc(itm, 0);
                                          } else {
                                            custMsg('Authentication',
                                                'Authentication Failure');
                                          }
                                        } on PlatformException catch (e) {
                                          if (e.code ==
                                              auth_error.permanentlyLockedOut) {
                                            custMsg('Authentication',
                                                'VerID Locked awaiting PIN/Password/Pattern Input');
                                          }
                                        }
                                      },
                                    ),
                                    CupertinoDialogAction(
                                      child: Text('No',
                                          style: TextStyle(
                                              fontFamily: 'Montserrat')),
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                    )
                                  ],
                                );
                              });
                        },
                        style: OutlinedButton.styleFrom(
                            foregroundColor:
                                !isDark ? Colors.white : Colors.black,
                            side: BorderSide(
                                color: !isDark ? Colors.white : Colors.black,
                                style: BorderStyle.solid,
                                width: 0.8))),
                    //borderSide:
                  ],
                ),
              ]),
        ));
  }

  Widget noAccs() {
    return GradientCard(
        gradient: isDark ? Gradients.cosmicFusion : Gradients.rainbowBlue,
        shadowColor: isDark
            ? Gradients.cosmicFusion.colors.last.withOpacity(0.25)
            : Gradients.rainbowBlue.colors.last.withOpacity(0.25),
        elevation: 8,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'No Data to Show',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                      color: Colors.black),
                ),
              ]),
        ));
  }

  Future<void> regAccDialog() async {
    bool connAvail = await valConn();
    if (connAvail) {
      //Load the List of Financial Institutions
      await loadBanks();
      var bnkLogo = new List<String>();
      var bnkList = new List<String>();
      var bnkids = new List<String>();
      for (var bnk in lstBanks) {
        bnkLogo.add(bnk['logo']);
        bnkList.add(bnk['facility']);
        bnkids.add(bnk['id']);
      }
      showDialog(
          context: this.context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            final _formKey = GlobalKey<FormState>();
            return AlertDialog(
              title: Text(
                'Add Account',
                style: TextStyle(fontFamily: 'Montserrat'),
              ),
              content: Stack(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField(
                          decoration: InputDecoration(
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Color(0xFF34eb4f), width: 1.0)),
                              border: OutlineInputBorder(),
                              //errorText: valTel(),
                              labelText: "Select Your Bank"),
                          icon: Icon(LineIcons.chevron_circle_down),
                          iconSize: 28,
                          onChanged: (String selVal) {
                            bankController.text = selVal;
                            bank_logo =
                                bnkLogo[bnkList.indexOf(selVal)].toString();
                            fid = bnkids[bnkList.indexOf(selVal)].toString();
                            print('Selected Bank ' + selVal);
                            print('Bank Logo ' + bank_logo);
                            print('FID ' + fid);
                          },
                          items: bnkList
                              .map<DropdownMenuItem<String>>((String val) {
                            return DropdownMenuItem<String>(
                              value: val,
                              child: Text(val,
                                  style: TextStyle(fontFamily: 'Montserrat')),
                            );
                          }).toList(),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        TextField(
                            controller: accController,
                            maxLength: 20,
                            decoration: InputDecoration(
                                focusedBorder: const OutlineInputBorder(
                                    borderSide: const BorderSide(
                                        color: Color(0xFF34eb4f), width: 1.0)),
                                border: OutlineInputBorder(),
                                //errorText: valTel(),
                                labelText: "Enter Your Account Number"),
                            keyboardType: TextInputType.number),
                        SizedBox(
                          height: 10,
                        ),
                        TextField(
                            controller: accDescController,
                            maxLength: 20,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                                focusedBorder: const OutlineInputBorder(
                                    borderSide: const BorderSide(
                                        color: Color(0xFF34eb4f), width: 1.0)),
                                border: OutlineInputBorder(),
                                //errorText: valTel(),
                                labelText: "Enter Account Description"),
                            keyboardType: TextInputType.name),
                        SizedBox(
                          height: 10,
                        ),
                        GradientButton(
                          child: Text('Link Account'),
                          callback: () {
                            regAcc(context);
                          },
                          gradient: isDark
                              ? Gradients.cosmicFusion
                              : Gradients.rainbowBlue,
                          shadowColor: isDark
                              ? Gradients.cosmicFusion.colors.last
                                  .withOpacity(0.25)
                              : Gradients.rainbowBlue.colors.last
                                  .withOpacity(0.25),
                          increaseHeightBy: 10,
                          increaseWidthBy: double.maxFinite,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        GradientButton(
                          child: Text('Close'),
                          callback: () {
                            Navigator.pop(context);
                          },
                          gradient: Gradients.backToFuture,
                          shadowColor: Gradients.backToFuture.colors.last
                              .withOpacity(0.25),
                          increaseHeightBy: 10,
                          increaseWidthBy: double.maxFinite,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          });
    } else {
      noConnMsg();
    }
  }

  Future<void> loadBanks() async {
    pr = ProgressDialog(this.context,
        type: ProgressDialogType.Normal, isDismissible: false);

    pr.style(message: 'Loading Banks');

    await pr.show();

    var response = await http.post(url, headers: {
      'x-task': 'getBanks',
      'x-API-KEY': 'P0oG6pnwuI>t*gQ*SehXqEp#x`5#Y',
    });

    debugPrint("response_getbanks - " + response.body);

    pr.hide();

    if (response.body != '0') {
      lstBanks = List.from(jsonDecode(response.body));
    } else {
      custMsg('Getting Banks', 'No Banks Registered');
    }
  }

  Future<bool> valConn() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      //Check for connection to the blueviolet network
      try {
        final result = await InternetAddress.lookup('blueviolet.tech');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          //Internet present continue to login
          return true;
        }
      } on SocketException catch (_) {
        //Error suspend login process
      }
    }
    return false;
  }

  void noConnMsg() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext cxt) {
          return CupertinoAlertDialog(
            title: Text(
              'Sign In',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
            content: Text(
                'Unable to Sign In\nNo connection to Blue violet Network',
                style: TextStyle(fontFamily: 'Montserrat')),
            actions: [
              CupertinoDialogAction(
                child: Text('Ok', style: TextStyle(fontFamily: 'Montserrat')),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ],
          );
        });
  }

  void custMsg(String title, String msg) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(
              title,
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
            content: Text(msg, style: TextStyle(fontFamily: 'Montserrat')),
            actions: [
              CupertinoDialogAction(
                child: Text('Ok', style: TextStyle(fontFamily: 'Montserrat')),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ],
          );
        });
  }

  void shwAlertMsg(bool isError, String title, String msg) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            //title: Text('Congratulations'),
            //content: Text('Welcome to the Smart Shopper Family'),
            content: new Container(
              //alignment: Alignment(0.0,0.0),
              child: Column(
                children: <Widget>[
                  new Container(
                    child: Icon(
                      isError
                          ? CupertinoIcons.exclamationmark_circle
                          : CupertinoIcons.info,
                      size: 50,
                      color: isError ? Color(0xFFc70a0a) : Color(0xFF23b83c),
                    ),
                    margin: EdgeInsets.only(bottom: 10),
                    alignment: Alignment.center,
                  ),
                  new Container(
                    child: Text(
                      title,
                      style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                    margin: EdgeInsets.only(bottom: 10),
                  ),
                  Text(
                    msg,
                    style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.grey),
                  )
                ],
              ),
            ),
            actions: <Widget>[
              CupertinoButton(
                onPressed: () {
                  //Close alert dialog
                  Navigator.of(context).pop();
                  getTotalAmt();
                },
                child: Text(
                  'Ok',
                  style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.normal),
                ),
                color: isError ? Color(0xFFc70a0a) : Color(0xFF23b83c),
                borderRadius: BorderRadius.circular(0),
              ),
            ],
          );
        });
  }

  Future<void> regAcc(BuildContext context) async {
    if (valAccData()) {
      if (!db.isOpen) {
        db = await openDatabase(db_path);
      }

      List<Map> lstRslt = await db.rawQuery(
          'SELECT * FROM my_accs WHERE f_nme = ? AND acc_no = ?',
          [bankController.text, accController.text]);

      //db.close();

      if (lstRslt.isEmpty) {
        //Close the Account Linkage Dialog
        Navigator.pop(context);

        if (pr == null) {
          pr = ProgressDialog(this.context,
              type: ProgressDialogType.Normal, isDismissible: false);
        }
        pr.style(message: 'Linking with Network...');

        await pr.show();

        await regAccCloud();
      } else {
        custMsg(
            'Validation',
            'Account ' +
                accController.text +
                ' of ' +
                bankController.text +
                ' Already Linked');
      }
    }
  }

  bool valAccData() {
    if (bankController.text.length > 0) {
      Pattern pattern = r'^[0-9]{9,18}';
      RegExp regex = new RegExp(pattern);
      if (regex.hasMatch(accController.text)) {
        pattern = r'^[a-zA-Z]';
        regex = new RegExp(pattern);
        if (regex.hasMatch(accDescController.text)) {
          return true;
        } else {
          custMsg(
              'Validation',
              'Kindly enter a Valid Account Description for ' +
                  bankController.text +
                  ' Account Number - ' +
                  accController.text);
        }
      } else {
        custMsg('Validation',
            'Kindly enter a Valid ' + bankController.text + ' Account Number');
      }
    } else {
      custMsg('Validation', 'Kindly Select the Bank your Account is in');
    }
    return false;
  }

  regAccCloud() async {
    final storage = FlutterSecureStorage();
    String uuid = await storage.read(key: 'usrid');
    String tel = await storage.read(key: 'usr_tel');

    pr.update(message: 'Verifying Ownership');

    var response = await http.post(url, headers: {
      'x-task': 'valAcc',
      'x-API-KEY': 'P0oG6pnwuI>t*gQ*SehXqEp#x`5#Y',
      'x-FID': fid,
      'x-ACC': accController.text,
      'x-TEL': tel,
      'x-USR': uuid
    });

    debugPrint("response_valAcc - " + response.body);

    pr.hide();

    if (response.body != '0') {
      //Enter OTP/ATM PIN
      showOTPDialog(response.body);
    } else {
      custMsg('Verifying Ownership', 'Unable to Verify Ownership');
    }
  }

  void showOTPDialog(String pin) {
    // ignore: close_sinks
    StreamController<ErrorAnimationType> errorController =
        StreamController<ErrorAnimationType>();
    showDialog(
        context: this.context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Verification'),
            content: Stack(children: <Widget>[
              Divider(
                thickness: 1.0,
                height: 1.0,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 6,
                  ),
                  Text('Enter 4 Digit Code Sent by ' + bankController.text,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat')),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                      child: PinCodeTextField(
                    appContext: context,
                    length: 4,
                    obscureText: false,
                    animationType: AnimationType.fade,
                    animationDuration: Duration(milliseconds: 300),
                    backgroundColor: Colors.white,
                    enableActiveFill: true,
                    errorAnimationController: errorController,
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(5),
                      fieldHeight: 50,
                      fieldWidth: 40,
                      activeFillColor: hasError ? Colors.orange : Colors.white,
                    ),
                    onChanged: (s) async {
                      setState(() {
                        hasError = false;
                      });
                    },
                    onCompleted: (v) async {
                      print("Completed");

                      if (v == pin) {
                        Navigator.pop(context);
                        //Link the Account
                        if (!db.isOpen) {
                          db = await openDatabase(db_path);
                        }

                        int insrt_val = await db.rawInsert(
                            'INSERT INTO my_accs (fid,f_nme,f_logo,acc_no,acc_desc) VALUES(?,?,?,?,?)',
                            [
                              int.parse(fid),
                              bankController.text,
                              bank_logo,
                              accController.text,
                              accDescController.text
                            ]);

                        //db.close();

                        if (insrt_val > 0) {
                          showToast(
                              false,
                              bankController.text +
                                  ' Account ' +
                                  accController.text +
                                  ' Linked Successfully');

                          /*custMsg('Account Linkage',
                              'Kindly input the Signature used to Open the Account');*/

                          //Capture the Authorized Account Signature
                          showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return CupertinoAlertDialog(
                                  title: Text(
                                    'Signature Capture',
                                    style: TextStyle(fontFamily: 'Montserrat'),
                                  ),
                                  content: Text(
                                      'For additional Security we request your Signature to authorize all transactions',
                                      style:
                                          TextStyle(fontFamily: 'Montserrat')),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: Text('Ok',
                                          style: TextStyle(
                                              fontFamily: 'Montserrat')),
                                      onPressed: () async {
                                        bool connAvail = await valConn();
                                        if (connAvail) {
                                          Navigator.pop(context);
                                          //Capture Signature
                                          await captureSignature();
                                        } else {
                                          custMsg('Network Connection',
                                              'No Internet Connection ');
                                        }
                                      },
                                    )
                                  ],
                                );
                              });

                          //Link Acc to Cloud
                          linkAcctoBVNetwork();

                          final storage = FlutterSecureStorage();

                          if (!await storage.containsKey(key: 'key_public')) {
                            genKeys(storage);
                          }

                          //Update the List
                          if (!db.isOpen) {
                            db = await openDatabase(db_path);
                          }

                          lstAccs = await db.rawQuery('SELECT * FROM my_accs');

                          //db.close();

                          setState(() {
                            //Update the UI
                          });
                        } else {
                          custMsg('Account Linkage',
                              'Error, Account Linkage Failed');
                        }
                      } else {
                        errorController.add(ErrorAnimationType
                            .shake); // Triggering error shake animation
                        setState(() {
                          hasError = true;
                        });
                      }
                    },
                  )),
                  SizedBox(
                    height: 10,
                  ),
                  GradientButton(
                    child: Text('Close'),
                    callback: () {
                      Navigator.pop(context);
                    },
                    gradient: Gradients.backToFuture,
                    shadowColor:
                        Gradients.backToFuture.colors.last.withOpacity(0.25),
                    increaseHeightBy: 10,
                    increaseWidthBy: double.maxFinite,
                  )
                ],
              )
            ]),
          );
        });
  }

  Future<void> linkAcctoBVNetwork() async {
    if (pr == null) {
      pr = ProgressDialog(this.context,
          type: ProgressDialogType.Normal, isDismissible: false);
    }
    pr.style(message: 'Linking for Authentication...');

    await pr.show();

    final storage = FlutterSecureStorage();
    String uuid = await storage.read(key: 'usrid');
    String tel = await storage.read(key: 'usr_tel');

    var response = await http.post(url, headers: {
      'x-task': 'regAcc',
      'x-API-KEY': 'P0oG6pnwuI>t*gQ*SehXqEp#x`5#Y',
      'x-FID': fid,
      'x-ACC': accController.text,
      'x-TEL': tel,
      'x-USR': uuid
    });

    pr.hide();

    print('link_response ' + response.body);

    if (response.body != 'x') {
      if (response.body == '1') {
        custMsg('Account Linkage',
            'Account Successfully Linked for Authentication');
      }
    } else {
      custMsg('Account Linkage', 'Account already Linked');
    }

    if (!await storage.containsKey(key: 'key_public')) {
      genKeys(storage);
    }
  }

  Future<pc_api.AsymmetricKeyPair<pc_api.PublicKey, pc_api.PrivateKey>>
      computeRSAKeyPair(pc_api.SecureRandom secureRandom) async {
    return await compute(getRsaKeyPair, secureRandom);
  }

  pc_api.SecureRandom getSecureRandom() {
    final secureRandom = FortunaRandom();

    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(255));
    }
    secureRandom.seed(pc_api.KeyParameter(Uint8List.fromList(seeds)));

    return secureRandom;
  }

  static pc_api.AsymmetricKeyPair<pc_api.PublicKey, pc_api.PrivateKey>
      getRsaKeyPair(pc_api.SecureRandom secureRandom) {
    var rsapars = new RSAKeyGeneratorParameters(
        BigInt.parse('337757'), 4096, 10); //337757 96
    var params = new pc_api.ParametersWithRandom(rsapars, secureRandom);
    var keyGenerator = new RSAKeyGenerator();
    keyGenerator.init(params);
    return keyGenerator.generateKeyPair();
  }

  String encodePublicKeyToPemPKCS1(RSAPublicKey publicKey) {
    var topLevel = new ASN1Sequence();

    topLevel.add(ASN1Integer(publicKey.modulus));
    topLevel.add(ASN1Integer(publicKey.exponent));

    var dataBase64 = base64.encode(topLevel.encodedBytes);
    return """-----BEGIN PUBLIC KEY-----\r\n$dataBase64\r\n-----END PUBLIC KEY-----""";
  }

  String encodePrivateKeyToPemPKCS1(RSAPrivateKey privateKey) {
    var topLevel = new ASN1Sequence();

    var version = ASN1Integer(BigInt.from(0));
    var modulus = ASN1Integer(privateKey.n);
    var publicExponent = ASN1Integer(privateKey.exponent);
    var privateExponent = ASN1Integer(privateKey.privateExponent);
    var p = ASN1Integer(privateKey.p);
    var q = ASN1Integer(privateKey.q);
    var dP = privateKey.privateExponent % (privateKey.p - BigInt.from(1));
    var exp1 = ASN1Integer(dP);
    var dQ = privateKey.privateExponent % (privateKey.q - BigInt.from(1));
    var exp2 = ASN1Integer(dQ);
    var iQ = privateKey.q.modInverse(privateKey.p);
    var co = ASN1Integer(iQ);

    topLevel.add(version);
    topLevel.add(modulus);
    topLevel.add(publicExponent);
    topLevel.add(privateExponent);
    topLevel.add(p);
    topLevel.add(q);
    topLevel.add(exp1);
    topLevel.add(exp2);
    topLevel.add(co);

    var dataBase64 = base64.encode(topLevel.encodedBytes);

    return """-----BEGIN PRIVATE KEY-----\r\n$dataBase64\r\n-----END PRIVATE KEY-----""";
  }

  Future<void> bkupKeys(String pub_key, String prv_key, String uuid) async {
    var response = await http.post(url, headers: {
      'x-task': 'regPKeys',
      'x-API-KEY': 'P0oG6pnwuI>t*gQ*SehXqEp#x`5#Y',
      'x-USR': uuid
    }, body: {
      'PUBKEY': pub_key,
      'PRKEY': prv_key
    });

    pr.hide();

    print('regkeys_response ' + response.body);

    if (response.body == '1') {
      showToast(false, 'Auth Keys Backup Successful');
    }
  }

  void showToast(bool isError, String msg) {
    Fluttertoast.showToast(
        msg: msg,
        toastLength: isError ? Toast.LENGTH_SHORT : Toast.LENGTH_SHORT,
        gravity: isError ? ToastGravity.CENTER : ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: isError ? Colors.red : Colors.white,
        textColor: Colors.black,
        fontSize: 16.0);
  }

  void genKeys(final storage) async {
    pr = ProgressDialog(this.context,
        type: ProgressDialogType.Normal, isDismissible: false);

    pr.style(message: 'Generating Auth Keys');

    await pr.show();

    //Show the Data

    final pair = await computeRSAKeyPair(getSecureRandom());

    String pub_key = encodePublicKeyToPemPKCS1(pair.publicKey);

    String prv_key = encodePrivateKeyToPemPKCS1(pair.privateKey);

    String uuid = await storage.read(key: 'usrid');

    await storage.write(key: 'key_public', value: pub_key);

    await storage.write(key: 'key_private', value: prv_key);

    await bkupKeys(pub_key, prv_key, uuid);

    print('Public Key - ' + pub_key);
    print('Private Key - ' + prv_key);

    pr.hide();
  }

  Future<void> shwAccDetails(var itm) async {
    String acc_no = itm['acc_no'].toString().substring(0, 4) +
        itm['acc_no']
            .toString()
            .substring(4, itm['acc_no'].toString().length - 3)
            .replaceAll(RegExp(r"."), "*") +
        itm['acc_no'].toString().substring(itm['acc_no'].toString().length - 3);

    String dur = '1 Month';
    String trans_type = 'Online Transactions';

    //Load the List of Financial Institutions
    await loadBanks();

    //Extract the fid from the list
    for (var b_itm in lstBanks) {
      if (b_itm['facility'] == itm['f_nme']) {
        fid = b_itm['id'];
        break;
      }
    }

    //Check if Account has been registered before
    if (!db.isOpen) {
      db = await openDatabase(db_path);
    }

    await tm.TimeMachine.initialize({'rootBundle': rootBundle});

    List<Map> lstRslts = await db.rawQuery(
        'SELECT * FROM accs_auto_trans WHERE aid = ?',
        [int.parse(itm['id'].toString())]);

    //db.close();

    if (lstRslts.isNotEmpty) {
      amtController.text = lstRslts[0]['amt_limit'].toString();
      tm.LocalDateTime t1 = tm.LocalDateTime.dateTime(
          DateTime.parse(lstRslts[0]['dur'].toString()));
      tm.LocalDateTime t2 = tm.LocalDateTime.dateTime(
          DateTime.parse(lstRslts[0]['reg_on'].toString().split(' ')[0]));
      int p = t1.periodSince(t2).months;

      print('Duration in Months ' +
          p.toString() +
          ' ' +
          lstRslts[0]['dur'].toString() +
          ' ' +
          lstRslts[0]['reg_on'].toString());

      if (p == 1) {
        dur = '1 Month';
      } else if (p == 3) {
        dur = '3 Months';
      } else if (p == 6) {
        dur = '6 Months';
      } else {
        dur = '12 Months';
      }
    } else {
      amtController.text = '';
    }

    showDialog(
        context: this.context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final _formKey = GlobalKey<FormState>();
          return AlertDialog(
            title: Text(
              itm['f_nme'] + ' Account  ' + acc_no,
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
            content: Stack(
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                          controller: amtController,
                          maxLength: 6,
                          decoration: InputDecoration(
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Color(0xFF34eb4f), width: 1.0)),
                              border: OutlineInputBorder(),
                              //errorText: valTel(),
                              labelText: "Enter Transaction Amount Limit"),
                          keyboardType: TextInputType.number),
                      SizedBox(
                        height: 10,
                      ),
                      DropdownButtonFormField(
                        decoration: InputDecoration(
                            focusedBorder: const OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Color(0xFF34eb4f), width: 1.0)),
                            border: OutlineInputBorder(),
                            //errorText: valTel(),
                            labelText: "Select Duration"),
                        icon: Icon(LineIcons.chevron_circle_down),
                        iconSize: 28,
                        onChanged: (String selVal) {
                          dur = selVal;
                        },
                        items: ["1 Month", "3 Months", "6 Months", "12 Months"]
                            .map<DropdownMenuItem<String>>((String val) {
                          return DropdownMenuItem<String>(
                            value: val,
                            child: Text(val,
                                style: TextStyle(fontFamily: 'Montserrat')),
                          );
                        }).toList(),
                        value: lstRslts.isNotEmpty ? dur : '1 Month',
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      DropdownButtonFormField(
                        decoration: InputDecoration(
                            focusedBorder: const OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Color(0xFF34eb4f), width: 1.0)),
                            border: OutlineInputBorder(),
                            //errorText: valTel(),
                            labelText: "Select Transactions for Approval"),
                        icon: Icon(LineIcons.chevron_circle_down),
                        iconSize: 28,
                        onChanged: (String selVal) {
                          trans_type = selVal;
                        },
                        items: [
                          "Online Transactions",
                          "Standing Order",
                          "Direct Debit"
                        ].map<DropdownMenuItem<String>>((String val) {
                          return DropdownMenuItem<String>(
                            value: val,
                            child: Text(val,
                                style: TextStyle(fontFamily: 'Montserrat')),
                          );
                        }).toList(),
                        value: lstRslts.isNotEmpty
                            ? trans_type
                            : "Online Transactions",
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      GradientButton(
                        child: Text(lstRslts.isEmpty
                            ? 'Set Auto Approval'
                            : 'Update Auto Approval'),
                        callback: () {
                          lstRslts.isEmpty
                              ? regAutoApprvl(context, dur, trans_type,
                                  int.parse(itm['id'].toString()))
                              : udteAutoApprvl(context, dur, trans_type,
                                  int.parse(itm['id'].toString()));
                        },
                        gradient: isDark
                            ? Gradients.cosmicFusion
                            : Gradients.rainbowBlue,
                        shadowColor: isDark
                            ? Gradients.cosmicFusion.colors.last
                                .withOpacity(0.25)
                            : Gradients.rainbowBlue.colors.last
                                .withOpacity(0.25),
                        increaseHeightBy: 10,
                        increaseWidthBy: double.maxFinite,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      GradientButton(
                        child: Text('Close'),
                        callback: () {
                          Navigator.pop(context);
                        },
                        gradient: Gradients.backToFuture,
                        shadowColor: Gradients.backToFuture.colors.last
                            .withOpacity(0.25),
                        increaseHeightBy: 10,
                        increaseWidthBy: double.maxFinite,
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }

  Future<void> regAutoApprvl(
      BuildContext context, String dur, String trans_type, int aid) async {
    if (valApprvlData(dur, trans_type)) {
      dur = dur.replaceAll('Month', '');
      dur = dur.replaceAll('s', '');
      dur = dur.trim();
      DateTime dtedue;
      DateFormat formatter = DateFormat('yyyy-MM-dd');

      if (int.parse(dur) < 12) {
        dtedue = DateTime(DateTime.now().year,
            DateTime.now().month + int.parse(dur), DateTime.now().day);
      } else {
        dtedue = DateTime(
            DateTime.now().year + 1, DateTime.now().month, DateTime.now().day);
      }

      //print('Auto_Apprvl_Data - '+aid.toString()+ ' , '+formatter.format(dtedue)+' , '+ amtController.text+' , '+DateTime.now().toString());

      if (!db.isOpen) {
        db = await openDatabase(db_path);
      }

      int insrt_val = await db.rawInsert(
          'INSERT INTO accs_auto_trans (aid,dur,amt_limit,reg_on) VALUES(?,?,?,?)',
          [
            aid,
            formatter.format(dtedue),
            int.parse(amtController.text),
            DateTime.now().toString()
          ]);

      //db.close();

      if (insrt_val > 0) {
        Navigator.pop(context);
        //Sync with Cloud Database
        regApprvltoCloud(insrt_val);
      }
    }
  }

  bool valApprvlData(String dur, String trans_type) {
    if (amtController.text.length > 0) {
      Pattern pattern = r'^[0-9]';
      RegExp regex = new RegExp(pattern);
      if (regex.hasMatch(amtController.text)) {
        if (dur != null) {
          if (trans_type != null) {
            return true;
          } else {
            custMsg(
                'Validation', 'Kindly select a Transaction type to monitor ');
          }
        } else {}
      } else {
        custMsg('Validation', 'Kindly enter a Valid Limit Amount');
      }
    } else {
      custMsg('Validation', 'Kindly Enter a Limit Amount');
    }
    return false;
  }

  udteAutoApprvl(
      BuildContext context, String dur, String trans_type, int aid) async {
    if (valApprvlData(dur, trans_type)) {
      dur = dur.replaceAll('Month', '');
      dur = dur.replaceAll('s', '');
      dur = dur.trim();
      DateTime dtedue;
      DateFormat formatter = DateFormat('yyyy-MM-dd');

      if (int.parse(dur) < 12) {
        dtedue = DateTime(DateTime.now().year,
            DateTime.now().month + int.parse(dur), DateTime.now().day);
      } else {
        dtedue = DateTime(
            DateTime.now().year + 1, DateTime.now().month, DateTime.now().day);
      }

      //print('Auto_Apprvl_Data - '+aid.toString()+ ' , '+formatter.format(dtedue)+' , '+ amtController.text+' , '+DateTime.now().toString());

      if (!db.isOpen) {
        db = await openDatabase(db_path);
      }

      int insrt_val = await db.rawUpdate(
          'UPDATE accs_auto_trans SET dur = ?,amt_limit = ? ,reg_on = ? WHERE aid = ?',
          [
            formatter.format(dtedue),
            int.parse(amtController.text),
            DateTime.now().toString(),
            aid
          ]);

      //db.close();

      if (insrt_val > 0) {
        Navigator.pop(context);
        regApprvltoCloud(aid);
        //custMsg('Auto Approval', 'Auto Approval Update Successful');
      }
    }
  }

  Future<void> delAcc(itm, int q) async {
    if (!db.isOpen) {
      db = await openDatabase(db_path);
    }

    int insrt_val = await db
        .rawUpdate('UPDATE my_accs SET del = ? WHERE id = ?', [q, itm['id']]);

    //Refresh the List of Accounts
    lstAccs = await db.rawQuery('SELECT * FROM my_accs');

    //db.close();

    if (insrt_val > 0) {
      await syncDelAcc(itm, q == 1 ? 0 : 1);

      q == 1
          ? custMsg('Deactivate Account', 'Deactivation Successful')
          : custMsg('Reactivate Account', 'Reactivation Successful');

      setState(() {
        //Update UI
      });
    }
  }

  Future<void> syncDelAcc(itm, q) async {
    if (pr == null) {
      pr = ProgressDialog(this.context,
          type: ProgressDialogType.Normal, isDismissible: false);

      pr.style(message: 'Syncing with Cloud...');
    }

    if (pr.isShowing()) {
      pr.update(message: 'Syncing with Cloud...');
    } else {
      await pr.show();
    }

    var response = await http.post(url, headers: {
      'x-task': 'delAcc',
      'x-API-KEY': 'P0oG6pnwuI>t*gQ*SehXqEp#x`5#Y',
      'x-FID': itm['fid'].toString(),
      'x-ACC': itm['acc_no'],
      'x-ACTV': q.toString(),
    });

    print('RegTrans_Response - ' + response.body);

    pr.hide();

    if (response.body != '0') {
      q == 1
          ? showToast(false, 'Activation Sync successful')
          : showToast(false, 'Deactivation Sync successful');
    } else {
      q == 1
          ? showToast(false, 'Activation Sync unsuccessful')
          : showToast(false, 'Deactivation Sync unsuccessful');
    }
  }

  Future<void> captureSignature() async {
    HandSignatureControl sig_control = new HandSignatureControl(
      threshold: 5.0,
      smoothRatio: 0.65,
      velocityRange: 2.0,
    );
    showDialog(
        context: this.context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final _formKey = GlobalKey<FormState>();
          return AlertDialog(
            title: Text(
              'Signature Capture',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
            content: Stack(
              children: [
                Divider(
                  thickness: 2.0,
                  height: 1.0,
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          height:
                              (MediaQuery.of(context).size.height / 2) - 100,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.black)),
                          child: HandSignaturePainterView(
                            control: sig_control,
                            type: SignatureDrawType.shape,
                          )),
                      CustomPaint(
                        painter: DebugSignaturePainterCP(
                          control: sig_control,
                          cp: false,
                          cpStart: false,
                          cpEnd: false,
                        ),
                      ),
                      /*Divider(
                        height: 10,
                        thickness: 1,
                        color: Colors.black,
                      ),*/
                      SizedBox(
                        height: 10,
                      ),
                      GradientButton(
                        child: Text('Save Signature'),
                        callback: () async {
                          //Navigator.pop(context);
                          final sig_img = await sig_control.toImage(
                              height: 157, width: 229);
                          await evalSig(context, sig_img);
                        },
                        gradient: isDark
                            ? Gradients.cosmicFusion
                            : Gradients.rainbowBlue,
                        shadowColor: isDark
                            ? Gradients.cosmicFusion.colors.last
                                .withOpacity(0.25)
                            : Gradients.rainbowBlue.colors.last
                                .withOpacity(0.25),
                        increaseHeightBy: 10,
                        increaseWidthBy: double.maxFinite,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      GradientButton(
                        child: Text('Start Over'),
                        callback: () {
                          sig_control.clear();
                        },
                        gradient: Gradients.backToFuture,
                        increaseHeightBy: 10,
                        increaseWidthBy: double.maxFinite,
                      ),
                      /*SizedBox(
                        height: 10,
                      ),
                      GradientButton(
                        child: Text('Close'),
                        callback: () {
                          Navigator.pop(context);
                        },
                        gradient: Gradients.backToFuture,
                        shadowColor: Gradients.backToFuture.colors.last
                            .withOpacity(0.25),
                        increaseHeightBy: 10,
                        increaseWidthBy: double.maxFinite,
                      ),*/
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }

  Future<void> evalSig(BuildContext cntx, ByteData sig_img) async {
    if (pr == null) {
      pr = ProgressDialog(this.context,
          type: ProgressDialogType.Normal, isDismissible: false);

      pr.style(message: 'Connect to Network...');
    }

    if (pr.isShowing()) {
      pr.update(message: 'Connect to Network...');
    } else {
      await pr.show();
    }

    //Gen File Name
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random _rnd = Random.secure();

    String getRandomString(int length) =>
        String.fromCharCodes(Iterable.generate(
            length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

    //Connect to Blueviolet Server
    final FTPConnect _ftpConnect = new FTPConnect("ftp.blueviolet.tech",
        user: "verify@blueviolet.tech", pass: "s,A9@motPSY*Q3~", debug: true);

    String file_name = getRandomString(10) + '.png';

    File fileToUpload = await MemoryFileSystem()
        .file(file_name)
        .writeAsBytes(sig_img.buffer.asUint8List());

    await _ftpConnect.connect();
    pr.update(message: 'Uploading Signature...');
    bool res =
        await _ftpConnect.uploadFileWithRetry(fileToUpload, pRetryCount: 2);
    await _ftpConnect.disconnect();
    print(res);
    pr.hide();

    if (res) {
      print('Success');
      //Report Success
      Navigator.pop(cntx);

      //Store the Signature link
      final storage = FlutterSecureStorage();

      await storage.write(
          key: 'sign', value: 'https://blueviolet.tech/verify/' + file_name);

      custMsg('Signature Capture', 'Successful');

      //Exchange public keys for secure communication
    } else {
      custMsg('Signature Capture',
          'Linkage Unsuccessful, try again later - ' + e.toString());
    }

    /*String res = await Tflite.loadModel(
        model: "assets/model.tflite",
        labels: "assets/labels.txt",
        numThreads: 1, // defaults to 1
        isAsset: true, // defaults to true, set to false to load resources outside assets
        useGpuDelegate: false // defaults to false, set to true to use GPU delegate
    );

    print('TensorFlow - '+res);

    img.Image sig = img.Image.fromBytes(229, 157, sig_img.buffer.asUint8List());


    */ /*String url = 'https://blueviolet.tech/ver_id/sigs/sample_signature.jpg';

    Uint8List sig_bytes = (await NetworkAssetBundle(Uri.parse(url)).load(url))
        .buffer
        .asUint8List();

    img.Image sig = img.decodeImage(sig_bytes);*/ /*

    var recognitions = await Tflite.runModelOnBinary(
        binary: imageToByteListFloat32(sig, 224, 127.5, 127.5),// required
        //binary: sig.getBytes().buffer.asUint8List(),
        numResults: 1,    // defaults to 5
        threshold: 0.05,  // defaults to 0.1
        asynch: true      // defaults to true
    );

    print('Signature Id Results '+jsonEncode(recognitions));


    await Tflite.close();

    pr.hide();*/

    /*d_imgs.Image sig_1 =
         d_imgs.Image.fromBytes(229, 157, sig_img.buffer.asUint8List());*/ /*
    //final d_imgs.Image sig_2 =  Image.network('https://blueviolet.tech/ver_id/sigs/sample_signature.jpg');
    String url = 'https://blueviolet.tech/ver_id/sigs/sample_signature.jpg';
    //String url_2 = 'https://blueviolet.tech/ver_id/sigs/sample_signature_2.jpg';
    Uint8List sig_bytes = (await NetworkAssetBundle(Uri.parse(url)).load(url))
        .buffer
        .asUint8List();

    //d_imgs.Image sig_2 = d_imgs.Image.fromBytes(229, 157, sig_bytes);

    //Compare the two signatures and see what the difference
    try {
      //Navigator.pop(context);
      var diff = DiffImage.compareFromMemory(d_imgs.decodeImage(sig_bytes),
          d_imgs.decodeImage(sig_img.buffer.asUint8List()),ignoreAlpha: false);
      //var diff = await DiffImage.compareFromUrl(url, url_2);
      print('The difference between images is: ${diff.diffValue} %');
    } catch (e) {
      print(e);
    }*/
    //pr.hide();
  }

  Uint8List imageToByteListFloat32(
      img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (img.getRed(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getGreen(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getBlue(pixel) - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  Uint8List imageToByteListUint8(img.Image image, int inputSize) {
    var convertedBytes = Uint8List(1 * inputSize * inputSize * 3);
    var buffer = Uint8List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = img.getRed(pixel);
        buffer[pixelIndex++] = img.getGreen(pixel);
        buffer[pixelIndex++] = img.getBlue(pixel);
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  String sign(String plainText, RSAPrivateKey privateKey) {
    var signer = RSASigner(SHA256Digest(), "0609608648016503040201");
    signer.init(true, pc_api.PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return base64Encode(signer
        .generateSignature(Uint8List.fromList(plainText.codeUnits))
        .bytes);
  }

  RSAPrivateKey parsePrivateKeyFromPem(pemString) {
    List<int> privateKeyDER = decodePEM(pemString);
    var asn1Parser = new ASN1Parser(privateKeyDER);
    var topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

    var modulus, privateExponent, p, q;
    // Depending on the number of elements, we will either use PKCS1 or PKCS8
    if (topLevelSeq.elements.length == 3) {
      var privateKey = topLevelSeq.elements[2];

      asn1Parser = new ASN1Parser(privateKey.contentBytes());
      var pkSeq = asn1Parser.nextObject() as ASN1Sequence;

      modulus = pkSeq.elements[1] as ASN1Integer;
      privateExponent = pkSeq.elements[3] as ASN1Integer;
      p = pkSeq.elements[4] as ASN1Integer;
      q = pkSeq.elements[5] as ASN1Integer;
    } else {
      modulus = topLevelSeq.elements[1] as ASN1Integer;
      privateExponent = topLevelSeq.elements[3] as ASN1Integer;
      p = topLevelSeq.elements[4] as ASN1Integer;
      q = topLevelSeq.elements[5] as ASN1Integer;
    }

    RSAPrivateKey rsaPrivateKey = RSAPrivateKey(
        modulus.valueAsBigInteger,
        privateExponent.valueAsBigInteger,
        p.valueAsBigInteger,
        q.valueAsBigInteger);

    return rsaPrivateKey;
  }

  List<int> decodePEM(String pem) {
    return base64.decode(removePemHeaderAndFooter(pem));
  }

  String removePemHeaderAndFooter(String pem) {
    var startsWith = [
      "-----BEGIN PUBLIC KEY-----",
      "-----BEGIN RSA PRIVATE KEY-----",
      "-----BEGIN RSA PUBLIC KEY-----",
      "-----BEGIN PRIVATE KEY-----",
      "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\nVersion: React-Native-OpenPGP.js 0.1\r\nComment: http://openpgpjs.org\r\n\r\n",
      "-----BEGIN PGP PRIVATE KEY BLOCK-----\r\nVersion: React-Native-OpenPGP.js 0.1\r\nComment: http://openpgpjs.org\r\n\r\n",
    ];
    var endsWith = [
      "-----END PUBLIC KEY-----",
      "-----END PRIVATE KEY-----",
      "-----END RSA PRIVATE KEY-----",
      "-----END RSA PUBLIC KEY-----",
      "-----END PGP PUBLIC KEY BLOCK-----",
      "-----END PGP PRIVATE KEY BLOCK-----",
    ];
    bool isOpenPgp = pem.indexOf('BEGIN PGP') != -1;

    pem = pem.replaceAll(' ', '');
    pem = pem.replaceAll('\n', '');
    pem = pem.replaceAll('\r', '');

    for (var s in startsWith) {
      s = s.replaceAll(' ', '');
      if (pem.startsWith(s)) {
        pem = pem.substring(s.length);
      }
    }

    for (var s in endsWith) {
      s = s.replaceAll(' ', '');
      if (pem.endsWith(s)) {
        pem = pem.substring(0, pem.length - s.length);
      }
    }

    if (isOpenPgp) {
      var index = pem.indexOf('\r\n');
      pem = pem.substring(0, index);
    }

    return pem;
  }

  Future<void> regTrans(
      bool apprvd, String reason, Map<String, dynamic> message) async {
    if (pr == null) {
      pr = ProgressDialog(this.context,
          type: ProgressDialogType.Normal, isDismissible: false);

      pr.style(message: 'Processing...');
    }

    if (pr.isShowing()) {
      pr.update(message: 'Processing...');
    } else {
      await pr.show();
    }

    if (!db.isOpen) {
      db = await openDatabase(db_path);
    }

    String actn_dte =
        new DateFormat('yyyy-MM-dd hh:mm:ss').format(new DateTime.now());

    int rslt = await db.insert('transactions', {
      'fi_name': message['data']['Sent By'],
      'fi_logo': message['data']['Logo'],
      'acc': message['data']['Acc'],
      'trans_id': message['data']['Trans ID'],
      'trans_type': message['data']['Trans Type'],
      'trans_nme': message['data']['Msg'],
      'curr_denom': message['data']['Curr'],
      'trans_amt': message['data']['Amt'],
      'date_req': message['data']['Trans Date'],
      'reg_on': actn_dte
    });

    //await db.close();

    if (rslt > 0) {
      actn_dte =
          new DateFormat('yyyy-MM-dd hh:mm:ss').format(new DateTime.now());

      if (!db.isOpen) {
        db = await openDatabase(db_path);
      }

      int q = await db.insert('verifications', {
        'tid': rslt,
        'date_ver': message['data']['Trans Date'],
        'approved': apprvd ? 1 : 0,
        'reason': reason,
        'token': client_sig,
        'reg_on': actn_dte
      });

      if (q > 0) {
        //Reg the Escrow
        int r = await db.insert('escrow', {
          'tid': rslt,
          'recpt': rtelController.text,
          'approved': escrow ? 0 : 1,
          'reg_on': actn_dte
        });

        if (r > 0) {
          showToast(false, escrow ? 'Escrow registered' : 'Escrow declined');
        }

        showToast(
            false, apprvd ? 'Transaction Approved' : 'Transaction Declined');
        pr.update(message: 'Syncing with ' + message['data']['Sent By']);

        //await db.close();

        if (!db.isOpen) {
          db = await openDatabase(db_path);
        }

        List<Map> lstTrans = await db.rawQuery(
            'SELECT * FROM transactions JOIN verifications ON transactions.id = verifications.tid '
            'WHERE transactions.id = ?',
            [rslt]);

        print(jsonEncode(lstTrans));

        //List<Map> lstVer = await db.rawQuery('SELECT * FROM verifications WHERE id = ?',[q]);

        String upld_rslt = await uploadTrans(
            lstTrans, message['data']['FID'], message['data']['Trans ID']);

        pr.hide();

        if (upld_rslt == '1') {
          //showToast(false, 'Successful Sync with ' + message['data']['Sent By']);
          apprvd
              ? shwAlertMsg(false, 'Transaction Approved',
                  'Successful Sync with ' + message['data']['Sent By'])
              : shwAlertMsg(true, 'Transaction Declined',
                  'Successful Sync with ' + message['data']['Sent By']);
        } else if (upld_rslt == '0') {
          custMsg('Sync Transaction', 'Syncing Failed - Unknown Error');
          //shwAlertMsg(true, 'Transaction Approval', 'Syncing Failed - Unknown Error');
        }
      } else {
        pr.hide();
      }
    }
    //await db.close();
  }

  Future<String> uploadTrans(List<Map> lstTrans, String fid, String tid) async {
    final storage = FlutterSecureStorage();
    String uuid = await storage.read(key: 'usrid');

    var response = await http.post(url, headers: {
      'x-task': 'regTrans',
      'x-API-KEY': 'P0oG6pnwuI>t*gQ*SehXqEp#x`5#Y',
      'x-FID': fid,
      'x-TRANS-ID': tid,
      'x-TRANS-ACC': lstTrans[0]['acc'],
      'x-TRANS-DTE': lstTrans[0]['date_req'],
      'x-TRANS-TYP': lstTrans[0]['trans_type'],
      'x-TRANS-CURR': lstTrans[0]['curr_denom'],
      'x-TRANS-AMT': lstTrans[0]['trans_amt'].toString(),
      'x-TRANS-DESC': lstTrans[0]['trans_nme'],
      'x-TRANS-STS': lstTrans[0]['approved'] == 1 ? 'Approved' : 'Declined',
      'x-TRANS-STS-RSN': lstTrans[0]['reason'],
      'x-VER-DTE': lstTrans[0]['date_ver'],
      'x-ESCRW': escrow ? '1' : '0',
      'x-USR': uuid,
      'x-TEL': rtelController.text
    }, body: {
      'TKN': lstTrans[0]['token']
    });

    print('RegTrans_Response - ' + response.body);

    return response.body;
  }

  void getRejReason(Map<String, dynamic> message) {
    String reason = 'Fraud';
    TextEditingController xplainCont = new TextEditingController();
    showDialog(
        context: this.context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final _formKey = GlobalKey<FormState>();
          return AlertDialog(
            title: Text(
              'Transaction Rejection',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
            content: Stack(
              children: [
                Divider(
                  thickness: 2.0,
                  height: 1.0,
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField(
                        decoration: InputDecoration(
                            focusedBorder: const OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Color(0xFF34eb4f), width: 1.0)),
                            border: OutlineInputBorder(),
                            //errorText: valTel(),
                            labelText: "Rejection Reason"),
                        icon: Icon(LineIcons.chevron_circle_down),
                        iconSize: 28,
                        onChanged: (String selVal) {
                          reason = selVal;
                        },
                        items: ['Fraud', 'Suspicious Transaction', 'Other']
                            .map<DropdownMenuItem<String>>((String val) {
                          return DropdownMenuItem<String>(
                            value: val,
                            child: Text(val,
                                style: TextStyle(fontFamily: 'Montserrat')),
                          );
                        }).toList(),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      TextField(
                        controller: xplainCont,
                        maxLength: 50,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                            focusedBorder: const OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Color(0xFF34eb4f), width: 1.0)),
                            border: OutlineInputBorder(),
                            //errorText: valTel(),
                            labelText: "Explain " + reason),
                        keyboardType: TextInputType.multiline,
                        maxLines: 4,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      GradientButton(
                        child: Text('Continue'),
                        callback: () {
                          if (xplainCont.text.length > 0) {
                            Navigator.pop(context);
                            reason += ' - ' + xplainCont.text;
                            regTrans(false, reason, message);
                          } else {
                            showToast(
                                true, 'Kindly explain reason for rejection');
                          }
                        },
                        gradient: isDark
                            ? Gradients.cosmicFusion
                            : Gradients.rainbowBlue,
                        shadowColor: isDark
                            ? Gradients.cosmicFusion.colors.last
                                .withOpacity(0.25)
                            : Gradients.rainbowBlue.colors.last
                                .withOpacity(0.25),
                        increaseHeightBy: 10,
                        increaseWidthBy: double.maxFinite,
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }

  regApprvltoCloud(int insrt_val) async {
    if (pr == null) {
      pr = ProgressDialog(this.context,
          type: ProgressDialogType.Normal, isDismissible: false);

      pr.style(message: 'Processing...');
    }

    if (pr.isShowing()) {
      pr.update(message: 'Processing...');
    } else {
      pr.update(message: 'Processing...');
      await pr.show();
    }

    final storage = FlutterSecureStorage();
    String usrid = await storage.read(key: 'usrid');

    //Get the data from the db
    if (!db.isOpen) {
      db = await openDatabase(db_path);
    }

    List<Map> lstRslt = await db.rawQuery(
        'SELECT * FROM my_accs '
        'JOIN accs_auto_trans ON my_accs.id = accs_auto_trans.aid WHERE accs_auto_trans.aid = ?',
        [insrt_val]);

    //await db.close();

    if (lstRslt.isNotEmpty) {
      var response = await http.post(url, headers: {
        'x-task': 'regAutoApprvl',
        'x-API-KEY': 'P0oG6pnwuI>t*gQ*SehXqEp#x`5#Y',
        'x-FID': fid,
        'x-USR': usrid,
        'x-BACC': lstRslt[0]['acc_no'].toString(),
        'x-DUR': lstRslt[0]['dur'],
        'x-TL': lstRslt[0]['trans_limit'].toString(),
        'x-AMT': lstRslt[0]['amt_limit'].toString(),
        'x-REG-ON': lstRslt[0]['reg_on']
      });

      print('RegAutoApproval_Response - ' + response.body);

      pr.hide();

      if (response.body == '1') {
        //Reg successful
        custMsg('Auto Approval', 'Auto Approval Sync Successful');
      } else if (response.body == '1u') {
        //Update successful
        if (c_cntx != null) {
          Navigator.pop(c_cntx);
          setState(() {
            chkAAValid();
          });
          showToast(false, 'Auto Approval Update Successful');
        } else {
          custMsg('Auto Approval', 'Auto Approval Update Successful');
        }
      }
    } else {
      pr.hide();
      print('No Data to Upload');
    }
  }

  Future<void> regAutoApprvlTrans(Map<String, dynamic> message) async {
    //Get the Transaction from the cloud
    if (pr == null) {
      pr = ProgressDialog(this.context,
          type: ProgressDialogType.Normal, isDismissible: false);

      pr.style(message: 'Processing...');
    }

    if (pr.isShowing()) {
      pr.update(message: 'Processing...');
    } else {
      pr.update(message: 'Processing...');
      await pr.show();
    }

    var response = await http.get(url, headers: {
      'x-task': 'getTrans',
      'x-API-KEY': 'P0oG6pnwuI>t*gQ*SehXqEp#x`5#Y',
      'x-TID': message['data']['TID']
    });

    print('GetTrans_Response - ' + response.body);

    if (response.body != '0') {
      pr.update(message: 'Syncing Transactions...');

      List<Map> tRslt = List.from(jsonDecode(response.body));

      if (!db.isOpen) {
        db = await openDatabase(db_path);
      }

      String actn_dte =
          new DateFormat('yyyy-MM-dd hh:mm:ss').format(new DateTime.now());

      int rslt = await db.insert('transactions', {
        'fi_name': tRslt[0]['facility'],
        'fi_logo': tRslt[0]['logo'],
        'acc': tRslt[0]['acc'],
        'trans_id': tRslt[0]['trans_id'],
        'trans_type': tRslt[0]['trans_type'],
        'trans_nme': message['data']['Msg'],
        'curr_denom': tRslt[0]['curr'],
        'trans_amt': tRslt[0]['trans_amt'],
        'date_req': tRslt[0]['trans_date'],
        'reg_on': actn_dte
      });

      if (rslt > 0) {
        actn_dte =
            new DateFormat('yyyy-MM-dd hh:mm:ss').format(new DateTime.now());

        int q = await db.insert('verifications', {
          'tid': rslt,
          'date_ver': tRslt[0]['ver_date'],
          'approved': 1,
          'reason': tRslt[0]['reason'],
          'token': client_sig,
          'reg_on': actn_dte
        });

        if (q > 0) {
          pr.hide();
          shwAlertMsg(false, 'Transaction Approval', message['data']['Msg']);
        }
      } else {
        custMsg('Auto Approval', 'Unable to Sync Transaction');
      }
    } else {
      pr.hide();
    }
  }

  Future<void> showBreakdown() async {
    //Get all the Transactions that add up to total

    if (!db.isOpen) {
      db = await openDatabase(db_path);
    }

    List<Map> lstRslt = await db.rawQuery(
        'SELECT * FROM transactions  WHERE curr_denom = ? GROUP BY acc',
        ['KES']);

    List<Map> lstRsltM = new List<Map>();

    for (int i = 0; i < lstRslt.length; i++) {
      List<Map> lstRslt2 = await db.rawQuery(
          'SELECT SUM(trans_amt) AS t_amt, ? AS fac, ? AS acc, ? AS logo FROM transactions WHERE fi_name = ? AND acc = ? GROUP BY acc',
          [
            lstRslt[i]['fi_name'],
            lstRslt[i]['acc'],
            lstRslt[i]['fi_logo'],
            lstRslt[i]['fi_name'],
            lstRslt[i]['acc']
          ]);

      lstRsltM.add(lstRslt2[0]);
    }

    //await db.close();

    if (lstRslt.isNotEmpty) {
      List<PieChartSectionData> showingSections = new List();
      for (int i = 0; i < lstRsltM.length; i++) {
        print(jsonEncode(lstRsltM[i]));

        final isTouched = i == touchedIndex;
        print('is touched ' + isTouched.toString());
        final double fontSize = isTouched ? 20 : 12;
        final double radius = isTouched ? 110 : 100;
        final double widgetSize = isTouched ? 55 : 40;
        final Color clr =
            Colors.primaries[Random().nextInt(Colors.primaries.length)];

        showingSections.add(new PieChartSectionData(
          color: clr,
          value: double.parse(lstRsltM[i]['t_amt'].toString()),
          title: obscAccNo(lstRsltM[i]['acc']) +
              '\n' +
              curr_format.format(lstRsltM[i]['t_amt']) +
              '\n' +
              ((double.parse(lstRsltM[i]['t_amt'].toString()) / total_amt) *
                      100)
                  .roundToDouble()
                  .toString() +
              '%',
          radius: radius,
          titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xffffffff),
              fontFamily: 'Montserrat'),
          badgeWidget: shwLogo(
            lstRsltM[i]['logo'],
            widgetSize,
            clr,
          ),
          badgePositionPercentageOffset: .98,
        ));
      }
      showDialog(
          context: this.context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            final _formKey = GlobalKey<FormState>();
            return AlertDialog(
              title: Text(
                'Total Amount Authenticated Breakdown',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
              ),
              content: Stack(
                children: [
                  Divider(
                    thickness: 1.0,
                    height: 1.0,
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AspectRatio(
                          aspectRatio: 1.0,
                          child: PieChart(PieChartData(
                              pieTouchData: PieTouchData(
                                  touchCallback: (pieTouchResponse) {
                                setState(() {
                                  if (pieTouchResponse.touchInput
                                          is FlLongPressEnd ||
                                      pieTouchResponse.touchInput is FlPanEnd) {
                                    touchedIndex = -1;
                                  } else {
                                    touchedIndex =
                                        pieTouchResponse.touchedSectionIndex;
                                  }
                                });
                              }),
                              borderData: FlBorderData(
                                show: false,
                              ),
                              sectionsSpace: 2.0,
                              centerSpaceRadius: 0,
                              sections: showingSections)),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        GradientButton(
                          child: Text('Close'),
                          callback: () {
                            Navigator.pop(context);
                          },
                          gradient: Gradients.backToFuture,
                          shadowColor: Gradients.backToFuture.colors.last
                              .withOpacity(0.25),
                          increaseHeightBy: 10,
                          increaseWidthBy: double.maxFinite,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          });
    }
  }

  Widget shwLogo(String svgAsset, double size, Color borderColor) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(.5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: FadeInImage.assetNetwork(
          placeholder: 'assets/loading.gif',
          image: svgAsset,
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  Future<bool> fcmProcessed(Map<String, dynamic> message) async {
    //Database db = await openDatabase(db_path);
    if (!db.isOpen) {
      db = await openDatabase(db_path);
    }

    List<Map> lstRslt = new List();

    try {
      if (message['data']['TID'] != null) {
        lstRslt = await db.rawQuery(
            'SELECT * FROM transactions WHERE trans_id = ? AND acc = ?',
            [message['data']['Trans ID'], message['data']['TID']]);
      } else {
        //Check if is escrow message
        if (message['data']['Msg'].toString().startsWith('Release Amount of')) {
          lstRslt = await db.rawQuery(
              'SELECT * FROM transactions JOIN escrow ON transactions.id = escrow.tid WHERE trans_id = ? AND approved = 1',
              [message['data']['Trans ID']]);
        } else {
          lstRslt = await db.rawQuery(
              'SELECT * FROM transactions WHERE trans_id = ? ',
              [message['data']['Trans ID']]);
        }
      }
    } on DatabaseException {
      print('Error on processing DB');
    }
    //await db.close();

    if (lstRslt.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<void> showTTrans() async {}

  Future<void> showTL(itm) async {
    //Database db = await openDatabase(db_path);
    if (!db.isOpen) {
      db = await openDatabase(db_path);
    }

    List<Map> lstRslt = await db.rawQuery(
        'SELECT * FROM transactions JOIN verifications ON transactions.id = verifications.tid WHERE fi_name = ? '
        'AND acc = ? AND DATE(date_req) BETWEEN ? AND ? ORDER BY date_req DESC',
        [
          itm['fi_name'],
          itm['acc'],
          u_dteController.text,
          l_dteController.text
        ]);

    if (lstRslt.isEmpty) {
      custMsg('Show More', 'No Data to Show');
      return;
    }

    //await db.close();

    List<TimelineModel> items = new List();

    final storage = FlutterSecureStorage();

    String usr_sign = await storage.read(key: 'sign');

    for (var v_itm in lstRslt) {
      items.add(TimelineModel(
          Card(
            margin: EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    child: ClipOval(
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/loading.gif',
                        image: itm['fi_logo'],
                        fit: BoxFit.fill,
                      ),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  Divider(
                    thickness: 1.0,
                    height: 1.0,
                    color: Colors.black,
                  ),
                  const SizedBox(
                    height: 5.0,
                  ),
                  Text(
                    'Date: - ' + v_itm['date_req'],
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
                  ),
                  const SizedBox(
                    height: 5.0,
                  ),
                  Text(
                    'Desc: - ' + v_itm['trans_nme'],
                    style: TextStyle(fontFamily: 'Montserrat'),
                  ),
                  const SizedBox(
                    height: 5.0,
                  ),
                  Divider(
                    thickness: 1.0,
                    height: 1.0,
                    color: Colors.black,
                  ),
                  const SizedBox(
                    height: 5.0,
                  ),
                  Text(
                    'Amount - ' + curr_format.format(v_itm['trans_amt']),
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
                  ),
                  const SizedBox(
                    height: 5.0,
                  ),
                  Divider(
                    thickness: 1.0,
                    height: 1.0,
                    color: Colors.black,
                  ),
                  const SizedBox(
                    height: 5.0,
                  ),
                  Text(
                    v_itm['approved'] == 1 ? 'Approved' : 'Rejected',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                        color:
                            v_itm['approved'] == 1 ? Colors.green : Colors.red),
                  ),
                  const SizedBox(
                    height: 2.0,
                  ),
                  CircleAvatar(
                    child: ClipOval(
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/loading.gif',
                        image: usr_sign,
                        fit: BoxFit.fill,
                      ),
                    ),
                    backgroundColor: Colors.white,
                  )
                ],
              ),
            ),
          ),
          icon: Icon(Icons.blur_circular_sharp)));
    }
    showDialog(
        context: this.context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final _formKey = GlobalKey<FormState>();
          return AlertDialog(
            title: Text(
              itm['fi_name'] + '\nAcc ' + obscAccNo(itm['acc']),
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
            ),
            content: Stack(
              children: [
                Divider(
                  thickness: 1.0,
                  height: 1.0,
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                          height: MediaQuery.of(this.context).size.height - 400,
                          width: double.maxFinite,
                          child: Timeline(
                              children: items,
                              position: TimelinePosition.Left)),
                      SizedBox(
                        height: 10,
                      ),
                      GradientButton(
                        child: Text('Close'),
                        callback: () {
                          Navigator.pop(context);
                        },
                        gradient: Gradients.backToFuture,
                        shadowColor: Gradients.backToFuture.colors.last
                            .withOpacity(0.25),
                        increaseHeightBy: 10,
                        increaseWidthBy: double.maxFinite,
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }

  void showDPT(itm) {
    showDialog(
        context: this.context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(
              'Select Date Range',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
            content: Material(
              child: Stack(
                children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      new Container(
                        child: TextField(
                          controller: u_dteController,
                          maxLength: 10,
                          decoration: InputDecoration(
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Color(0xFF650dd1), width: 1.0)),
                              border: OutlineInputBorder(),
                              labelText: "From"),
                          keyboardType: TextInputType.datetime,
                          onTap: () async {
                            FocusScope.of(context)
                                .requestFocus(new FocusNode());

                            DateTime selDT = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now()
                                    .subtract(Duration(days: 365)),
                                lastDate: DateTime.now());

                            u_dteController.text =
                                selDT.toIso8601String().substring(0, 10);
                          },
                        ),
                        margin: new EdgeInsets.fromLTRB(10, 10, 10, 10),
                      ),
                      new Container(
                        child: TextField(
                          controller: l_dteController,
                          maxLength: 10,
                          decoration: InputDecoration(
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Color(0xFF650dd1), width: 1.0)),
                              border: OutlineInputBorder(),
                              labelText: "To"),
                          keyboardType: TextInputType.datetime,
                          onTap: () async {
                            FocusScope.of(context)
                                .requestFocus(new FocusNode());

                            DateTime selDT = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now()
                                    .subtract(Duration(days: 365)),
                                lastDate: DateTime.now());

                            l_dteController.text =
                                selDT.toIso8601String().substring(0, 10);
                          },
                        ),
                        margin: new EdgeInsets.fromLTRB(10, 0, 10, 10),
                      )
                    ],
                  )
                ],
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: Text('Ok', style: TextStyle(fontFamily: 'Montserrat')),
                onPressed: () async {
                  //Run Analysis Again
                  Navigator.pop(context);
                  if (_selectedIndex == 2) {
                    //Load the summerized transactions as per the selected date range
                    if (l_dteController.text.isNotEmpty ||
                        u_dteController.text.isNotEmpty) {
                      setState(() {
                        getData();
                      });
                    }
                  } else {
                    if (itm != null) {
                      showTL(itm);
                    }
                  }
                },
              ),
              CupertinoDialogAction(
                child:
                    Text('Cancel', style: TextStyle(fontFamily: 'Montserrat')),
                onPressed: () {
                  Navigator.pop(context);
                  u_dteController.text = '';
                  l_dteController.text = '';
                  setState(() {
                    getData();
                  });
                },
              )
            ],
          );
        });
  }

  Future<void> regFdbk(int mood) async {
    final InAppReview inAppReview = InAppReview.instance;

    if (pr == null) {
      pr = ProgressDialog(this.context,
          type: ProgressDialogType.Normal, isDismissible: false);

      pr.style(message: 'Processing...');
    }

    if (pr.isShowing()) {
      pr.update(message: 'Processing...');
    } else {
      pr.update(message: 'Processing...');
      await pr.show();
    }

    final storage = FlutterSecureStorage();

    String usrid = await storage.read(key: 'usrid');

    var response = await http.get(url, headers: {
      'x-task': 'regFdbk',
      'x-API-KEY': 'P0oG6pnwuI>t*gQ*SehXqEp#x`5#Y',
      'x-USR': usrid,
      'x-MOOD': mood.toString(),
      'x-FDBK': fdbkController.text
    });

    pr.hide();

    print('RegFdbk_Response - ' + response.body);

    if (response.body == '1') {
      custMsg('Feedback', 'Feedback Registered Successfully');
      fdbkController.text = '';
      if (!await storage.containsKey(key: 'has_rated')) {
        if (await inAppReview.isAvailable()) {
          //reqAppStoreRating(inAppReview); TODO: Enable during field testing
        }
      }
    }
  }

  void reqAppStoreRating(InAppReview inAppReview) {
    showDialog(
        context: this.context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(
              'App Rating',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
            content: Platform.isAndroid
                ? Text('Rate the App in the Play Store ?',
                    style: TextStyle(fontFamily: 'Montserrat'))
                : Text('Rate the App in the App Store ?',
                    style: TextStyle(fontFamily: 'Montserrat')),
            actions: [
              CupertinoDialogAction(
                child: Text('Yes', style: TextStyle(fontFamily: 'Montserrat')),
                onPressed: () async {
                  //Run Analysis Again
                  Navigator.pop(context);
                  inAppReview.requestReview();
                  final storage = FlutterSecureStorage();
                  await storage.write(key: 'has_rated', value: 'true');
                },
              ),
              CupertinoDialogAction(
                child: Text('No', style: TextStyle(fontFamily: 'Montserrat')),
                onPressed: () {
                  //Run Analysis Again
                  Navigator.pop(context);
                },
              )
            ],
          );
        });
  }

  void reqEscrow(Map<String, dynamic> message) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(
              'Request Escrow',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
            content: Text('Freeze the payment until goods/services received?',
                style: TextStyle(fontFamily: 'Montserrat')),
            actions: [
              CupertinoDialogAction(
                child: Text('Yes', style: TextStyle(fontFamily: 'Montserrat')),
                onPressed: () async {
                  Navigator.pop(context);
                  escrow = true;
                  reqRecpTel(message);
                },
              ),
              CupertinoDialogAction(
                child: Text('No', style: TextStyle(fontFamily: 'Montserrat')),
                onPressed: () async {
                  Navigator.pop(context);
                  escrow = false;
                  rtelController.text = 'N/A';
                  regTrans(true, 'N/A', message);
                },
              )
            ],
          );
        });
  }

  void reqEscrowRegReason(BuildContext ctx, Map<String, dynamic> message) {
    showDialog(
        context: this.context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final _formKey = GlobalKey<FormState>();
          return AlertDialog(
            title: Text(
              'Escrow Non Release Reason',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
            ),
            content: Stack(
              children: [
                Divider(
                  thickness: 1.0,
                  height: 1.0,
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: escrw_rej_Controller,
                        maxLength: 50,
                        minLines: 5,
                        maxLines: 10,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                            focusedBorder: const OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Color(0xFF34eb4f), width: 1.0)),
                            border: OutlineInputBorder(),
                            //errorText: valTel(),
                            labelText: "Enter Reason"),
                        keyboardType: TextInputType.multiline,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      GradientButton(
                        child: Text('Continue'),
                        callback: () {
                          if (escrw_rej_Controller.text != null) {
                            Navigator.pop(context);
                            Navigator.pop(ctx);
                            updteEscrow(false, message);
                            //custMsg('Escrow Decline Reason', escrw_rej_Controller.text);
                          } else {
                            custMsg('Rejection Reason',
                                'Kindly enter your rejection reason');
                          }
                        },
                        gradient: isDark
                            ? Gradients.cosmicFusion
                            : Gradients.rainbowBlue,
                        shadowColor: isDark
                            ? Gradients.cosmicFusion.colors.last
                                .withOpacity(0.25)
                            : Gradients.rainbowBlue.colors.last
                                .withOpacity(0.25),
                        increaseHeightBy: 10,
                        increaseWidthBy: double.maxFinite,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      GradientButton(
                        child: Text('Close'),
                        callback: () {
                          Navigator.pop(context);
                        },
                        gradient: Gradients.backToFuture,
                        shadowColor: Gradients.backToFuture.colors.last
                            .withOpacity(0.25),
                        increaseHeightBy: 10,
                        increaseWidthBy: double.maxFinite,
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }

  void reqRecpTel(Map<String, dynamic> message) {
    showDialog(
        context: this.context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final _formKey = GlobalKey<FormState>();
          return AlertDialog(
            title: Text(
              'Recipient Mobile Number',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
            ),
            content: Stack(
              children: [
                Divider(
                  thickness: 1.0,
                  height: 1.0,
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        maxLength: 10,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                            focusedBorder: const OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Color(0xFF34eb4f), width: 1.0)),
                            border: OutlineInputBorder(),
                            //errorText: valTel(),
                            labelText: "Enter Recipients Mobile Number"),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          new FilteringTextInputFormatter.allow(RegExp("[0-9]"))
                        ],
                        onChanged: (tel) {
                          rtelController.text = tel;
                        },
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      GradientButton(
                        child: Text('Continue'),
                        callback: () {
                          if (rtelController.text != null) {
                            //Confirm number
                            Navigator.pop(context);
                            telConfirmed(message);
                          } else {
                            custMsg('Recipient Tel',
                                'Kindly enter a valid Mobile Number');
                          }
                        },
                        gradient: isDark
                            ? Gradients.cosmicFusion
                            : Gradients.rainbowBlue,
                        shadowColor: isDark
                            ? Gradients.cosmicFusion.colors.last
                                .withOpacity(0.25)
                            : Gradients.rainbowBlue.colors.last
                                .withOpacity(0.25),
                        increaseHeightBy: 10,
                        increaseWidthBy: double.maxFinite,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      GradientButton(
                        child: Text('Close'),
                        callback: () {
                          Navigator.pop(context);
                        },
                        gradient: Gradients.backToFuture,
                        shadowColor: Gradients.backToFuture.colors.last
                            .withOpacity(0.25),
                        increaseHeightBy: 10,
                        increaseWidthBy: double.maxFinite,
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }

  Future<void> updteEscrow(bool apprv, Map<String, dynamic> message) async {
    if (pr == null) {
      pr = ProgressDialog(this.context,
          type: ProgressDialogType.Normal, isDismissible: false);

      pr.style(message: 'Processing...');
    }

    if (pr.isShowing()) {
      pr.update(message: 'Processing...');
    } else {
      pr.update(message: 'Processing...');
      await pr.show();
    }

    var response = await http.post(url, headers: {
      'x-task': 'updteEscrow',
      'x-API-KEY': 'P0oG6pnwuI>t*gQ*SehXqEp#x`5#Y',
      'x-EID': message['data']['EID'],
      'x-APPRV': apprv ? '1' : '0',
      'x-REG-RSN': escrw_rej_Controller.text,
      'x-R-TEL': message['data']['R Tel']
    }, body: {
      'TKN': client_sig
    });

    print('ApprvEscrow_Response - ' + response.body);

    String rslt = response.body;

    pr.hide();

    if (rslt != '0') {
      //Update the value of escrow in the database to approved
      if (!db.isOpen) {
        db = await openDatabase(db_path);
      }

      List<Map> lstRslt = await db.rawQuery(
          "SELECT id FROM transactions WHERE trans_id = ?",
          [message['data']['Trans ID']]);
      if (lstRslt.isNotEmpty) {
        if (apprv) {
          int q = await db.rawUpdate(
              'UPDATE escrow SET approved = ? WHERE tid = ?',
              [1, lstRslt[0]['id']]);
          if (q > 0) {
            shwAlertMsg(false, 'Escrow Release',
                message['data']['Msg'] + ' - APPROVED');
          }
        } else {
          shwAlertMsg(
              true, 'Escrow Rejection', message['data']['Msg'] + ' - REJECTED');
        }
      }
    } else {
      shwAlertMsg(true, 'Escrow Release', 'Unable to process release');
    }
  }

  void shwEscrwTerms(BuildContext ctx, Map<String, dynamic> message) {
    double p_amt = double.parse(message['data']['Amt']);
    p_amt = (p_amt / 100) * 150;
    String p_val = message['data']['Curr'] + ' ' + p_amt.round().toString();
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            content: new Container(
              //alignment: Alignment(0.0,0.0),
              child: Column(
                children: <Widget>[
                  new Container(
                    child: Icon(
                      CupertinoIcons.exclamationmark_circle,
                      size: 50,
                      color: Color(0xFFc70a0a),
                    ),
                    margin: EdgeInsets.only(bottom: 10),
                    alignment: Alignment.center,
                  ),
                  new Container(
                    child: Text(
                      'Escrowed Decline Terms',
                      style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                    margin: EdgeInsets.only(bottom: 10),
                  ),
                  Text(
                      'Note that refusal to release funds by giving flimsy reasons will result in a fine of\n' +
                          p_val +
                          ' (150%) of Escrowed amount '
                              'and the immediate release of funds to the requesting merchant.',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black,
                      ))
                ],
              ),
            ),
            actions: <Widget>[
              CupertinoButton(
                onPressed: () {
                  Navigator.pop(context);
                  reqEscrowRegReason(ctx, message);
                },
                child: Text(
                  'Continue',
                  style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.normal),
                ),
                color: Color(0xFFc70a0a),
                borderRadius: BorderRadius.circular(0),
              ),
              CupertinoButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.normal),
                ),
                color: Color(0xFF23b83c),
                borderRadius: BorderRadius.circular(0),
              ),
            ],
          );
        });
  }

  chkAAValid() async {
    DateTime dtedue = DateTime.now();
    DateFormat formatter = DateFormat('yyyy-MM-dd');

    List<Map> lstRslt = await db.rawQuery(
        "SELECT * FROM accs_auto_trans JOIN my_accs ON accs_auto_trans.aid = my_accs.id "
        "WHERE DATE(dur) <= ?",
        [formatter.format(dtedue)]);

    if (lstRslt.isNotEmpty) {
      showDialog(
          context: this.context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            c_cntx = context;
            final _formKey = GlobalKey<FormState>();
            return AlertDialog(
              title: Text(
                'Auto Approval Expiry',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
              ),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.90,
                child: Stack(
                  children: [
                    Divider(
                      thickness: 1.0,
                      height: 1.0,
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 10),
                          Text(
                              'The following Account Auto Approvals need to be Renewed',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Montserrat')),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                              child: ListView(
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            children: [for (var itm in lstRslt) expAccs(itm)],
                          )),
                          SizedBox(
                            height: 10,
                          ),
                          GradientButton(
                            child: Text('Close'),
                            callback: () {
                              Navigator.pop(context);
                            },
                            gradient: Gradients.backToFuture,
                            shadowColor: Gradients.backToFuture.colors.last
                                .withOpacity(0.25),
                            increaseHeightBy: 10,
                            increaseWidthBy: double.maxFinite,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          });
    } else {
      print('No Auto Approvals expired');
    }
  }

  Widget expAccs(var itm) {
    return Container(
        padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: ExpansionTileCard(
          leading: CircleAvatar(
            child: ClipOval(
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/loading.gif',
                image: itm['f_logo'],
                fit: BoxFit.fill,
              ),
            ),
            backgroundColor: Colors.white,
          ),
          title: RichText(
            text: TextSpan(
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Montserrat',
                    fontSize: 16.0),
                children: [
                  TextSpan(text: 'Account '),
                  TextSpan(
                      text: itm['f_nme'] + ' - ' + obscAccNo(itm['acc_no']),
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  TextSpan(text: ' Expired On ' + itm['dur'])
                ]),
          ),
          //subtitle: Text('Tap to see more!'),
          children: [
            Divider(
              thickness: 2.0,
              height: 1.0,
            ),
            ButtonBar(
              alignment: MainAxisAlignment.spaceAround,
              buttonHeight: 52.0,
              buttonMinWidth: 90.0,
              children: [
                TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0)),
                    ),
                    onPressed: () {
                      shwAccDetails(itm);
                    },
                    child: Column(
                      children: <Widget>[
                        FaIcon(FontAwesomeIcons.calendarWeek),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                        ),
                        Text(
                          'Auto Renew',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )),
              ],
            )
          ],
        ));
  }

  void telConfirmed(Map<String, dynamic> message) {
    showDialog(
        context: this.context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          c_cntx = context;
          final _formKey = GlobalKey<FormState>();
          return AlertDialog(
            title: Text(
              'Mobile number Confirmation',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
            ),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.90,
              child: Stack(
                children: [
                  Divider(
                    thickness: 1.0,
                    height: 1.0,
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 10),
                        Text(
                            'Kindly confirm that the number to link the escrow with is ' +
                                rtelController.text +
                                " ?",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat')),
                        SizedBox(
                          height: 10,
                        ),
                        GradientButton(
                          child: Text('Yes'),
                          callback: () {
                            Navigator.pop(context);
                            regTrans(true, 'N/A', message);
                          },
                          gradient: Gradients.rainbowBlue,
                          shadowColor: Gradients.rainbowBlue.colors.last
                              .withOpacity(0.25),
                          increaseHeightBy: 10,
                          increaseWidthBy: double.maxFinite,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        GradientButton(
                          child: Text('No'),
                          callback: () {
                            Navigator.pop(context);
                            reqRecpTel(message);
                          },
                          gradient: Gradients.backToFuture,
                          shadowColor: Gradients.backToFuture.colors.last
                              .withOpacity(0.25),
                          increaseHeightBy: 10,
                          increaseWidthBy: double.maxFinite,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }
}

class AuthTopFraud {
  final String acc;
  final String f_rsn;
  final int count;

  AuthTopFraud(this.acc, this.f_rsn, this.count);
}

class AuthTrans {
  final String acc;
  final String month;
  final int amt;

  AuthTrans(this.acc, this.month, this.amt);
}

class AuthAppvl {
  final String acc;
  final String status;
  final int amt;

  AuthAppvl(this.acc, this.status, this.amt);
}

class _Badge extends StatelessWidget {
  final String svgAsset; //Re-purposed to hold logo url
  final double size;
  final Color borderColor;

  const _Badge(
    this.svgAsset, {
    Key key,
    @required this.size,
    @required this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(svgAsset + ' ' + size.toString());
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(.5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: SvgPicture.asset(
          svgAsset,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) async {
  print('Triggered ' + jsonEncode(message));

  Directory documentsDirectory = await getApplicationDocumentsDirectory();
  db_path = documentsDirectory.path + "/ver_id.db3";

//TODO:Process Transactions on Accounts that are set for Auto Accept

//Evaluate the message for auto approval
  if (!db.isOpen) {
    db = await openDatabase(db_path);
  }

  List<Map> lstRslts = await db.rawQuery(
      'SELECT * FROM my_accs JOIN accs_auto_trans '
      'ON my_accs.id = accs_auto_trans.aid WHERE f_name = ? '
      'AND acc_no = ? ',
      [message['data']['Sent By'], message['data']['Acc']]);

  if (lstRslts.isNotEmpty) {
//Evaluate the Transaction date
    if (DateTime.parse(lstRslts[0]['dur'])
        .isAfter(DateTime.parse(message['data']['Trans Date']))) {
//Evaluate the Transaction amount
      int amt_limit = lstRslts[0]['amt_limit'];
      if (double.parse(message['data']['Amt']) <= amt_limit.toDouble()) {
//Process the auto approval
        if (!db.isOpen) {
          db = await openDatabase(db_path);
        }

        String actn_dte =
            new DateFormat('yyyy-MM-dd hh:mm:ss').format(new DateTime.now());

        int rslt = await db.insert('transactions', {
          'fi_name': message['data']['Sent By'],
          'fi_logo': message['data']['Logo'],
          'acc': message['data']['Acc'],
          'trans_id': message['data']['Trans ID'],
          'trans_type': message['data']['Trans Type'],
          'trans_nme': message['data']['Msg'],
          'curr_denom': message['data']['Curr'],
          'trans_amt': message['data']['Amt'],
          'date_req': message['data']['Trans Date'],
          'reg_on': actn_dte
        });

        if (rslt > 0) {
          actn_dte =
              new DateFormat('yyyy-MM-dd hh:mm:ss').format(new DateTime.now());

          int q = await db.insert('verifications', {
            'tid': rslt,
            'date_ver': message['data']['Trans Date'],
            'approved': 1,
            'reason': 'auto approved',
            'token': client_sig,
            'reg_on': actn_dte
          });

          if (q > 0) {
            List<Map> lstTrans = await db.rawQuery(
                'SELECT * FROM transactions JOIN verifications ON transactions.id = verifications.tid '
                'WHERE transactions.id = ?',
                [rslt]);

            print(jsonEncode(lstTrans));

            var response = await http.post(url, headers: {
              'x-task': 'regTrans',
              'x-API-KEY': 'P0oG6pnwuI>t*gQ*SehXqEp#x`5#Y',
              //TODO:Hide this Key from reverse engineering
              'x-FID': message['data']['FID'],
              'x-TRANS-ID': q.toString(),
              'x-TRANS-ACC': lstTrans[0]['acc'],
              'x-TRANS-DTE': lstTrans[0]['date_req'],
              'x-TRANS-TYP': lstTrans[0]['trans_type'],
              'x-TRANS-CURR': lstTrans[0]['curr_denom'],
              'x-TRANS-AMT': lstTrans[0]['trans_amt'].toString(),
              'x-TRANS-DESC': lstTrans[0]['trans_nme'],
              'x-TRANS-STS':
                  lstTrans[0]['approved'] == 1 ? 'Approved' : 'Declined',
              'x-TRANS-STS-RSN': lstTrans[0]['reason'],
              'x-VER-DTE': lstTrans[0]['date_ver']
            }, body: {
              'TKN': lstTrans[0]['token']
            });

            print('RegTrans_Response - ' + response.body);

            String upld_rslt = response.body;

            if (upld_rslt == '1') {
              //showToast(false, 'Successful Sync with ' + message['data']['Sent By']);
              //Success show result
              final storage = FlutterSecureStorage();

              String tkn = await storage.read(key: 'fcm_key');

              response = await http.post(url, headers: {
                'x-task': 'sendNoti',
                'x-API-KEY': 'P0oG6pnwuI>t*gQ*SehXqEp#x`5#Y',
                'x-DEV-ID': tkn,
                'x-ACC': message['data']['Acc'],
              }, body: {
                'CURR': message['data']['Curr'],
                'AMT': message['data']['Amt'],
                'FI': message['data']['Sent By'],
                'TD': message['data']['Trans Date'],
                'FI_IMG': message['data']['Logo']
              });

              print('Noti Response ' + response.body);
            }
          }
        }
      }
    }
    await db.close();
//Auto approval failed resort to backup
//TODO:Restart Authentication process
  } else {
    print('No Auto Approval Set');
  }
  if (message.containsKey('data')) {
// Handle data message
    final dynamic data = message['data'];
  }

  if (message.containsKey('notification')) {
// Handle notification message
    final dynamic notification = message['notification'];
  }

  return Future<void>.value();
}
