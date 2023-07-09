/*class NetTask {
  String url;

  NetTask(this.url);
}*/

import 'dart:io';
import 'dart:typed_data';
import 'package:dirplayer/common/util.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;


import '../../director/lingo/datum.dart';
import 'net_task.dart';

class NetManager {
  Uri basePath = getBaseUri(Uri.base);
  List<NetTask> tasks = [];

  NetTask? findTaskWithUrl(String url) {
    return tasks.where((element) => element.url == url).firstOrNull;
  }

  NetTask? findTaskWithId(int id) {
    return tasks.where((element) => element.id == id).firstOrNull;
  }

  NetTask? findTask(Datum? idOrUrl) {
    if (idOrUrl != null) {
      if (idOrUrl.isInt()) {
        return findTaskWithId(idOrUrl.toInt());
      } else {
        return findTaskWithUrl(idOrUrl.stringValue());
      }
    } else {
      return tasks.lastOrNull;
      //var isLoading = movie.castManager.casts.any((element) => element.isExternal && element.isLoading);
    }
  }

  NetTask preloadNetThing(String url) {
    var existingTask = findTaskWithUrl(url);
    if (existingTask != null) {
      return existingTask;
    }

    var task = NetTask(tasks.length + 1, url, normalizeTaskUrl(url));
    tasks.add(task);
    executeTask(task);
    return task;
  }

  Uri normalizeTaskUrl(String url) {
    url = url.replaceAll("\\", "/");
    var uri = Uri.parse(url);
    if (uri.host.isNotEmpty) {
      return Uri.parse(uri.toString());
    } else if (p.isAbsolute(url)) {
      return Uri.parse("file:///$url");
    } else {
      return basePath.resolve(url);
    }
  }

  Future<NetResult> awaitNetTask(NetTask task) async {
    return await task.completer.future;
  }

  NetTask getNetText(String url) {
    var task = preloadNetThing(url);
    print("TODO load text $url");
    return task;
  }

  void clear() {
    for (var task in tasks) {
      // TODO cancel task
    }
    tasks.clear();
  }

  Future executeTask(NetTask task) async {
    var uri = task.resolvedUri;
    if (kIsWeb || uri.host.isNotEmpty) {
      return await executeRemoteTask(task);
    } else {
      return await executeLocalTask(task);
    }
  }

  Future executeLocalTask(NetTask task) async {
    NetResult taskResult;

    var file = File(task.resolvedUri.toFilePath());
    if (await file.exists()) {
      taskResult = NetResultSuccess(await file.readAsBytes());
    } else {
      taskResult = NetResultError(Exception("File not found ${task.url}"));
    }

    task.result = taskResult;
    task.completer.complete(taskResult);
  }

  Future executeRemoteTask(NetTask task) async {
    NetResult taskResult;
    try {
      var uri = task.resolvedUri;
      var resp = await http.get(uri);
      if (resp.statusCode == 200) {
        taskResult = NetResultSuccess(resp.bodyBytes);
      } else {
        taskResult = NetResultError(Exception("Net request failed with code ${resp.statusCode}"));
      }
    } on Exception catch(err) {
      taskResult = NetResultError(err);
    }
    
    task.result = taskResult;
    task.completer.complete(taskResult);
  }
}
