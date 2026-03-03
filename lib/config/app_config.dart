enum AppEnv { local, staging, production }

enum ServiceType { supabase, custom }

class AppConfig {
  final String appName;
  final String appVersion;
  final String buildDate;
  final String webSiteUrl;
  final String apiBaseUrl;
  final String storageUrl;
  final String bucketName;
  final String storageUuid;
  final String localKey;
  final ServiceType serviceType;

  const AppConfig({
    required this.appName,
    required this.appVersion,
    required this.buildDate,
    required this.webSiteUrl,
    required this.apiBaseUrl,
    required this.storageUrl,
    required this.bucketName,
    required this.storageUuid,
    required this.localKey,
    required this.serviceType,
  });
}

const Map<String, AppConfig> configs = {
  "dev-supabase": AppConfig(
    appName: 'Easy Learning',
    appVersion: '1.0.0',
    buildDate: '2026-03-10',
    webSiteUrl: 'https://EasyLearning.com',
    apiBaseUrl: 'https://tpgyuqvncljnuyrohqre.supabase.co',
    storageUrl:
        'https://tpgyuqvncljnuyrohqre.supabase.co/storage/v1/object/public/edu_files/e1dd570d-f347-4c69-addf-6da9393e5e95',
    bucketName: "edu_files",
    storageUuid: "e1dd570d-f347-4c69-addf-6da9393e5e95",
    localKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRwZ3l1cXZuY2xqbnV5cm9ocXJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc4NDIxMTMsImV4cCI6MjA2MzQxODExM30.7FbAYzOpsJ7sNGM-2H5kzy5zQLN-SgO2KcRCtTiJu60',
    serviceType: ServiceType.supabase,
  )
};

const String appEnvString = String.fromEnvironment(
  'APP_ENV',
  defaultValue: 'dev-supabase',
);

final AppConfig appConfig = configs[appEnvString]!;
