import 'dart:typed_data';

import 'package:dirplayer/reader.dart';

import '../../common/codewriter.dart';
import '../chunk.dart';
import '../lingo/flags.dart';
import '../lingo/handler.dart';
import '../subchunk.dart';
import 'cast_member.dart';
import 'script_context.dart';

class ScriptChunk extends Chunk {
	/*  8 */ int totalLength = 0;
	/* 12 */ int totalLength2 = 0;
	/* 16 */ int headerLength = 0;
	/* 18 */ int scriptNumber = 0;
	/* 20 */ int unk20 = 0;
	/* 22 */ int parentNumber = 0;

	/* 38 */ int scriptFlags = 0;
	/* 42 */ int unk42 = 0;
	/* 44 */ int castID = 0;
	/* 48 */ int factoryNameID = 0;
	/* 50 */ int handlerVectorsCount = 0;
	/* 52 */ int handlerVectorsOffset = 0;
	/* 56 */ int handlerVectorsSize = 0;
	/* 60 */ int propertiesCount = 0;
	/* 62 */ int propertiesOffset = 0;
	/* 66 */ int globalsCount = 0;
	/* 68 */ int globalsOffset = 0;
	/* 72 */ int handlersCount = 0;
	/* 74 */ int handlersOffset = 0;
	/* 78 */ int literalsCount = 0;
	/* 80 */ int literalsOffset = 0;
	/* 84 */ int literalsDataCount = 0;
	/* 88 */ int literalsDataOffset = 0;

	List<int> propertyNameIDs = [];
	List<int> globalNameIDs = [];

	String factoryName = "";
	List<String> propertyNames = [];
	List<String> globalNames = [];
	List<Handler> handlers = [];
	List<LiteralStore> literals = [];
	List<ScriptChunk> factories = [];

	ScriptContextChunk? context;
	CastMemberChunk? member;


	ScriptChunk({ required super.dir, super.chunkType = ChunkType.kScriptChunk });
  
  @override
  void read(Reader stream, int dirVersion) {
    // Lingo scripts are always big endian regardless of file endianness
    stream.endian = Endian.big;

    stream.position = 8;
    /*  8 */ totalLength = stream.readUint32();
    /* 12 */ totalLength2 = stream.readUint32();
    /* 16 */ headerLength = stream.readUint16();
    /* 18 */ scriptNumber = stream.readUint16();
    /* 20 */ unk20 = stream.readInt16();
    /* 22 */ parentNumber = stream.readInt16();
    
    stream.position = 38;
    /* 38 */ scriptFlags = stream.readUint32();
    /* 42 */ unk42 = stream.readInt16();
    /* 44 */ castID = stream.readInt32();
    /* 48 */ factoryNameID = stream.readInt16();
    /* 50 */ handlerVectorsCount = stream.readUint16();
    /* 52 */ handlerVectorsOffset = stream.readUint32();
    /* 56 */ handlerVectorsSize = stream.readUint32();
    /* 60 */ propertiesCount = stream.readUint16();
    /* 62 */ propertiesOffset = stream.readUint32();
    /* 66 */ globalsCount = stream.readUint16();
    /* 68 */ globalsOffset = stream.readUint32();
    /* 72 */ handlersCount = stream.readUint16();
    /* 74 */ handlersOffset = stream.readUint32();
    /* 78 */ literalsCount = stream.readUint16();
    /* 80 */ literalsOffset = stream.readUint32();
    /* 84 */ literalsDataCount = stream.readUint32();
    /* 88 */ literalsDataOffset = stream.readUint32();

    propertyNameIDs = readVarnamesTable(stream, propertiesCount, propertiesOffset);
	  globalNameIDs = readVarnamesTable(stream, globalsCount, globalsOffset);

    handlers = List.generate(handlersCount, (index) => Handler(this));
    if ((scriptFlags & ScriptFlags.kScriptFlagEventScript != 0) && handlersCount > 0) {
      handlers[0].isGenericEvent = true;
    }

    stream.position = handlersOffset;
    for (var handler in handlers) {
      handler.readRecord(stream);
    }
    for (var handler in handlers) {
      handler.readData(stream);
    }

    stream.position = literalsOffset;
    literals = List.generate(literalsCount, (index) => LiteralStore());
    for (var literal in literals) {
      literal.readRecord(stream, dir.version);
    }
    for (var literal in literals) {
      literal.readData(stream, literalsDataOffset);
    }
  }

