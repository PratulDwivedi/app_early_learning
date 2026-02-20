class AuthResponseModel {
  final String? accessToken; // required
  final String? msg;

  const AuthResponseModel({required this.accessToken, this.msg});

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['access_token'] as String,
      msg: json['msg'] as String?,
    );
  }
}
