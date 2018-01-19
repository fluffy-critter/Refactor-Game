# ugh this is such a mess, maybe I should use cmake or scons or something

# itch.io target
TARGET="fluffy/Refactor"

# game directory
SRC=src

# build directory
DEST=build

# build dependencies directory
DEPS=build_deps

# Application name
NAME=Refactor

# LOVE version to fetch and build against
LOVE_VERSION=0.10.2

# Version of the game - whenever this changes, set a tag for v$(BASEVERSION) for the revision base
BASEVERSION=0.3.0

# Determine the full version string based on the tag
COMMITHASH=$(shell git rev-parse --short HEAD)
COMMITTIME=$(shell expr `git show -s --format=format:%at` - `git show -s --format=format:%at v$(BASEVERSION)`)
GAME_VERSION=$(BASEVERSION).$(COMMITTIME)-$(COMMITHASH)

GITSTATUS=$(shell git status --porcelain | grep -q . && echo "dirty" || echo "clean")

# Which track to include in the current jam build
JAM_TRACK=track7

.PHONY: clean all run
.PHONY: publish publish-precheck publish-love publish-osx publish-win32 publish-win64
.PHONY: publish-jam publish-osx-jam publish-win32-jam publish-win64-jam
.PHONY: publish-all
.PHONY: publish-status publish-wait
.PHONY: commit-check
.PHONY: love-bundle osx win32 win64 bundle-win32
.PHONY: jam love-jam osx-jam win32-jam win64-jam
.PHONY: submodules tests checks version

all: submodules checks tests love-bundle osx win32 win64 bundle-win32

clean:
	rm -rf build

submodules:
	git submodule update --init --recursive

version:
	@echo "$(GAME_VERSION)"

publish: publish-precheck publish-love publish-osx publish-win32 publish-win64 publish-status
	@echo "Done publishing build $(GAME_VERSION)"

publish-all: publish publish-jam

publish-jam: publish-love-jam publish-osx-jam publish-win32-jam publish-win64-jam

jam: love-jam osx-jam win32-jam win64-jam

publish-precheck: commit-check checks

publish-status:
	butler status $(TARGET)
	@ echo "Current version: $(GAME_VERSION)"

publish-wait:
	@ while butler status $(TARGET) | grep '•' ; do sleep 5 ; done

commit-check:
	@ [ "$(GITSTATUS)" == "dirty" ] && echo "You have uncommitted changes" && exit 1 || exit 0

tests:
	@which love 1>/dev/null || (echo \
		"love (https://love2d.org/) must be on the path to run the unit tests" \
		&& false )
	love $(SRC) --cute-headless

checks:
	@which luacheck 1>/dev/null || (echo \
		"Luacheck (https://github.com/mpeterv/luacheck/) is required to run the static analysis checks" \
		&& false )
	find src -name '*.lua' | grep -v thirdparty | xargs luacheck -q

run: love-bundle
	love $(DEST)/love/$(NAME).love

