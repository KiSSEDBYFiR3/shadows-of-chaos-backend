// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserAuthResponse _$UserAuthResponseFromJson(Map<String, dynamic> json) =>
    UserAuthResponse(
      id: json['id'] as int,
      email: json['email'] as String,
      refreshToken: json['refresh_token'] as String,
      accessToken: json['access_token'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$UserAuthResponseToJson(UserAuthResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'email': instance.email,
      'name': instance.name,
      'refresh_token': instance.refreshToken,
      'access_token': instance.accessToken,
    };
