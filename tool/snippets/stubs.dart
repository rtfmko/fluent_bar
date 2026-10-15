// Names that the snippets in the docs use but do not declare. Used by tool/check_snippets.dart.
// ignore_for_file: type=lint
import 'dart:async';

import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/material.dart';

class User {
  String get name => '';
}

class Order {
  String get id => '';
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class Home extends HomePage {
  const Home({super.key});
}

Api get api => Api();

dynamic get analytics => null;

dynamic get crashReporter => null;

dynamic get logger => null;

Download get download => Download();

Order get order => Order();

List<Widget> get destinations => const <Widget>[];

void openTracking([Object? id]) {}

Future<void> restore() async {}

Future<void> signIn() async {}

FluentBarEntry<void> get entry => FluentBar.find('x')! as FluentBarEntry<void>;

FluentBarController<void> get controller => entry.controller;

FluentBarItem<void> get item => entry.item;

FluentBarConfig get config => FluentBar.currentConfig;

FluentBarProgressState get state => const FluentBarProgressState.indeterminate();

void listener(FluentBarAnalyticsPayload payload) {}

void handler(FluentBarException error, StackTrace stackTrace) {}

dynamic get auth => null;

Future<void> loadFeed() async {}

Future<void> openSignIn() async {}

Future<void> openChat([Object? a]) async {}

void log([Object? a, Object? b]) {}

void startReading() {}

dynamic get dio => null;

String get url => '';

String get path => '';

class Api {
  Future<User> saveProfile() async => User();

  Future<User> getUser() async => User();

  Future<void> retry() async {}
}

class Download {
  void Function(int received, int total)? onProgress;

  Future<void> cancel() async {}
}

void retry() {}
void upload() {}

class FirebaseAnalytics {
  static final FirebaseAnalytics instance = FirebaseAnalytics();

  Future<void> logEvent({required String name, Map<String, Object>? parameters}) async {}
}

FluentBarMetrics get metrics => throw UnimplementedError();

class AppLocalizations {
  String get noConnection => '';
}

class CheckoutBody extends StatelessWidget {
  const CheckoutBody({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class DownloadTask {
  Future<void> cancel() async {}

  void start({required void Function(int received, int total) onProgress, required void Function() onDone, required void Function() onError}) {}
}

DownloadTask get task => DownloadTask();
