import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

({String id, String password, String? error}) getUserFromNfcCard(NfcTag tag) {
  try {
    return (
      id: (tag.data["nfca"]["identifier"] as List<int>).join(),
      password: base64
          .encode(utf8
              .encode(tag.data.toString().padLeft(50, '0').substring(0, 50)))
          .replaceAll("=", ""),
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
