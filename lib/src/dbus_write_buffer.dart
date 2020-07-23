import "dart:convert";
import "dart:typed_data";

import "dbus_buffer.dart";
import "dbus_value.dart";

class DBusWriteBuffer extends DBusBuffer {
  var data = List<int>();

  writeByte(int value) {
    data.add(value);
  }

  writeBytes(Iterable<int> value) {
    data.addAll(value);
  }

  writeInt16(int value) {
    var bytes = Uint8List(2).buffer;
    ByteData.view(bytes).setInt16(0, value, Endian.little);
    writeBytes(bytes.asUint8List());
  }

  writeUint16(int value) {
    var bytes = Uint8List(2).buffer;
    ByteData.view(bytes).setUint16(0, value, Endian.little);
    writeBytes(bytes.asUint8List());
  }

  writeInt32(int value) {
    var bytes = Uint8List(4).buffer;
    ByteData.view(bytes).setInt32(0, value, Endian.little);
    writeBytes(bytes.asUint8List());
  }

  writeUint32(int value) {
    var bytes = Uint8List(4).buffer;
    ByteData.view(bytes).setUint32(0, value, Endian.little);
    writeBytes(bytes.asUint8List());
  }

  writeInt64(int value) {
    var bytes = Uint8List(8).buffer;
    ByteData.view(bytes).setInt64(0, value, Endian.little);
    writeBytes(bytes.asUint8List());
  }

  writeUint64(int value) {
    var bytes = Uint8List(8).buffer;
    ByteData.view(bytes).setUint64(0, value, Endian.little);
    writeBytes(bytes.asUint8List());
  }

  writeFloat64(double value) {
    var bytes = Uint8List(8).buffer;
    ByteData.view(bytes).setFloat64(0, value, Endian.little);
    writeBytes(bytes.asUint8List());
  }

  setByte(int offset, int value) {
    data[offset] = value;
  }

  writeValue(DBusValue value) {
    if (value is DBusByte) {
      writeByte((value as DBusByte).value);
    } else if (value is DBusBoolean) {
      align(getAlignment(value));
      writeUint32((value as DBusBoolean).value ? 1 : 0);
    } else if (value is DBusInt16) {
      align(getAlignment(value));
      writeInt16((value as DBusInt16).value);
    } else if (value is DBusUint16) {
      align(getAlignment(value));
      writeUint16((value as DBusUint16).value);
    } else if (value is DBusInt32) {
      align(getAlignment(value));
      writeInt32((value as DBusInt32).value);
    } else if (value is DBusUint32) {
      align(getAlignment(value));
      writeUint32((value as DBusUint32).value);
    } else if (value is DBusInt64) {
      align(getAlignment(value));
      writeInt64((value as DBusInt64).value);
    } else if (value is DBusUint64) {
      align(getAlignment(value));
      writeUint64((value as DBusUint64).value);
    } else if (value is DBusDouble) {
      align(getAlignment(value));
      writeFloat64((value as DBusDouble).value);
    } else if (value is DBusString) {
      var data = utf8.encode((value as DBusString).value);
      writeValue(DBusUint32(data.length));
      for (var d in data) writeByte(d);
      writeByte(0); // Terminating nul.
    } else if (value is DBusSignature) {
      var data = utf8.encode((value as DBusSignature).value);
      writeByte(data.length);
      for (var d in data) writeByte(d);
      writeByte(0);
    } else if (value is DBusVariant) {
      var childValue = (value as DBusVariant).value;
      writeValue(childValue.signature);
      writeValue(childValue);
    } else if (value is DBusStruct) {
      align(getAlignment(value));
      var children = (value as DBusStruct).children;
      for (var child in children) writeValue(child);
    } else if (value is DBusArray) {
      // Length will be overwritten later.
      writeValue(DBusUint32(0));
      var lengthOffset = data.length - 4;

      var children = (value as DBusArray).children;
      if (children.length > 0) align(getAlignment(children[0]));
      var startOffset = data.length;
      for (var child in children) writeValue(child);

      // Update the length that was written
      var length = data.length - startOffset;
      setByte(lengthOffset + 0, (length >> 0) & 0xFF);
      setByte(lengthOffset + 1, (length >> 8) & 0xFF);
      setByte(lengthOffset + 2, (length >> 16) & 0xFF);
      setByte(lengthOffset + 3, (length >> 24) & 0xFF);
    } else if (value is DBusDict) {
      // Length will be overwritten later.
      writeValue(DBusUint32(0));
      var lengthOffset = data.length - 4;

      var children = (value as DBusDict).children;
      if (children.length > 0) align(getAlignment(children[0]));
      var startOffset = data.length;
      for (var child in children) writeValue(child);

      // Update the length that was written
      var length = data.length - startOffset;
      setByte(lengthOffset + 0, (length >> 0) & 0xFF);
      setByte(lengthOffset + 1, (length >> 8) & 0xFF);
      setByte(lengthOffset + 2, (length >> 16) & 0xFF);
      setByte(lengthOffset + 3, (length >> 24) & 0xFF);
    }
  }

  int getAlignment(DBusValue value) {
    if (value is DBusByte) {
      return BYTE_ALIGNMENT;
    } else if (value is DBusBoolean) {
      return BOOLEAN_ALIGNMENT;
    } else if (value is DBusInt16) {
      return INT16_ALIGNMENT;
    } else if (value is DBusUint16) {
      return UINT16_ALIGNMENT;
    } else if (value is DBusInt32) {
      return INT32_ALIGNMENT;
    } else if (value is DBusUint32) {
      return UINT32_ALIGNMENT;
    } else if (value is DBusInt64) {
      return INT64_ALIGNMENT;
    } else if (value is DBusUint64) {
      return UINT64_ALIGNMENT;
    } else if (value is DBusDouble) {
      return DOUBLE_ALIGNMENT;
    } else if (value is DBusString) {
      return STRING_ALIGNMENT;
    } else if (value is DBusSignature) {
      return SIGNATURE_ALIGNMENT;
    } else if (value is DBusVariant) {
      return VARIANT_ALIGNMENT;
    } else if (value is DBusStruct) {
      return STRUCT_ALIGNMENT;
    } else if (value is DBusArray) {
      return ARRAY_ALIGNMENT;
    } else if (value is DBusDict) {
      return DICT_ALIGNMENT;
    }
  }

  align(int boundary) {
    while (data.length % boundary != 0) writeByte(0);
  }
}
