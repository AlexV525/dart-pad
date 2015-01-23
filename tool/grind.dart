// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dartpad_server.grind;

import 'dart:convert' show JSON;
import 'dart:io';

import 'package:grinder/grinder.dart';
import 'package:librato/librato.dart';

void main(List<String> args) {
  task('init', defaultInit);
  task('travis-bench', travisBench, ['init']);
  task('clean', defaultClean);

  startGrinder(args);
}

/**
 * Run the benchmarks on the build-bot; upload the data to librato.com.
 */
travisBench(GrinderContext context) {
  context.log('Running benchmarks...');

  Librato librato = new Librato.fromEnvVars();
  if (Platform.environment['TRAVIS_COMMIT'] == null) {
    context.fail('Missing env var: TRAVIS_COMMIT');
  }

  ProcessResult result = Process.runSync(
      'dart', ['benchmark/bench.dart', '--json']);
  if (result.exitCode != 0) {
    context.fail('benchmarks exit code: ${result.exitCode}');
  }

  List results = JSON.decode(result.stdout);
  Map stats = {};

  results.forEach((r) {
    context.log('${r}');
    stats.addAll(r);
  });

  context.log('Uploading stats to ${librato.url}');
  return librato.postStats(
      stats, groupName: Platform.environment['TRAVIS_COMMIT']);
}
