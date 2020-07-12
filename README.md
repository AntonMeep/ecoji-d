ecoji-d 👦🔉🦐🔼🍽🔓☕☕ [![Page on DUB](https://img.shields.io/dub/v/ecoji-d.svg?style=flat-square)](http://code.dlang.org/packages/ecoji-d)[![License](https://img.shields.io/dub/l/ecoji-d.svg?style=flat-square)](https://github.com/ohdatboi/ecoji-d/blob/master/LICENSE)[![Build Status TravisCI](https://img.shields.io/travis/ohdatboi/ecoji-d/master.svg?style=flat-square)](https://travis-ci.org/ohdatboi/ecoji-d)
========

**ecoji-d** implements [Ecoji](https://github.com/keith-turner/ecoji) encoding standard using the D programming language.

Ecoji-d encodes data as base1024 but with emoji character set.

Visit [ecoji.io](https://ecoji.io) to try Ecoji in your browser.

## Usage

**ecoji-d** can be used both as a library or as a CLI utility, in both cases [D compiler](https://dlang.org/download.html) and [dub](https://code.dlang.org/download) are required:

### As a library

#### Installation

You can find **ecoji-d** on the [D package registry](http://code.dlang.org/packages/ecoji-d).

#### API

API consists of 2 modules:

1. [ecoji.d.encode](source/ecoji/d/encode.d), which provides encoding functionality
2. [ecoji.d.decode](source/ecoji/d/decode.d), which provides decoding functionality

You can import modules individally or import `ecoji.d` which will do this for you:

```D
import ecoji.d;
```

Once it is imported you can call functions of **ecoji-d**:

```D
auto encode(Range)(Range r) if(isInputRange!Range && is(ElementType!Range : ubyte));
```

This function takes a range of `ubyte`s or `char`s and returns a range of `dchar`s.

```D
auto decode(Range)(Range r) if(isInputRange!Range && is(ElementType!Range : dchar));
```

This functions takes a range of `dchar`s and returns a range of `ubyte`s.


Both encoding and decoding happen *lazily* which decreases memory consumption and increases speed.

### As a CLI utility

#### Installation

```
$ dub fetch ecoji-d
```

#### Usage

```
$ dub run ecoji-d -- [OPTIONS] [FILES]
Usage: ./ecoji-d [OPTIONS] [FILES]
-e --encode Encode data (default).
-d --decode Decode data.
-o --output Output file (default: stdout).
-h   --help This help information.
```

If no input file is specified, stdin is used.















