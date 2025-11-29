import 'package:flutter/material.dart';
import 'package:flutter_plugin_example/data/model/user.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

enum FormMode { login, signUp }

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _email = "";
  String _password = "";
  String? _errorMessage = "";

  // Initial form is login form
  FormMode _formMode = FormMode.login;
  bool _isLoading = false;

  // Check if form is valid before perform login or signup
  bool _validateAndSave() {
    final FormState form = _formKey.currentState!;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  // Perform login or signup
  Future<void> _validateAndSubmit() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });
    if (_validateAndSave()) {
      final User user = User(_email, _password, _email);

      ParseResponse response;
      try {
        if (_formMode == FormMode.login) {
          response = await user.login();
          print('Signed in');
        } else {
          response = await user.signUp();
          print('Signed up user:');
        }
        setState(() {
          _isLoading = false;
        });
        if (response.success) {
          if (_formMode == FormMode.login) {
            Navigator.pop(context as dynamic, true);
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = response.error.toString();
          });
        }
      } catch (e) {
        print('Error: $e');
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void initState() {
    _errorMessage = '';
    _isLoading = false;
    super.initState();
  }

  void _changeFormToSignUp() {
    _formKey.currentState?.reset();
    _errorMessage = '';
    setState(() {
      _formMode = FormMode.signUp;
    });
  }

  void _changeFormToLogin() {
    _formKey.currentState?.reset();
    _errorMessage = '';
    setState(() {
      _formMode = FormMode.login;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Parse Server demo'),
        ),
        body: Stack(
          children: <Widget>[
            _showBody(),
            _showCircularProgress(),
          ],
        ));
  }

  Widget _showCircularProgress() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return const SizedBox(
      height: 0.0,
      width: 0.0,
    );
  }

  Widget _showBody() {
    return Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              _showLogo(),
              _showEmailInput(),
              _showPasswordInput(),
              _showPrimaryButton(),
              _showSecondaryButton(),
              _showErrorMessage(),
            ],
          ),
        ));
  }

  Widget _showErrorMessage() {
    if (_errorMessage!.isNotEmpty && _errorMessage != null) {
      return Text(
        _errorMessage!,
        style: const TextStyle(
            fontSize: 13.0,
            color: Colors.red,
            height: 1.0,
            fontWeight: FontWeight.w300),
      );
    } else {
      return Container(
        height: 0.0,
      );
    }
  }

  Widget _showLogo() {
    return Hero(
      tag: 'hero',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 70.0, 0.0, 0.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 48.0,
          child: Image.asset('assets/parse.png'),
        ),
      ),
    );
  }

  Widget _showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 100.0, 0.0, 0.0),
      child: TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: const InputDecoration(
            hintText: 'Email',
            icon: Icon(
              Icons.mail,
              color: Colors.grey,
            )),
        validator: (String? value) =>
            value!.isEmpty ? 'Email can\'t be empty' : null,
        onSaved: (String? value) => _email = value!,
      ),
    );
  }

  Widget _showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: const InputDecoration(
            hintText: 'Password',
            icon: Icon(
              Icons.lock,
              color: Colors.grey,
            )),
        validator: (String? value) =>
            value!.isEmpty ? 'Password can\'t be empty' : null,
        onSaved: (String? value) => _password = value!,
      ),
    );
  }

  Widget _showSecondaryButton() {
    return TextButton(
      onPressed: _formMode == FormMode.login
          ? _changeFormToSignUp
          : _changeFormToLogin,
      child: _formMode == FormMode.login
          ? const Text('Create an account',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300))
          : const Text('Have an account? Sign in',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
    );
  }

  Widget _showPrimaryButton() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
        child: SizedBox(
          height: 40.0,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0)),
              elevation: 5.0,
            ),
            onPressed: _validateAndSubmit,
            child: _formMode == FormMode.login
                ? const Text('Login',
                    style: TextStyle(fontSize: 20.0, color: Colors.white))
                : const Text('Create account',
                    style: TextStyle(fontSize: 20.0, color: Colors.white)),
          ),
        ));
  }
}
