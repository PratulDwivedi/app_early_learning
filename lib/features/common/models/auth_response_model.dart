class AuthResponseModel {
  final String? accessToken;
  final String? refreshToken;
  final String? msg;

  const AuthResponseModel({this.accessToken, this.refreshToken, this.msg});

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      msg: json['msg'] as String?,
    );
  }
}
