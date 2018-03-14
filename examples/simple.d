#!/usr/bin/env dub
/+
dub.json:
{
	"name": "simple",
	"description": "Simple example",
	"dependencies": {
		"ecoji-d": { "path": "../" }
	}
}
+/

import ecoji.d;

import std.array : array;
import std.stdio : writeln;
import std.string : assumeUTF;
import std.utf : byChar;

void main() {
	"Simple encoding example".byChar.encode.writeln;
	"🐞🖌🛳🌴👥📘🏧🐴💎🔙🔮🔺🍉🔪📪🐾💒😑🐑☕".decode.array.assumeUTF.writeln;
}