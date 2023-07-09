import 'dart:io';
import 'dart:typed_data';

import 'package:dirplayer/common/util.dart';
import 'package:dirplayer/director/castmembers.dart';
import 'package:dirplayer/director/chunks/bitmap.dart';
import 'package:dirplayer/director/chunks/score.dart';
import 'package:dirplayer/director/chunks/text.dart';
import 'package:dirplayer/player/player.dart';
import 'package:dirplayer/player/runtime/net_task.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';

import '../player/runtime/net_manager.dart';
import 'chunk.dart';
import 'chunks/cast.dart';
import 'chunks/cast_list.dart';
import 'chunks/cast_member.dart';
import 'chunks/initial_map.dart';
import 'chunks/memory_map.dart';
import 'chunks/script.dart';
import 'chunks/script_context.dart';
import 'chunks/script_names.dart';
import 'guid.dart';
import 'subchunk.dart';
import 'util.dart';
import '../reader.dart';
import 'package:flutter/foundation.dart';

import 'chunks/config.dart';
import 'chunks/key_table.dart';


class ChunkInfo {
  int id;
  int fourCC;
  int len;
  int uncompressedLen;
  int offset;
  MoaID compressionID;

  ChunkInfo({ required this.id, required this.fourCC, required this.len, required this.uncompressedLen, required this.offset, required this.compressionID });
}

Future<DirectorFile> readDirectorFile(NetManager netManager, String path) async {
  Uint8List bytes;

  var task = netManager.preloadNetThing(path);
  var netResult = await netManager.awaitNetTask(task);
  if (netResult is NetResultSuccess) {
    bytes = netResult.bytes;
  } else {
    return Future.error("Could not load movie file $path");
  }

  var resolvedUri = task.resolvedUri;
  var dir = await readDirectorFileFromBytes(bytes, resolvedUri.pathSegments.last, getBaseUri(resolvedUri));
  return dir;
}

Future<DirectorFile> readDirectorFileFromBytes(Uint8List bytes, String fileName, Uri basePath) async {
  var reader = Reader(data: bytes.buffer);
  
  var dir = DirectorFile(basePath, fileName, reader);
  dir.read();
  dir.parseScripts();
  dir.config!.unprotect();

  return dir;
}

final FONTMAP_COMPRESSION_GUID = MoaID(0x8A4679A1, 0x3720, 0x11D0, [0x92,0x23,0x00,0xA0,0xC9,0x08,0x68,0xB1]);
final NULL_COMPRESSION_GUID =    MoaID(0xAC99982E, 0x005D, 0x0D50, [0x00,0x00,0x08,0x00,0x07,0x37,0x7A,0x34]);
final SND_COMPRESSION_GUID =     MoaID(0x7204A889, 0xAFD0, 0x11CF, [0xA2,0x22,0x00,0xA0,0x24,0x53,0x44,0x4C]);
final ZLIB_COMPRESSION_GUID =    MoaID(0xAC99E904, 0x0070, 0x0B36, [0x00,0x00,0x08,0x00,0x07,0x37,0x7A,0x34]);

class DirectorFile {
  static final log = Logger("DirectorFile");

  Uri basePath;
  String fileName;
  Reader reader;
  String fverVersionString = "";
  int _ilsBodyOffset = -1;

  Map<int, ChunkInfo> chunkInfo = {};
  Map<int, ByteBuffer> _cachedChunkViews = {};
  Map<int, Chunk> deserializedChunks = {};
  Map<int, Uint8List> _cachedChunkBufs = {};
  List<CastChunk> casts = [];
  Map<int, TextChunk> texts = {};

  KeyTableChunk? keyTable;
  ConfigChunk? config;
  int version = 0;
  bool dotSyntax = false;
  bool capitalX = false;
  Endian endian = Endian.big;
  bool afterburned = false;

  DirectorFile(this.basePath, this.fileName, this.reader);

