#!/usr/bin/env dub
/+
dub.json:
{
	"name": "hash",
	"description": "Example of using different hash functions with ecoji-d",
	"dependencies": {
		"ecoji-d": { "path": "../" }
	}
}
+/

import ecoji.d;

import std.stdio : writeln, writefln;
import std.digest.crc;
import std.digest.md;
import std.digest.ripemd;
import std.digest.sha;

void main() {
	"hash function | input | hash | ecoji-encoded".writeln;
	"Ecoji is cool".hash!crc32Of;
	"Emojis are cool".hash!crc64ECMAOf;
	"Very good".hash!crc64ISOOf;
	"Dead hash function btw".hash!md5Of;
	"Very nice".hash!ripemd160Of;
	"Somebody once".hash!sha224Of;
	"Told me".hash!sha256Of;
}

void hash(alias FUNC)(string i) {
	"%s | %s | %(%02x%) | %s"
		.writefln(FUNC.stringof, i, FUNC(i), FUNC(i)[].encode);
}