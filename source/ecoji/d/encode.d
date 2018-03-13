module ecoji.d.encode;

import ecoji.d.mapping;

import std.algorithm : min;
import std.array : array;
import std.range : isInputRange, ElementType, popFrontN, takeExactly, walkLength, front;
import std.utf : byChar;

version(unittest) import fluent.asserts;

template encode(Range) 
if(isInputRange!Range && is(ElementType!Range : ubyte)) {
	@safe auto encode(Range r) {
		return encodeImpl(r);
	}

	private struct encodeImpl {
		private {
			Range m_range;
			bool m_empty;
			dchar[4] m_buffer;
			size_t m_index = 4;
		}

		@safe:

		this(Range r) {
			m_range = r;
			this.popFront;
		}

		@property const auto front() { return m_buffer[m_index]; }
		@property const auto empty() { return m_empty; }
		void popFront() {
			if(m_index++ < 3)
				return;

			switch(m_range.walkLength(5).min(5)) {
			case 0:
				m_empty = true;
				return;
			case 1:
				m_buffer = [
					EMOJIS[m_range.front << 2],
					PADDING,
					PADDING,
					PADDING,
				];
				m_index = 0;
				m_range.popFrontN(1);
				break;
			case 2:
				auto tmp = m_range.takeExactly(2).array;
				m_buffer = [
					EMOJIS[tmp[0] << 2 | tmp[1] >> 6],
					EMOJIS[(tmp[1] & 0x3F) << 4],
					PADDING,
					PADDING,
				];
				m_index = 0;
				m_range.popFrontN(2);
				break;
			case 3:
				auto tmp = m_range.takeExactly(3).array;
				m_buffer = [
					EMOJIS[tmp[0] << 2          | tmp[1] >> 6],
					EMOJIS[(tmp[1] & 0x3F) << 4 | tmp[2] >> 4],
					EMOJIS[(tmp[2] & 0x0F) << 6],
					PADDING,
				];
				m_index = 0;
				m_range.popFrontN(3);
				break;
			case 4:
				auto tmp = m_range.takeExactly(4).array;
				m_buffer[0..3] = [
					EMOJIS[tmp[0] << 2          | tmp[1] >> 6],
					EMOJIS[(tmp[1] & 0x3F) << 4 | tmp[2] >> 4],
					EMOJIS[(tmp[2] & 0x0F) << 6 | tmp[3] >> 2],
				];

				final switch(tmp[3] & 0x03) {
					case 0: m_buffer[3] = PADDING40; break;
					case 1: m_buffer[3] = PADDING41; break;
					case 2: m_buffer[3] = PADDING42; break;
					case 3: m_buffer[3] = PADDING43; break;
				}

				m_index = 0;
				m_range.popFrontN(4);
				break;
			case 5:
				auto tmp = m_range.takeExactly(5).array;
				m_buffer = [
					EMOJIS[tmp[0] << 2          | tmp[1] >> 6],
					EMOJIS[(tmp[1] & 0x3F) << 4 | tmp[2] >> 4],
					EMOJIS[(tmp[2] & 0x0F) << 6 | tmp[3] >> 2],
					EMOJIS[(tmp[3] & 0x03)<<8   | tmp[4]]
				];
				m_index = 0;
				m_range.popFrontN(5);
				break;
			default:
				assert(false, "Impossible?");
			}
		}
	}
}

@("encode() works for 1-byte inputs")
unittest {
	"o".byChar.encode.array.should.be.equal([EMOJIS['o' << 2], PADDING, PADDING, PADDING]);
	"k".byChar.encode.array.should.be.equal([EMOJIS['k' << 2], PADDING, PADDING, PADDING]);
}

@("encode() works for 2-byte inputs")
unittest {
	[ubyte(0), ubyte(1)].encode.array.should.be.equal([
		EMOJIS[0],
		EMOJIS[16],
		PADDING,
		PADDING,
	]);
}

@("encode() works for 3-byte inputs")
unittest {
	[ubyte(0), ubyte(1), ubyte(2)].encode.array.should.be.equal([
		EMOJIS[0],
		EMOJIS[16],
		EMOJIS[128],
		PADDING,
	]);
}

@("encode() works for 4-byte inputs")
unittest {
	[ubyte(0), ubyte(1), ubyte(2), ubyte(0)].encode.array.should.be.equal([
		EMOJIS[0],
		EMOJIS[16],
		EMOJIS[128],
		PADDING40,
	]);
	[ubyte(0), ubyte(1), ubyte(2), ubyte(1)].encode.array.should.be.equal([
		EMOJIS[0],
		EMOJIS[16],
		EMOJIS[128],
		PADDING41,
	]);
	[ubyte(0), ubyte(1), ubyte(2), ubyte(2)].encode.array.should.be.equal([
		EMOJIS[0],
		EMOJIS[16],
		EMOJIS[128],
		PADDING42,
	]);
	[ubyte(0), ubyte(1), ubyte(2), ubyte(3)].encode.array.should.be.equal([
		EMOJIS[0],
		EMOJIS[16],
		EMOJIS[128],
		PADDING43,
	]);
}

@("encode() works for 5-byte inputs")
unittest {
	[ubyte(0xAB), ubyte(0xCD), ubyte(0xEF), ubyte(0x01), ubyte(0x23)].encode.array.should.be.equal([
		EMOJIS[687],
		EMOJIS[222],
		EMOJIS[960],
		EMOJIS[291],
	]);
}

@("encode() can encode strings")
unittest {
	"abc".byChar.encode.array.should.be.equal("👖📸🎈☕");
	"6789".byChar.encode.array.should.be.equal("🎥🤠📠🏍");
	"XY\n".byChar.encode.array.should.be.equal("🐲👡🕟☕");
	"Base64 is so 1999, isn't there something better?\n".byChar.encode.array
		.should.be.equal("🏗📩🎦🐇🎛📘🔯🚜💞😽🆖🐊🎱🥁🚄🌱💞😭💮🇵💢🕥🐭🔸🍉🚲🦑🐶💢🕥🔮🔺🍉📸🐮🌼👦🚟🥴📑");
}