  List<int> readVarnamesTable(Reader stream, int count, int offset) {
    stream.position = offset;
    return List.generate(count, (index) => stream.readInt16());
  }

  /*
	std::vector<int16_t> readVarnamesTable(Common::ReadStream &stream, uint16_t count, uint32_t offset);
	*/
  bool validName(int id) {
    return context?.validName(id) ?? false;
  }

	String getName(int id) {
    return context?.getName(id) ?? "";
  }

	void setContext(ScriptContextChunk ctx) {
    context = ctx;
    if (factoryNameID != -1) {
      factoryName = getName(factoryNameID);
    }
    for (var nameID in propertyNameIDs) {
      if (validName(nameID)) {
        String name = getName(nameID);
        if (isFactory() && name == "me") {
          continue;
        }
        propertyNames.add(name);
      }
    }
    for (var nameID in globalNameIDs) {
      if (validName(nameID)) {
        globalNames.add(getName(nameID));
      }
    }
    for (var handler in handlers) {
      handler.readNames();
    }
  }

	void parse() {
    for (var handler in handlers) {
      handler.parse();
    }
  }

	void writeVarDeclarations(CodeWriter code) {
    if (!isFactory()) {
      if (propertyNames.isNotEmpty) {
        code.write("property ");
        for (int i = 0; i < propertyNames.length; i++) {
          if (i > 0) {
            code.write(", ");
          }
          code.write(propertyNames[i]);
        }
        code.writeEmptyLine();
      }
    }
    if (globalNames.isNotEmpty) {
      code.write("global ");
      for (int i = 0; i < globalNames.length; i++) {
        if (i > 0) {
          code.write(", ");
        }
        code.write(globalNames[i]);
      }
      code.writeEmptyLine();
    }
  }

	void writeScriptText(CodeWriter code) {
    int origSize = code.size();
    writeVarDeclarations(code);
    if (isFactory()) {
      if (code.size() != origSize) {
        code.writeEmptyLine();
      }
      code.write("factory ");
      code.writeLine(factoryName);
    }
    for (int i = 0; i < handlers.length; i++) {
      if ((!isFactory() || i > 0) && code.size() != origSize) {
        code.writeEmptyLine();
      }
      handlers[i].ast!.writeScriptText(code, dir.dotSyntax, false);
    }
    for (var factory in factories) {
      if (code.size() != origSize) {
        code.writeEmptyLine();
      }
      factory.writeScriptText(code);
    }
  }

	String scriptText(String lineEnding) {
    var code = CodeWriter(lineEnding: lineEnding);
    writeScriptText(code);
    return code.str();
  }

	void writeBytecodeText(CodeWriter code) {
    int origSize = code.size();
    writeVarDeclarations(code);
    if (isFactory()) {
      if (code.size() != origSize) {
        code.writeEmptyLine();
      }
      code.write("factory ");
      code.writeLine(factoryName);
    }
    for (int i = 0; i < handlers.length; i++) {
      if ((!isFactory() || i > 0) && code.size() != origSize) {
        code.writeEmptyLine();
      }
      handlers[i].writeBytecodeText(code);
    }
    for (var factory in factories) {
      if (code.size() != origSize) {
        code.writeEmptyLine();
      }
      factory.writeBytecodeText(code);
    }
  }

	String bytecodeText(String lineEnding) {
    var code = CodeWriter(lineEnding: lineEnding);
    writeBytecodeText(code);
    return code.str();
  }

	//virtual void writeJSON(Common::JSONWriter &json) const;

	bool isFactory() => scriptFlags & ScriptFlags.kScriptFlagFactoryDef != 0;
}
