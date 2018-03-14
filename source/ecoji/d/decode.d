module ecoji.d.decode;

import ecoji.d.mapping;

import std.array : array;
import std.range : isInputRange, ElementType, walkLength, popFrontN, takeExactly, front, empty;
import std.string : indexOf, assumeUTF;
import std.format : format;

version(unittest) import fluent.asserts;

class DecodingException : Exception {
	@safe pure @nogc nothrow this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

template decode(Range) 
if(isInputRange!Range && is(ElementType!Range : dchar)) {
	auto decode(Range r) {
		return decodeImpl(r);
	}

	private struct decodeImpl {
		private {
			Range m_range;
			bool m_empty;
			ubyte[5] m_buffer;
			size_t m_index = 0;
			size_t m_length = 0;
		}

		this(Range r) {
			m_range = r;
			this.popFront;
		}

		@property auto front() { return m_buffer[m_index]; }
		@property auto empty() { return m_empty; }

		void popFront() {
			if(++m_index < m_length)
				return;

			if(m_range.empty) {
				m_empty = true;
				return;
			}

			if(m_range.walkLength(4) < 4)
				throw new DecodingException("Unexpected end of data");
			
			m_length = 0;
			m_index = 0;

			dchar[4] runes = m_range.takeExactly(4).array;
			m_range.popFrontN(4);

			if(EMOJIS.indexOf(runes[0]) == -1)
				throw new DecodingException(format!"Invalid rune `%s`"(runes[0]));

			int bits1 = runes[0].runeOf;
			int bits2 = runes[1].runeOf;
			int bits3 = runes[2].runeOf;
			int bits4;

			switch(runes[3]) {
			case PADDING40: bits4 = 0; break;
			case PADDING41: bits4 = 1 << 8; break;
			case PADDING42: bits4 = 2 << 8; break;
			case PADDING43: bits4 = 3 << 8; break;
			default: bits4 = runes[3].runeOf; break;
			}

			m_buffer[0] = cast(ubyte) (bits1 >> 2);
			m_buffer[1] = cast(ubyte) (((bits1 & 0x3)  << 6) | (bits2 >> 4));
			m_buffer[2] = cast(ubyte) (((bits2 & 0xF)  << 4) | (bits3 >> 6));
			m_buffer[3] = cast(ubyte) (((bits3 & 0x3F) << 2) | (bits4 >> 8));
			m_buffer[4] = cast(ubyte) (bits4  & 0xFF);

			foreach(i; 1..4) {
				++m_length;
				if(runes[i] == PADDING)
					return;
			}

			++m_length;
			if(runes[3] == PADDING40 || runes[3] == PADDING41 || runes[3] == PADDING42 || runes[3] == PADDING43)
				return;
			++m_length;
		}
	}

	private @safe pure nothrow @nogc int runeOf(dchar d) {
		auto t = cast(int) EMOJIS.indexOf(d);
		return t == -1 ? 0 : t;
	}
}

@("decode() returns valid input range")
unittest {
	static assert(isInputRange!(typeof([EMOJIS['o' << 2], PADDING, PADDING, PADDING].decode)));
}

@("decode() is @safe")
@safe unittest {
	[EMOJIS['o' << 2], PADDING, PADDING, PADDING].decode;
}

@("decode() is pure")
pure unittest {
	[EMOJIS['o' << 2], PADDING, PADDING, PADDING].decode;
}

@("decode() works for encoded 1-byte values")
unittest {
	[EMOJIS['o' << 2], PADDING, PADDING, PADDING].decode.array.should.be.equal([ubyte('o')]);
	[EMOJIS['k' << 2], PADDING, PADDING, PADDING].decode.array.should.be.equal([ubyte('k')]);
}

@("decode() works for encoded 2-byte values")
unittest {
	[
		EMOJIS[0],
		EMOJIS[16],
		PADDING,
		PADDING,
	].decode.array.should.be.equal([ubyte(0), ubyte(1)]);
}

@("decode() works for encoded 3-byte values")
unittest {
	[
		EMOJIS[0],
		EMOJIS[16],
		EMOJIS[128],
		PADDING,
	].decode.array.should.be.equal([ubyte(0), ubyte(1), ubyte(2)]);
}

@("decode() works for encoded 4-byte values")
unittest {
	[
		EMOJIS[0],
		EMOJIS[16],
		EMOJIS[128],
		PADDING40,
	].decode.array.should.be.equal([ubyte(0), ubyte(1), ubyte(2), ubyte(0)]);

	[
		EMOJIS[0],
		EMOJIS[16],
		EMOJIS[128],
		PADDING41,
	].decode.array.should.be.equal([ubyte(0), ubyte(1), ubyte(2), ubyte(1)]);

	[
		EMOJIS[0],
		EMOJIS[16],
		EMOJIS[128],
		PADDING42,
	].decode.array.should.be.equal([ubyte(0), ubyte(1), ubyte(2), ubyte(2)]);

	[
		EMOJIS[0],
		EMOJIS[16],
		EMOJIS[128],
		PADDING43,
	].decode.array.should.be.equal([ubyte(0), ubyte(1), ubyte(2), ubyte(3)]);
}

@("decode() works for encoded 5-byte values")
unittest {
	[
		EMOJIS[687],
		EMOJIS[222],
		EMOJIS[960],
		EMOJIS[291],
	].decode.array.should.be.equal([ubyte(0xAB), ubyte(0xCD), ubyte(0xEF), ubyte(0x01), ubyte(0x23)]);
}

@("decode() can decode encoded strings")
unittest {
	"👖📸🎈☕".decode.array.assumeUTF.should.be.equal("abc");
	"🎥🤠📠🏍".decode.array.assumeUTF.should.be.equal("6789");
	"🐲👡🕟☕".decode.array.assumeUTF.should.be.equal("XY\n");
	"🏗📩🎦🐇🎛📘🔯🚜💞😽🆖🐊🎱🥁🚄🌱💞😭💮🇵💢🕥🐭🔸🍉🚲🦑🐶💢🕥🔮🔺🍉📸🐮🌼👦🚟🥴📑"
		.decode.array.assumeUTF.should.be.equal("Base64 is so 1999, isn't there something better?\n");
}

@("decode() throws an exception if end of data is reached unexpectedly")
unittest {
	({
		[EMOJIS[1], EMOJIS[2], EMOJIS[3]].decode;
	}).should.throwException!DecodingException
		.msg.should.be.equal("Unexpected end of data");

	({
		[EMOJIS[1], EMOJIS[2]].decode;
	}).should.throwException!DecodingException
		.msg.should.be.equal("Unexpected end of data");

	({
		[EMOJIS[1]].decode;
	}).should.throwException!DecodingException
		.msg.should.be.equal("Unexpected end of data");
}

@("decode() throws an exception if rune is invalid")
unittest {
	({
		['N', 'O', 'T', 'V', 'A', 'L', 'I', 'D'].decode;
	}).should.throwException!DecodingException
		.msg.should.be.equal("Invalid rune `N`");
}