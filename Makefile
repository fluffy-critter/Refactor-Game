# ugh this is such a mess, maybe I should use cmake or scons or something

# itch.io target
TARGET=fluffy/Refactor

# game directory
SRC=src

# build directory
DEST=build

# build dependencies directory
DEPS=build_deps

# Application name
NAME=Refactor
BUNDLE_ID=biz.beesbuzz.Refactor

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

# supported publish channels
CHANNELS=love osx win32 win64

.PHONY: clean all run
.PHONY: publish publish-precheck publish-jam publish-all
.PHONY: publish-status publish-wait
.PHONY: commit-check
.PHONY: love-bundle osx win32 win64 bundle-win32
.PHONY: love-jam osx-jam win32-jam win64-jam
.PHONY: submodules tests checks version

# necessary to expand the PUBLISH_CHANNELS variable for the publish rules
.SECONDEXPANSION:

# don't remove secondary files
.SECONDARY:

publish-dep=$(DEST)/.published-$(GAME_VERSION)_$(1)
PUBLISH_CHANNELS=$(foreach tgt,$(CHANNELS),$(call publish-dep,$(tgt)))
JAM_CHANNELS=$(foreach tgt,$(CHANNELS),$(call publish-dep,$(tgt)-jam))

all: submodules checks tests love-bundle osx win32 win64 bundle-win32

clean:
	rm -rf build

submodules:
	git submodule update --init --recursive

version:
	@echo "$(GAME_VERSION)"

publish-all: publish publish-jam

publish: publish-precheck $$(PUBLISH_CHANNELS) publish-status
	@echo "Done publishing full build $(GAME_VERSION)"

publish-jam: publish-precheck $$(JAM_CHANNELS)
	@echo "Done publishing jam build $(GAME_VERSION)"

jam: love-jam osx-jam win32-jam win64-jam

publish-precheck: commit-check tests checks

publish-status:
	butler status $(TARGET)
	@echo "Current version: $(GAME_VERSION)"

publish-wait:
	@while butler status $(TARGET) | grep '•' ; do sleep 5 ; done

commit-check:
	@[ "$(GITSTATUS)" == "dirty" ] && echo "You have uncommitted changes" && exit 1 || exit 0

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

staging-love: love-bundle
staging-osx: osx
staging-win32: win32
staging-win64: win64

staging-love-jam: love-jam
staging-osx-jam: osx-jam
staging-win32-jam: win32-jam
staging-win64-jam: win64-jam


$(DEST)/.published-$(GAME_VERSION)_%: staging-% $(DEST)/%/LICENSE
	butler push $(DEST)/$(lastword $(subst _, ,$(@))) $(TARGET):$(lastword $(subst _, ,$(@))) --userversion $(GAME_VERSION) && touch $(@)

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

# macOS version
osx: $(DEST)/osx/$(NAME).app
$(DEST)/osx/$(NAME).app: love-bundle $(wildcard osx/*) $(DEST)/deps/love.app
	echo $(@)
	mkdir -p $(DEST)/osx
	rm -rf $(@)
	cp -r "$(DEST)/deps/love.app" $(@) && \
	sed 's/{TITLE}/$(NAME)/;s/{BUNDLE_ID}/$(BUNDLE_ID)/' osx/Info.plist > $(@)/Contents/Info.plist && \
	cp osx/*.icns $(@)/Contents/Resources/ && \
	cp $(DEST)/love/$(NAME).love $(@)/Contents/Resources

osx-jam: $(DEST)/osx-jam/$(NAME)-jam.app
$(DEST)/osx-jam/$(NAME)-jam.app: love-jam $(wildcard osx/*) $(DEST)/deps/love.app
	echo $(@)
	mkdir -p $(DEST)/osx-jam
	rm -rf $(@)
	cp -r "$(DEST)/deps/love.app" $(@) && \
	sed 's/{TITLE}/$(NAME) (jam version)/;s/{BUNDLE_ID}/$(BUNDLE_ID)Jam/' osx/Info.plist > $(@)/Contents/Info.plist && \
	cp osx/*.icns $(@)/Contents/Resources/ && \
	cp $(DEST)/love-jam/$(NAME)-jam.love $(@)/Contents/Resources

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

WIN32_BUNDLE_FILENAME=refactor-win32-$(GAME_VERSION).zip
bundle-win32: $(DEST)/$(WIN32_BUNDLE_FILENAME)
$(DEST)/$(WIN32_BUNDLE_FILENAME): $(DEST)/win32/$(NAME).exe $(DEST)/win32/LICENSE
	cd $(DEST)/win32 && zip -9r ../$(WIN32_BUNDLE_FILENAME) *
