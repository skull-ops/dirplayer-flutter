import 'file.dart';
import '../reader.dart';

enum MemberType {
	kNullMember(0),
  kBitmapMember(1),
	kFilmLoopMember(2),
	kTextMember(3),
	kPaletteMember(4),
	kPictureMember(5),
	kSoundMember(6),
	kButtonMember(7),
	kShapeMember(8),
	kMovieMember(9),
	kDigitalVideoMember(10),
	kScriptMember(11),
	kRTEMember(12),
  kMysteryMember(15);

  const MemberType(this.rawValue);
  final int rawValue;
  static MemberType fromValue(int value) => MemberType.values.firstWhere((element) => element.rawValue == value);
}

class CastMember {
  DirectorFile? dir;
  MemberType type;

  CastMember({ this.dir, required this.type });
  void read(Reader stream) { }
}

enum ScriptType {
  kInvalidScript(0),
	kScoreScript(1),
	kMovieScript(3),
	kParentScript(7);

  const ScriptType(this.rawValue);
  final int rawValue;
  static ScriptType fromValue(int value) => ScriptType.values.firstWhere((element) => element.rawValue == value);
}

class ScriptMember extends CastMember {
  ScriptType scriptType = ScriptType.kInvalidScript;

  ScriptMember(DirectorFile? dir) : super(dir: dir, type: MemberType.kScriptMember);

  @override
  void read(Reader stream) {
    scriptType = ScriptType.fromValue(stream.readUint16());
  }

  // void ScriptMember::writeJSON(Common::JSONWriter &json) const 
}
