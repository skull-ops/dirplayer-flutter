class ScriptFlags {
	static const int kScriptFlagUnused		= (1 << 0x0);
	static const int kScriptFlagFuncsGlobal	= (1 << 0x1);
	static const int kScriptFlagVarsGlobal	= (1 << 0x2);	// Occurs in event scripts (which have no local vars). Correlated with use of alternate global var opcodes.
	static const int kScriptFlagUnk3			= (1 << 0x3);
	static const int kScriptFlagFactoryDef	= (1 << 0x4);
	static const int kScriptFlagUnk5			= (1 << 0x5);
	static const int kScriptFlagUnk6			= (1 << 0x6);
	static const int kScriptFlagUnk7			= (1 << 0x7);
	static const int kScriptFlagHasFactory	= (1 << 0x8);
	static const int kScriptFlagEventScript	= (1 << 0x9);
	static const int kScriptFlagEventScript2	= (1 << 0xa);
	static const int kScriptFlagUnkB			= (1 << 0xb);
	static const int kScriptFlagUnkC			= (1 << 0xc);
	static const int kScriptFlagUnkD			= (1 << 0xd);
	static const int kScriptFlagUnkE			= (1 << 0xe);
	static const int kScriptFlagUnkF			= (1 << 0xf);
}
