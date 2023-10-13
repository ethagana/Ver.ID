import 'dart:convert';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gradient_app_bar/gradient_app_bar.dart';
import 'package:gradient_widgets/gradient_widgets.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:page_transition/page_transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:sms_retriever_api/sms_retriever_api.dart';
import 'package:unique_ids/unique_ids.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:verid/home.dart';

final String url = 'https://blueviolet.tech/ver_id/websrvc.php';

bool isDark = false;

ProgressDialog pr;

int val_cnt = 3;

String db_path;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ver.ID',
      theme: ThemeData(
        fontFamily: 'Montserrat',
        brightness: Brightness.light,
        primaryColor: Color(0xFF0279FF),
        //0xFFB400FF
        accentColor: Color(0xFF0279FF),

        //primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        fontFamily: 'Montserrat',
        brightness: Brightness.dark,
        primaryColor: Color(0xFF650dd1),
        //0xFFB400FF
        accentColor: Color(0xFF650dd1), //0xFF0279FF 0xFF34eb4f
      ),
      home: MyHomePage(title: 'VerID'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController dob_controller = TextEditingController();
  final TextEditingController tel_controller = TextEditingController();
  final TextEditingController cntry_controller = TextEditingController();

  final LocalAuthentication auth = LocalAuthentication();

  final FirebaseMessaging fcm = FirebaseMessaging();

  String usr_names;
  String usr_email;
  String usr_img;
  String otp_code;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => login());
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).platformBrightness == Brightness.dark) {
      isDark = true;
    } else {
      isDark = false;
    }
    return Scaffold(
        appBar: GradientAppBar(
            title: Text(widget.title),
            centerTitle: true,
            gradient: !isDark ? Gradients.rainbowBlue : Gradients.cosmicFusion),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Welcome',
                  style: TextStyle(
                      color: !isDark ? Colors.black : Colors.white,
                      fontSize: 54,
                      fontWeight: FontWeight.bold)),
              Text('Let\'s get started',
                  style: TextStyle(color: Colors.grey)),
              SizedBox(height: 30,),
              Theme.of(context).platform == TargetPlatform.android ? SignInButton(
                !isDark ? Buttons.Google : Buttons.GoogleDark,
                onPressed: () async {
                  bool connAvail = await valConn();
                  if(connAvail){

                    pr = ProgressDialog(this.context,type: ProgressDialogType.Normal, isDismissible: true);

                    pr.style(message: 'Processing');

                    await pr.show();

                    GoogleSignInAccount googleSignInAccount = await _googleSignIn.signIn();

                    GoogleSignInAuthentication googleSignInAuthentication =
                    await googleSignInAccount.authentication;

                    pr.update(message: 'Signing In');


                    AuthCredential credential = GoogleAuthProvider.credential(
                      accessToken: googleSignInAuthentication.accessToken,
                      idToken: googleSignInAuthentication.idToken,
                    );

                    User authUser = (await _auth.signInWithCredential(credential)).user;

                    if(authUser != null) {
                      usr_email = authUser.email;
                      usr_img = authUser.photoURL.replaceAll('s96', 's512');
                      usr_names = authUser.displayName;

                      print('Username - ' + authUser.displayName);
                      print('Email - ' + authUser.email);
                      print(
                          'pic - ' + authUser.photoURL.replaceAll('s96', 's512'));

                      await pr.hide();

                      //Request Client Phone Number and Date of birth
                      getDobTel();
                      //Register Client into VerID network
                      //Show Main
                    }

                    // pr.update(message: 'Signing Out');

                    //await _googleSignIn.signOut();



                    //Extract client name,phone number,email,icon_image


                  }
                  else {
                    showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext cxt){
                          return CupertinoAlertDialog(
                            title: Text('Sign In',style: TextStyle(fontFamily: 'Montserrat'),),
                            content: Text('Unable to Sign In\nNo connection to Blue violet Network',style: TextStyle(fontFamily: 'Montserrat')),
                            actions: [
                              CupertinoDialogAction(
                                child: Text('Ok',style: TextStyle(fontFamily: 'Montserrat')),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              )
                            ],
                          );
                        }
                    );
                  }
                },
              ) : SignInButton(
                  !isDark ? Buttons.Apple : Buttons.AppleDark,
                  onPressed: () {/* ... */})
            ],
          ),
        ),
                // This trailing comma makes auto-formatting nicer for build methods.
        );
  }

  static Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) {

    if (message.containsKey('data')) {
      // Handle data message
      final dynamic data = message['data'];
      Fluttertoast.showToast(
          msg: jsonEncode(data),
          toastLength:   Toast.LENGTH_SHORT,
          gravity:ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.white,
          textColor: Colors.black ,
          fontSize: 16.0);
    }
  }

  login() async {
    final storage = FlutterSecureStorage();

    if(await storage.read(key: 'usrid') != null) {

      bool canCheckBiometrics = await auth.canCheckBiometrics;
      if (canCheckBiometrics) {
        try{
        bool didAuthenticate = await auth.authenticateWithBiometrics(
            localizedReason: 'Please authenticate to access VerID',
            useErrorDialogs: false);

        if(didAuthenticate){
         //Check if region set
          if(await storage.read(key: 'country') != null){
            if(await storage.read(key: 'fcm_key') != null) {
              //iniFCM();
              iniDB();
              Navigator.pushReplacement(
                  this.context,
                  PageTransition(
                      type: PageTransitionType.fade,
                      child: MyHome()));
            }
            else {
              //Get the cloud message id
              String fcm_tkn = await fcm.getToken();
              print('FCM-Key '+fcm_tkn);
              //iniFCM();
              iniDB();
              await storage.write(key: 'fcm_key', value: fcm_tkn);
              await regToken(fcm_tkn,await storage.read(key: 'usrid'));
              Navigator.pushReplacement(
                  this.context,
                  PageTransition(
                      type: PageTransitionType.fade,
                      child: MyHome()));
            }
          }
          else {
            //Get the users country
            getCountry();
          }
        }
        else {
          val_cnt--;
          if(val_cnt > 0) {
            //Notify User not
            showDialog(
                context: this.context,
                barrierDismissible: false,
                builder: (BuildContext cxt){
                  return CupertinoAlertDialog(
                    title: Text('User Verification',style: TextStyle(fontFamily: 'Montserrat'),),
                    content: Text('Verification Failed\nYou have '+val_cnt.toString()+' tries remaining',style: TextStyle(fontFamily: 'Montserrat')),
                    actions: [
                      CupertinoDialogAction(
                        child: Text('Ok',style: TextStyle(fontFamily: 'Montserrat')),
                        onPressed: () {
                          Navigator.pop(cxt);
                          login();
                        },
                      )
                    ],
                  );
                }
            );
          }
          else {
            showDialog(
                context: this.context,
                barrierDismissible: false,
                builder: (BuildContext cxt){
                  return CupertinoAlertDialog(
                    title: Text('User Verification',style: TextStyle(fontFamily: 'Montserrat'),),
                    content: Text('Verification Failure\nVerID will now exit',style: TextStyle(fontFamily: 'Montserrat')),
                    actions: [
                      CupertinoDialogAction(
                        child: Text('Ok',style: TextStyle(fontFamily: 'Montserrat')),
                        onPressed: () {
                          Navigator.pop(cxt);
                          exit(0);
                        },
                      )
                    ],
                  );
                }
            );
          }
        }
        }
        on PlatformException catch(e){
          if(e.code == auth_error.permanentlyLockedOut){
            custMsg('Authentication', 'VerID Locked awaiting PIN/Password/Pattern Input');
          }
        }
      }
      else {
        showDialog(
            context: this.context,
            barrierDismissible: false,
            builder: (BuildContext cxt){
              return CupertinoAlertDialog(
                title: Text('User Login',style: TextStyle(fontFamily: 'Montserrat'),),
                content: Text('Device Lacks Biometric Verification Capability',style: TextStyle(fontFamily: 'Montserrat')),
                actions: [
                  CupertinoDialogAction(
                    child: Text('Ok',style: TextStyle(fontFamily: 'Montserrat')),
                    onPressed: () {
                      Navigator.pop(cxt);
                      exit(0);
                    },
                  )
                ],
              );
            }
        );
      }
    }
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

  void iniFCM(){
    fcm.configure(onMessage: (Map<String, dynamic> message) async {
      print("onMessage_AppActive: $message");

      //proMsg(message['data']['list_name'], message['data']['message']);
    }, onLaunch: (Map<String, dynamic> message) async {
      print("onLaunch_AppActive: $message");

      //proMsg(message['data']['list_name'], message['data']['message']);
    }, onResume: (Map<String, dynamic> message) async {
      print("onLaunch_AppResume: $message");

      //proMsg(message['title'], message['data']['message']);
    },
        onBackgroundMessage: myBackgroundMessageHandler);
  }

  Future<void> iniDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    db_path = documentsDirectory.path + "/ver_id.db3";
    if (FileSystemEntity.typeSync(db_path) == FileSystemEntityType.notFound) {
      ByteData data = await rootBundle.load('database/ver_id.db3');
      List<int> bytes =
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      // Save copied asset to documents
      await new File(db_path).writeAsBytes(bytes);

      print('Database Copied');
    }
    else {
      print('Database Exists');
    }

  }

  Future<bool> valConn() async{
    var connectivityResult = await (Connectivity().checkConnectivity());
    if(connectivityResult != ConnectivityResult.none){
      //Check for connection to the blueviolet network
      try {
        final result = await InternetAddress.lookup('blueviolet.tech');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          //Internet present continue to login
          return true;
        }
      } on SocketException catch(_) {
        //Error suspend login process
      }
    }
    return false;
  }

  void getDobTel() {
    showDialog(context: this.context,
        barrierDismissible: false,
        builder: (BuildContext context){
          return CupertinoAlertDialog(
            key: formKey,
            title: Text('User Registration Completion',style: TextStyle(fontFamily: 'Montserrat'),),
            content: Material(
              child: Stack(
                children: [
                  Container(
                    height: 180,
                    child: Padding(padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: dob_controller,
                            decoration: InputDecoration(
                                focusedBorder: const OutlineInputBorder(
                                    borderSide: const BorderSide(
                                        color: Color(0xFF34eb4f), width: 1.0)),
                                border: OutlineInputBorder(),
                                labelText: "Date of Birth"),
                            onTap: () async {
                              FocusScope.of(context)
                                  .requestFocus(new FocusNode());

                              DateTime selDT = await showDatePicker(
                                  context: context,
                                  initialDate: new DateTime(
                                      DateTime.now().year - 18,
                                      DateTime.now().month,
                                      DateTime.now().day),
                                  firstDate: DateTime(1900),
                                  lastDate: new DateTime(DateTime.now().year - 18,
                                      DateTime.now().month, DateTime.now().day));

                              if (selDT != null) {
                                dob_controller.text =
                                    selDT.toIso8601String().substring(0, 10);
                              }
                            },

                          ),
                          SizedBox(height: 10,),
                          TextField(//TODO: Build a mask for verifying USA numbers
                              controller: tel_controller,
                              maxLength: 12,
                              decoration: InputDecoration(
                                  focusedBorder: const OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color:Color(0xFF34eb4f), width: 1.0)),
                                  border: OutlineInputBorder(),
                                  errorText: valTel(),
                                  labelText: "Mobile Number"),
                              keyboardType: TextInputType.phone
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: Text('Register',style: TextStyle(fontFamily: 'Montserrat')),
                onPressed: () async {
                  if (dob_controller.text.isNotEmpty) {
                    if (tel_controller.text.length >= 10) {
                      String pattern = r'(^(?:[+0]9)?[0-9]{12}$)';
                      RegExp regExp = new RegExp(pattern);
                      if(regExp.hasMatch(tel_controller.text)) {
                        Navigator.pop(context);
                        pr.update(message: 'Verifying Mobile Number');
                        pr.show();
                        verTel();
                        //Generate the OTP Code
                        var response = await http.post(url, headers: {
                          'x-task': 'verTel',
                          'x-api-key':'P0oG6pnwuI>t*gQ*SehXqEp#x`5#Y',
                          'x-SIGN': await SmsRetrieverApi.getAppSignature(),
                          'x-TEL': tel_controller.text
                        });

                        print('OTP_Response: ' + response.body);

                        otp_code = response.body;

                        pr.update(message: 'Awaiting OTA Code');
                      }
                      else {
                        showToast(true, 'Please Enter a Valid Mobile Number');
                      }
                    }
                    else {
                      showToast(true, 'Please Enter your Mobile Number');
                    }
                  }
                  else {
                    showToast(true, 'Please Select your Date of Birth');
                  }
                },
              ),
              CupertinoDialogAction(
                child: Text('Cancel',style: TextStyle(fontFamily: 'Montserrat')),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ],
          );
        }
    );
  }

  String valTel(){
    if(tel_controller.text.length < 12 && tel_controller.text.isNotEmpty){
      return 'Int prefix missing';
    }
    return null;
  }

  void showToast(bool isError,String msg) {
    Fluttertoast.showToast(
        msg: msg,
        toastLength:  isError ? Toast.LENGTH_SHORT: Toast.LENGTH_SHORT,
        gravity: isError ? ToastGravity.CENTER : ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: isError ? Colors.red: Colors.white,
        textColor: Colors.black ,
        fontSize: 16.0);
  }



  Future<void> verTel() async {
    String sign;
    SmsRetrieverApi.getAppSignature().then((signature) {
      sign = signature;
      print(signature); // use it in sms body.
      return SmsRetrieverApi.startListening();
    }).then((x) async {
      String smsCode = x.replaceAll(sign, '').trim(); // otp code (digit only)
      print("sms - $smsCode");

      List<String> arr1 = smsCode.split(' ');
      print(arr1);
      String f_code = arr1[arr1.indexOf('is') + 1].trim();
      print("F_Code - $f_code");

      //stop listening for sms
      SmsRetrieverApi.stopListening();

      if(otp_code == f_code){
        //We are good save data in cloud and generate the user_id
        showToast(false, 'Mobile Number Authenticated');
        pr.update(message: 'Generating User ID...');
        regUser();
      }


    }).catchError((_) {
      print("sms error " + _.toString());
    });




  }

  Future<void> regUser() async {

    //Generate Unique ID
    String uuid;

    try {
      if(Theme.of(this.context).platform == TargetPlatform.android) {
        uuid = await UniqueIds.uuid;
      }
      else if(Theme.of(this.context).platform == TargetPlatform.iOS){
        uuid = await UniqueIds.adId;
      }
    } on PlatformException {
      uuid = 'Failed to create uuid.v1';
    }

    var response = await http.post(url, headers: {
      'x-task': 'regUser',
      'x-API-KEY':'P0oG6pnwuI>t*gQ*SehXqEp#x`5#Y',
      'x-USR': uuid,
      'x-EMAIL':usr_email,
      'x-DOB':dob_controller.text,
      'x-TEL': tel_controller.text
    });

    print('RegUsr_Response - '+response.body);

    if(response.body != '0'){

      //Success so save data securely
      final storage = FlutterSecureStorage();
      await storage.write(key: 'usrid', value: response.body);
      await storage.write(key: 'usr_nme', value: usr_names);
      await storage.write(key: 'usr_pic', value: usr_img);
      await storage.write(key: 'usr_tel', value: tel_controller.text);
      await storage.write(key: 'uuid', value: uuid);

      //Show the welcome dialog
      pr.hide();
      showDialog(
          context: this.context,
          barrierDismissible: false,
          builder: (BuildContext cxt){
            return CupertinoAlertDialog(
              title: Text('User Registration',style: TextStyle(fontFamily: 'Montserrat'),),
              content: Text('Welcome to the VerID Family',style: TextStyle(fontFamily: 'Montserrat')),
              actions: [
                CupertinoDialogAction(
                  child: Text('Ok',style: TextStyle(fontFamily: 'Montserrat')),
                  onPressed: () {
                    Navigator.pop(cxt);
                    login();
                  },
                )
              ],
            );
          }
      );
    }
    else {
      pr.hide();
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext cxt){
            return CupertinoAlertDialog(
              title: Text('User Registration',style: TextStyle(fontFamily: 'Montserrat'),),
              content: Text('Unable to Sign In\nTry again later',style: TextStyle(fontFamily: 'Montserrat')),
              actions: [
                CupertinoDialogAction(
                  child: Text('Ok',style: TextStyle(fontFamily: 'Montserrat')),
                  onPressed: () {
                    Navigator.pop(cxt);
                  },
                )
              ],
            );
          }
      );
    }

  }

  void getCountry() {

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext cxt){
          return CupertinoAlertDialog(
            key: formKey,
            title: Text('User Region',style: TextStyle(fontFamily: 'Montserrat'),),
            content: Material(
              child: Stack(
                children: [
                  Container(
                    //height: 180,
                    child: Padding(padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: cntry_controller,
                            decoration: InputDecoration(
                                focusedBorder: const OutlineInputBorder(
                                    borderSide: const BorderSide(
                                        color: Color(0xFF34eb4f), width: 1.0)),
                                border: OutlineInputBorder(),
                                labelText: "Enter your Country"),
                                keyboardType: TextInputType.name,
                          ),

                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: Text('Register',style: TextStyle(fontFamily: 'Montserrat')),
                onPressed: () async {
                  if (cntry_controller.text.isNotEmpty) {
                    Navigator.pop(context);
                    if(pr == null){
                      pr = ProgressDialog(this.context,type: ProgressDialogType.Normal, isDismissible: true);

                      pr.style(message: 'Processing');
                    }else {
                      pr.update(message: 'Processing....');
                    }
                    pr.show();

                    String url = 'https://restcountries.eu/rest/v2/name/'+cntry_controller.text.trim();

                    //Get the country name and currency
                    var response = await http.get(url);

                    print('GetCountry_Response: ' + response.body);

                    List<Map> rslts = List<Map>.from(jsonDecode(response.body));

                    print('Name of Country '+rslts[0]['name']);
                    print('Currencies '+rslts[0]['currencies'][0]['code']);
                    print('Flag '+rslts[0]['flag']);

                    final storage = FlutterSecureStorage();
                    await storage.write(key: 'country', value: rslts[0]['name']);
                    await storage.write(key: 'currency', value: rslts[0]['currencies'][0]['code']);
                    await storage.write(key: 'flag', value: rslts[0]['flag']);

                    showToast(false, 'Region Registered Successfully');

                    //pr.hide();
                    String fcm_tkn = await fcm.getToken();
                    print('FCM-Key '+fcm_tkn);
                    iniFCM();
                    iniDB();
                    await storage.write(key: 'fcm_key', value: fcm_tkn);
                    await regToken(fcm_tkn,await storage.read(key: 'usrid'));

                    //Show Main
                    Navigator.pushReplacement(
                        this.context,
                        PageTransition(
                            type: PageTransitionType.fade,
                            child: MyHome()));
                  }
                  else {
                    showToast(true, 'Please Enter your Country Name');
                  }
                },
              ),

            ],
          );
        }
    );
  }

  Future<void> regToken(String fcm_tkn,String uuid) async {

    if(pr == null){
      pr = ProgressDialog(this.context,type: ProgressDialogType.Normal, isDismissible: true);

      pr.style(message: 'Registering Token...');

      pr.show();
    }else {
      pr.update(message: 'Registering Token...');
    }

    var response = await http.post(url, headers: {
      'x-task': 'regToken',
      'x-API-KEY':'P0oG6pnwuI>t*gQ*SehXqEp#x`5#Y',
      'x-UUID': uuid,
      'x-FCM-TOKEN':fcm_tkn
    });

    print('RegToken_Response - '+response.body);

    if(response.body != '0'){
      showToast(false, 'Messaging Ready');
    }

    pr.hide();
  }

}