# hacky way to inject the distfiles content
$(DEST)/%/LICENSE: LICENSE $(wildcard distfiles/*)
	echo $(@)
	mkdir -p $(shell dirname $(@))
	cp LICENSE distfiles/* $(shell dirname $(@))

# download build-dependency stuff
$(DEPS)/love/%:
	echo $(@)
	mkdir -p $(DEPS)/love
	curl -L -o $(@) https://bitbucket.org/rude/love/downloads/$(shell basename $(@))

publish-love: $(DEST)/.published-love-$(GAME_VERSION)
$(DEST)/.published-love-$(GAME_VERSION): $(DEST)/love/$(NAME).love $(DEST)/love/LICENSE
	butler push $(DEST)/love $(TARGET):love-bundle --userversion $(GAME_VERSION) && touch $(@)

# .love bundle
love-bundle: submodules $(DEST)/love/$(NAME).love
$(DEST)/love/$(NAME).love: $(shell find $(SRC) -type f)
	echo $(@)
	mkdir -p $(DEST)/love && \
	cd $(SRC) && \
	rm -f ../$(@) && \
	zip -9r ../$(@) . -x 'test'

# .love bundle, jam-specific
love-jam: submodules $(DEST)/love-jam/$(NAME)-jam.love
$(DEST)/love-jam/$(NAME)-jam.love: $(shell find $(SRC) -type f)
	echo $(@)
	mkdir -p $(DEST)/love-jam && \
	cd $(SRC) && \
	rm -f ../$(@) && \
	zip -9r ../$(@) . -x 'track*' 'track*/**' 'test' 'test/**' && \
	zip -9r ../$(@) $(JAM_TRACK)

publish-love-jam: publish $(DEST)/.published-love-jam-$(GAME_VERSION)
$(DEST)/.published-love-jam-$(GAME_VERSION): $(DEST)/love-jam/$(NAME)-jam.love $(DEST)/love-jam/LICENSE
	butler push $(DEST)/love-jam $(TARGET):love-jam --userversion $(GAME_VERSION) && touch $(@)

# macOS version
osx: $(DEST)/osx/$(NAME).app
$(DEST)/osx/$(NAME).app: $(DEST)/love/$(NAME).love $(wildcard osx/*) $(DEST)/deps/love.app
	echo $(@)
	mkdir -p $(DEST)/osx
	rm -rf $(@)
	cp -r "$(DEST)/deps/love.app" $(@) && \
	sed 's/{TITLE}/$(NAME)/' osx/Info.plist > $(@)/Contents/Info.plist && \
	cp osx/*.icns $(@)/Contents/Resources/ && \
	cp $(DEST)/love/$(NAME).love $(@)/Contents/Resources

osx-jam: $(DEST)/osx-jam/$(NAME)-jam.app
$(DEST)/osx-jam/$(NAME)-jam.app: $(DEST)/love-jam/$(NAME)-jam.love $(wildcard osx/*) $(DEST)/deps/love.app
	echo $(@)
	mkdir -p $(DEST)/osx-jam
	rm -rf $(@)
	cp -r "$(DEST)/deps/love.app" $(@) && \
	sed 's/{TITLE}/$(NAME) (jam version)/' osx/Info.plist > $(@)/Contents/Info.plist && \
	cp osx/*.icns $(@)/Contents/Resources/ && \
	cp $(DEST)/love-jam/$(NAME)-jam.love $(@)/Contents/Resources


publish-osx: $(DEST)/.published-osx-$(GAME_VERSION)
$(DEST)/.published-osx-$(GAME_VERSION): $(DEST)/osx/$(NAME).app $(DEST)/osx/LICENSE
	butler push $(DEST)/osx $(TARGET):osx --userversion $(GAME_VERSION) && touch $(@)

publish-osx-jam: $(DEST)/.published-osx-$(GAME_VERSION)
$(DEST)/.published-osx-jam-$(GAME_VERSION): $(DEST)/osx-jam/$(NAME)-jam.app $(DEST)/osx-jam/LICENSE
	butler push $(DEST)/osx-jam $(TARGET):osx-jam --userversion $(GAME_VERSION) && touch $(@)

# OSX build dependencies
$(DEST)/deps/love.app: $(DEPS)/love/love-$(LOVE_VERSION)-macosx-x64.zip
	echo $(@)
	mkdir -p $(DEST)/deps && \
	unzip -d $(DEST)/deps $(^)
	touch $(@)

# Windows build dependencies
WIN32_ROOT=$(DEST)/deps/love-$(LOVE_VERSION)-win32
WIN64_ROOT=$(DEST)/deps/love-$(LOVE_VERSION)-win64

$(WIN32_ROOT)/love.exe: $(DEPS)/love/love-$(LOVE_VERSION)-win32.zip
	echo $(@)
	mkdir -p $(DEST)/deps/
	unzip -d $(DEST)/deps $(^)
	touch $(@)

$(WIN64_ROOT)/love.exe: $(DEPS)/love/love-$(LOVE_VERSION)-win64.zip
	echo $(@)
	mkdir -p $(DEST)/deps/
	unzip -d $(DEST)/deps $(^)
	touch $(@)

# Win32 version
win32: $(WIN32_ROOT)/love.exe $(DEST)/win32/$(NAME).exe
$(DEST)/win32/$(NAME).exe: windows/refactor-win32.exe $(DEST)/love/$(NAME).love
	echo $(@)
	mkdir -p $(DEST)/win32
	cp -r $(wildcard $(WIN32_ROOT)/*.dll) $(WIN32_ROOT)/license.txt $(DEST)/win32
	cat $(^) > $(@)

win32-jam: $(WIN32_ROOT)/love.exe $(DEST)/win32-jam/$(NAME)-jam.exe
$(DEST)/win32-jam/$(NAME)-jam.exe: windows/refactor-win32.exe $(DEST)/love-jam/$(NAME)-jam.love
	echo $(@)
	mkdir -p $(DEST)/win32-jam
	cp -r $(wildcard $(WIN32_ROOT)/*.dll) $(WIN32_ROOT)/license.txt $(DEST)/win32-jam
	cat $(^) > $(@)

publish-win32: $(DEST)/.published-win32-$(GAME_VERSION)
$(DEST)/.published-win32-$(GAME_VERSION): $(DEST)/win32/$(NAME).exe $(DEST)/win32/LICENSE
	butler push $(DEST)/win32 $(TARGET):win32 --userversion $(GAME_VERSION) && touch $(@)

publish-win32-jam: $(DEST)/.published-win32-jam-$(GAME_VERSION)
$(DEST)/.published-win32-jam-$(GAME_VERSION): $(DEST)/win32-jam/$(NAME)-jam.exe $(DEST)/win32-jam/LICENSE
	butler push $(DEST)/win32-jam $(TARGET):win32-jam --userversion $(GAME_VERSION) && touch $(@)

# Win64 version
win64: $(WIN64_ROOT)/love.exe $(DEST)/win64/$(NAME).exe
$(DEST)/win64/$(NAME).exe: windows/refactor-win64.exe $(DEST)/love/$(NAME).love
	echo $(@)
	mkdir -p $(DEST)/win64
	cp -r $(wildcard $(WIN64_ROOT)/*.dll) $(WIN64_ROOT)/license.txt $(DEST)/win64
	cat $(^) > $(@)

win64-jam: $(WIN64_ROOT)/love.exe $(DEST)/win64-jam/$(NAME)-jam.exe
$(DEST)/win64-jam/$(NAME)-jam.exe: windows/refactor-win64.exe $(DEST)/love-jam/$(NAME)-jam.love
	echo $(@)
	mkdir -p $(DEST)/win64-jam
	cp -r $(wildcard $(WIN64_ROOT)/*.dll) $(WIN64_ROOT)/license.txt $(DEST)/win64-jam
	cat $(^) > $(@)

publish-win64: $(DEST)/.published-win64-$(GAME_VERSION)
$(DEST)/.published-win64-$(GAME_VERSION): $(DEST)/win64/$(NAME).exe $(DEST)/win64/LICENSE
	butler push $(DEST)/win64 $(TARGET):win64 --userversion $(GAME_VERSION) && touch $(@)

publish-win64-jam: $(DEST)/.published-win64-jam-$(GAME_VERSION)
$(DEST)/.published-win64-jam-$(GAME_VERSION): $(DEST)/win64/$(NAME).exe $(DEST)/win64-jam/LICENSE
	butler push $(DEST)/win64-jam $(TARGET):win64-jam --userversion $(GAME_VERSION) && touch $(@)

WIN32_BUNDLE_FILENAME=refactor-win32-$(GAME_VERSION).zip
bundle-win32: $(DEST)/$(WIN32_BUNDLE_FILENAME)
$(DEST)/$(WIN32_BUNDLE_FILENAME): $(DEST)/win32/$(NAME).exe $(DEST)/win32/LICENSE
	cd $(DEST)/win32 && zip -9r ../$(WIN32_BUNDLE_FILENAME) *