  bool read() {
    reader.endian = Endian.big;

    var metaFourCC = reader.readUint32();
    if (metaFourCC == FOURCC("XFIR")) {
      reader.endian = Endian.little;
    }
    endian = reader.endian;

    reader.readUint32(); // meta length
    var codec = reader.readUint32();

    // Codec-dependent map
    if (codec == FOURCC("MV93") || codec == FOURCC("MC95")) {
      readMemoryMap();
    } else if (codec == FOURCC("FGDM") || codec == FOURCC("FGDC")) {
      afterburned = true;
      if (!readAfterburnerMap()) {
        return false;
      }
    } else {
      throw Exception("Codec unsupported");
    }

    if (!readKeyTable()) {
		  return false;
    }
    if (!readConfig()) {
      return false;
    }
    if (!readCasts()) {
      return false;
    }
    readTexts();

    return true;
  }

  void readTexts() {
    texts = getAllChunksOfType("STXT");
  }

  List<ChunkInfo?> getChildrenOfChunk(int chunkId) {
    var associations = keyTable!.entries.where((element) => element.castID == chunkId);
    return associations.map((e) => chunkInfo[e.sectionID]).toList();
  }

  void readMemoryMap() {
    throw Exception("TODO");
  }

  bool readAfterburnerMap() {
    int start, end;

    // File version
    if (reader.readUint32() != FOURCC("Fver")) {
      log.severe("readAfterburnerMap(): Fver expected but not found");
      return false;
    }

    var fverLength = reader.readVarInt();
    start = reader.position;
    int fverVersion = reader.readVarInt();
    log.fine("Fver: version: $fverVersion");
    if (fverVersion >= 0x401) {
      int imapVersion = reader.readVarInt();
      int directorVersion = reader.readVarInt();
      log.fine("Fver: imapVersion: $imapVersion directorVersion: 0x$directorVersion");
    }
    if (fverVersion >= 0x501) {
      int versionStringLen = reader.readUint8();
      fverVersionString = reader.readString(versionStringLen);
      log.fine("Fver: versionString: $fverVersionString");
    }
    end = reader.position;

    if (end - start != fverLength) {
      log.warning("readAfterburnerMap(): Expected Fver of length $fverLength but read ${end - start} bytes");
      reader.position = start + fverLength;
    }

    // Compression types
    if (reader.readUint32() != FOURCC("Fcdr")) {
      log.severe("readAfterburnerMap(): Fcdr expected but not found");
      return false;
    }

    var zlib = ZLibDecoder();

    var fcdrLength = reader.readVarInt();
    var fcdrUncomp = reader.readZlibBytes(fcdrLength);

    var fcdrStream = Reader(data: fcdrUncomp.buffer, endian: reader.endian);

    var compressionTypeCount = fcdrStream.readUint16();
    var compressionIds = List.generate(compressionTypeCount, (index) => MoaID.fromReader(fcdrStream));
    var compressionDescs = List.generate(compressionTypeCount, (index) => fcdrStream.readCString());

    if (fcdrStream.position != fcdrStream.data.lengthInBytes) {
      log.warning("readAfterburnerMap(): Fcdr has uncompressed length ${fcdrStream.data.lengthInBytes} but read ${fcdrStream.position} bytes");
    }

    log.fine("Fcdr: $compressionTypeCount compression types");

    for (var i = 0; i < compressionTypeCount; i++) {
      log.fine("Fcdr: type $i: ${compressionIds[i]} \"${compressionDescs[i]}\"");
    }

    if (reader.readUint32() != FOURCC("ABMP")) {
      log.severe("RIFXArchive::readAfterburnerMap(): ABMP expected but not found");
      return false;
    }

    int abmpLength = reader.readVarInt();
    int abmpEnd = reader.position + abmpLength;
    int abmpCompressionType = reader.readVarInt();
    int abmpUncompLength = reader.readVarInt();
    log.fine("ABMP: length: $abmpLength compressionType: $abmpCompressionType uncompressedLength: $abmpUncompLength");

    var abmpUncomp = reader.readZlibBytes(abmpEnd - reader.position);
    if (abmpUncomp.lengthInBytes != abmpUncompLength) {
      log.warning("ABMP: Expected uncompressed length $abmpUncompLength but got length ${abmpUncomp.lengthInBytes}");
    }
    var abmpStream = Reader(data: abmpUncomp.buffer, endian: reader.endian);
    
    int abmpUnk1 = abmpStream.readVarInt();
    int abmpUnk2 = abmpStream.readVarInt();
    int resCount = abmpStream.readVarInt();
    log.fine("ABMP: unk1: $abmpUnk1 unk2: $abmpUnk2 resCount: $resCount");

    for (var i = 0; i < resCount; i++) {
      int resId = abmpStream.readVarInt();
      int offset = abmpStream.readVarInt();
      int compSize = abmpStream.readVarInt();
      int uncompSize = abmpStream.readVarInt();
      int compressionType = abmpStream.readVarInt();
      int tag = abmpStream.readUint32();

      log.fine("Found RIFX resource index $resId: '${fourCCToString(tag)}', $compSize bytes ($uncompSize uncompressed) @ pos $offset, compressionType: $compressionType");

      var info = ChunkInfo(
        id: resId, 
        fourCC: tag, 
        len: compSize, 
        uncompressedLen: uncompSize,
        offset: offset, 
        compressionID: compressionIds[compressionType],
      );
      chunkInfo[resId] = info;
    }

    // Initial load segment
    if (!chunkInfo.containsKey(2)) {
      log.severe("readAfterburnerMap(): Map has no entry for ILS");
      return false;
    }
    if (reader.readUint32() != FOURCC("FGEI")) {
      log.severe("readAfterburnerMap(): FGEI expected but not found");
      return false;
    }

    var ilsInfo = chunkInfo[2]!;
    var ilsUnk1 = reader.readVarInt();
    log.fine("ILS: length: ${ilsInfo.len} unk1: $ilsUnk1");
    _ilsBodyOffset = reader.position;

    var ilsUncomp = reader.readZlibBytes(ilsInfo.len);
    if (ilsUncomp.length != ilsInfo.uncompressedLen) {
      log.warning("ILS: Expected uncompressed length ${ilsInfo.uncompressedLen} but got length ${ilsUncomp.length}");
    }

    var ilsStream = Reader(data: ilsUncomp.buffer, endian: reader.endian);
    while (!ilsStream.eof()) {
      int resId = ilsStream.readVarInt();
      var info = chunkInfo[resId]!;

      log.fine("Loading ILS resource $resId: '${fourCCToString(info.fourCC)}', ${info.len} bytes");
      _cachedChunkViews[resId] = ilsStream.readByteList(info.len).buffer;
    }
    return true;
  }

