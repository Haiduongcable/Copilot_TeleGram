enum Flavor {
  development,
  staging,
  production;

  bool get isDevelopment => this == Flavor.development;
  bool get isStaging => this == Flavor.staging;
  bool get isProduction => this == Flavor.production;
}
