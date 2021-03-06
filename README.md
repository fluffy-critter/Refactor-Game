# Refactor

An ongoing project to turn the [Sockpuppet](http://sockpuppet.us) album [Refactor](http://music.sockpuppet.us/album/refactor) into the game for which it is a soundtrack.

Official builds of the game are available [on itch.io](http://fluffy.itch.io/refactor). Also feel free to support me [on Patreon](http://patreon.com/fluffy).

This game and music is &copy;2017 j "[fluffy](http://beesbuzz.biz)" shagam; please see `LICENSE` for further copyright terms.

## Building from source

To build you need to have the following things installed:

* [LÖVE](http://love2d.org), with the `love` executable somewhere on the path
* A reasonable UNIXy userspace (Linux or macOS preferred, mingw should be fine if you know what you're doing)
* `wget`, `unzip`, and `make` installed
* [luacheck](https://github.com/mpeterv/luacheck) (installable via `luarocks install luacheck`)
* Probably a bit of patience

The easy way to run it is `make run` which assembles the `Refactor.love` bundle and runs it through the installed LÖVE executable. `make` on its own will build all platforms' executables and run the unit tests/static analysis/etc. See `Makefile` for more targets.