  bool readKeyTable() {
    var info = getFirstChunkInfo(FOURCC("KEY*"));
    if (info != null) {
      keyTable = getChunk(info.fourCC, info.id) as KeyTableChunk;
      
      for (var i = 0; i < keyTable!.usedCount; i++) {
        var entry = keyTable!.entries[i];
        var ownerTag = FOURCC("????");
        if (chunkInfo.containsKey(entry.castID)) {
          ownerTag = chunkInfo[entry.castID]!.fourCC;
        }
        log.fine("KEY* entry $i: '${fourCCToString(entry.fourCC)}' @ ${entry.sectionID} owned by '${fourCCToString(ownerTag)}' @ ${entry.castID}");
      }

      return true;
    }

    log.warning("No key chunk!");
    return false;
  }

  bool readConfig() {
    var info = getFirstChunkInfo(FOURCC("DRCF"));
    info ??= getFirstChunkInfo(FOURCC("VWCF"));

    if (info != null) {
      config = getChunk(info.fourCC, info.id) as ConfigChunk;
      version = humanVersion(config!.directorVersion);
      dotSyntax = (version >= 700);

      return true;
    }

    log.warning("No config chunk!");
    return false;
  }

  T? getFirstChunk<T>(String fourcc) {
    var info = getFirstChunkInfo(FOURCC(fourcc));
    if (info != null) {
      return getChunk(info.fourCC, info.id) as T;
    } else {
      return null;
    }
  }

