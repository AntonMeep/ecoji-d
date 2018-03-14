module app;

import ecoji.d;

import std.algorithm : map, copy, joiner;
import std.getopt : getopt, config, defaultGetoptPrinter;
import std.stdio : File, stdin, stdout, writef;
import std.string : assumeUTF;
import std.utf : byDchar;

enum Mode {
	Encode,
	Decode,
}

version(unittest) {

} else {
	void main(string[] args) {
		Mode mode;
		string output;

		auto r = args.getopt(
			config.stopOnFirstNonOption,
			"encode|e", "Encode data (default).", { mode = Mode.Encode; },
			"decode|d", "Decode data.", { mode = Mode.Decode; },
			"output|o", "Output file (default: stdout).", &output, 
		);

		auto outFile = output ? File(output, "w") : stdout;

		if(r.helpWanted) {
			"Usage: %s [OPTIONS] [FILES]".writef(args[0]);
			"".defaultGetoptPrinter(r.options);
			return;
		}

		final switch(mode) with(Mode) {
			case Encode:
				if(args.length == 1 || args[1] == "-") {
					stdin.byChunk(4096).joiner.encode.copy(outFile.lockingTextWriter);
				} else {
					args[1..$]
						.map!(a => File(a, "r").byChunk(4096).joiner)
						.joiner
						.encode
						.copy(outFile.lockingTextWriter);
				}
				break;
			case Decode:
				if(args.length == 1 || args[1] == "-") {
					stdin.byChunk(4096).map!assumeUTF.joiner.byDchar.decode.copy(outFile.lockingBinaryWriter);
				} else {
					args[1..$]
						.map!(a => File(a, "r").byChunk(4096).map!assumeUTF.joiner)
						.joiner
						.byDchar
						.decode
						.copy(outFile.lockingBinaryWriter);
				}
				break;
		}
	}
}