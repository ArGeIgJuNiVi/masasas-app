import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:pointycastle/export.dart';

({String password, String id, String? error}) getUserFromNfcCard(NfcTag tag) {
  try {
    return (
      id: hex.encode(MD5Digest().process(utf8.encode(jsonEncode(tag.data)))),
      password: hex.encode(SHA256Digest()
          .process(utf8.encode(jsonEncode(tag.data["nfca"]["identifier"])))),
      error: null
    );
  } catch (e) {
    if (kDebugMode) print(e);
    return (
      error: "NFC card not supported",
      id: "",
      password: "",
    );
  }
}