  Map<int, T> getAllChunksOfType<T extends Chunk>(String fourCC) {
    var chunkInfos = chunkInfo.entries.where((entry) => entry.value.fourCC == FOURCC(fourCC));
    return Map.fromEntries(
      chunkInfos.map((e) => MapEntry(e.key, getChunk<T>(e.value.fourCC, e.value.id)))
    );
  }

  ScoreChunk? getScoreChunk() {
    return getFirstChunk<ScoreChunk>("VWSC");
  }

  CastListChunk? getCastListChunk() {
    return getFirstChunk<CastListChunk>("MCsL");
  }

  CastChunk getCastChunk(int sectionID) {
    return getChunk(FOURCC("CAS*"), sectionID) as CastChunk;
  }

  CastChunk? getCastChunkForCastId(int castID) {
    var keyEntry = findKeyTableEntryForCast(castID);
    if (keyEntry != null) {
      return getCastChunk(keyEntry.sectionID);
    } else {
      return null;
    }
  }

  KeyTableEntry? findKeyTableEntry(bool predicate(KeyTableEntry)) {
    return keyTable?.entries.where((element) => predicate(element)).firstOrNull;
  }

  KeyTableEntry? findKeyTableEntryForCast(int castID) {
    return findKeyTableEntry((keyEntry) => keyEntry.castID == castID && keyEntry.fourCC == FOURCC("CAS*"));
  }

  bool readCasts() {
    bool internal = true;

    if (version >= 500) {
      var castList = getCastListChunk();
      if (castList != null) {
        for (var castEntry in castList.entries) {
          log.fine("Cast: ${castEntry.name}");
          var cast = getCastChunkForCastId(castEntry.id);
          if (cast != null) {
            cast.populate(castEntry.name, castEntry.id, castEntry.minMember);
            casts.add(cast);
          }
        }

        return true;
      } else {
        internal = false;
      }
    }

    var cast = getFirstChunk<CastChunk>("CAS*");
    if (cast != null) {
      cast.populate(internal ? "Internal" : "External", 1024, config!.minMember);
      casts.add(cast);

      return true;
    }

    log.warning("No cast!");
    return false;
  }

  ChunkInfo? getFirstChunkInfo(int fourCC) {
    return chunkInfo.values.where((element) => element.fourCC == fourCC).firstOrNull;
  }

  bool chunkExists(int fourCC, int id) {
    if (!chunkInfo.containsKey(id)) {
      return false;
    }

    if (fourCC != chunkInfo[id]!.fourCC) {
      return false;
    }

    return true;
  }

  T getChunk<T extends Chunk>(int fourCC, int id) {
    if (deserializedChunks.containsKey(id)) {
      return deserializedChunks[id]! as T;
    }

    var chunkView = getChunkData(fourCC, id);
    var chunk = makeChunk(fourCC, chunkView);

    deserializedChunks[id] = chunk;

    return chunk as T;
  }

  Chunk makeChunk(int fourCC, ByteBuffer view) {
    Chunk? res;
    switch (fourCCToString(fourCC)) {
      case "imap":
        res = InitialMapChunk(dir: this);
        break;
      case "mmap":
        res = MemoryMapChunk(dir: this);
        break;
      case "CAS*":
        res = CastChunk(dir: this);
        break;
      case "CASt":
        res = CastMemberChunk(dir: this);
        break;
      case 'KEY*':
        res = KeyTableChunk(dir: this);
        break;
      case "LctX":
      case "Lctx":
        capitalX = fourCC == FOURCC("LctX");
        res = ScriptContextChunk(dir: this);
        break;
      case "Lnam":
        res = ScriptNamesChunk(dir: this);
        break;
      case "Lscr":
        res = ScriptChunk(dir: this);
        break;
      case "VWCF":
      case "DRCF":
        res = ConfigChunk(dir: this);
        break;
      case "MCsL":
        res = CastListChunk(dir: this);
        break;
      case "VWSC":
        res = ScoreChunk(dir: this);
      case "STXT":
        res = TextChunk(dir: this);
      case "BITD":
        res = BitmapChunk(dir: this);
      default:
        throw Exception("Could not deserialize '${fourCCToString(fourCC)}' chunk");
    }

    var chunkReader = Reader(data: view, endian: reader.endian);
    res.read(chunkReader, version);

    return res;
  }

  ByteBuffer getChunkData(int fourCC, int id) {
    if (!chunkInfo.containsKey(id)) {
      throw Exception("Could not find chunk $id");
    }

    var info = chunkInfo[id]!;
    if (fourCC != info.fourCC) {
      throw Exception("Expected chunk $id to be '${fourCCToString(fourCC)}', but is actually '${fourCCToString(info.fourCC)}'");
    }

    if (_cachedChunkViews.containsKey(id)) {
      return _cachedChunkViews[id]!;
    }

    if (afterburned) {
      reader.position = info.offset + _ilsBodyOffset;
      if (info.len == 0 && info.uncompressedLen == 0) {
        _cachedChunkViews[id] = reader.readByteList(info.len).buffer;
      } else if (compressionImplemented(info.compressionID)) {
        Uint8List? uncompBuf;
        //_cachedChunkBufs[id] = Uint8List(info.uncompressedLen);
        if (info.compressionID == ZLIB_COMPRESSION_GUID) {
          uncompBuf = reader.readZlibBytes(info.len);
        } else if (info.compressionID == SND_COMPRESSION_GUID) {
          // TODO line 406-409
          throw Exception("TODO");
        }
        if (uncompBuf == null) {
          throw Exception("Chunk $id: Could not decompress");
        }
        if (uncompBuf.lengthInBytes != info.uncompressedLen) {
          throw Exception("Chunk $id: Expected uncompressed length ${info.uncompressedLen} but got length ${uncompBuf.lengthInBytes}");
        }
        _cachedChunkBufs[id] = uncompBuf;
        _cachedChunkViews[id] = uncompBuf.buffer;
      } else if (info.compressionID == FONTMAP_COMPRESSION_GUID) {
        // TODO line 424
        throw Exception("TODO");
      } else {
        if (info.compressionID != NULL_COMPRESSION_GUID) {
          log.warning("Unhandled compression type ${info.compressionID}");
        }
        _cachedChunkViews[id] = reader.readByteList(info.len).buffer;
      }
    } else {
      reader.position = info.offset;
      _cachedChunkViews[id] = readChunkData(fourCC, info.len);
    }

    return _cachedChunkViews[id]!;
  }

  ByteBuffer readChunkData(int fourCC, int len) {
    int offset = reader.position;

    int validFourCC = reader.readUint32();
    int validLen = reader.readUint32();

    // use the valid length if mmap hasn't been read yet
    if (len == UINT32_MAX) {
      len = validLen;
    }

    // validate chunk
    if (fourCC != validFourCC || len != validLen) {
      throw Exception("At offset $offset expected ${fourCCToString(fourCC)} chunk with length $len, but got ${fourCCToString(validFourCC)} chunk with length $validLen");
    } else {
      log.warning("At offset $offset reading chunk '${fourCCToString(fourCC)}' with length $len");
    }

    return reader.readByteList(len).buffer;
  }

  bool compressionImplemented(MoaID compressionID) {
    return compressionID == ZLIB_COMPRESSION_GUID || compressionID == SND_COMPRESSION_GUID;
  }

  void parseScripts() {
    for (var cast in casts) {
      var lctx = cast.lctx;
      if (lctx == null) {
        continue;
      }

      lctx.parseScripts();
    }
  }
}
