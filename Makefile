# itch.io target
TARGET="fluffy/Refactor"

# game directory
SRC=src

# build directory
DEST=build

# Application name
NAME=Refactor

# LOVE version to fetch and build against
LOVE_VERSION=0.10.2

# Version of the game
GAME_VERSION=$(shell git rev-parse --short HEAD)

GITSTATUS=$(shell git status --porcelain | grep -q . && echo "dirty" || echo "clean")

.PHONY: clean all run
.PHONY: publish publish-precheck publish-love publish-osx publish-win32 publish-win64 publish-status publish-wait
.PHONY: love-bundle osx win32 win64
.PHONY: assets setup tests checks

all: checks tests love-bundle osx win32 win64

clean:
	rm -rf build

publish: publish-precheck publish-love publish-osx publish-win32 publish-win64 publish-status
	@echo "Done publishing build $(GAME_VERSION)"

publish-precheck: checks tests
	@ [ "$(GITSTATUS)" == "dirty" ] && echo "You have uncommitted changes" && exit 1 || exit 0

publish-status:
	butler status $(TARGET)
	@ echo "Current version: $(GAME_VERSION)"

publish-wait:
	@ while butler status $(TARGET) | grep '•' ; do sleep 5 ; done

setup: $(DEST)/.setup
$(DEST)/.setup: .gitmodules
	@which luacheck 1>/dev/null || (echo \
		"Luacheck (https://github.com/mpeterv/luacheck/) is required to run the static analysis checks" \
		&& false )
	mkdir -p $(DEST)
	git submodule update --init --recursive
	git submodule update --recursive
	touch $(@)

assets: $(DEST)/.assets
$(DEST)/.assets: $(shell find raw_assets -name '*.png')
	mkdir -p $(DEST)
	./update-art.sh
	touch $(@)

# TODO grab the binary out of the appropriate platform version
tests: setup
	love $(SRC) --cute-headless

checks: setup
	find src -name '*.lua' | grep -v thirdparty | xargs luacheck -q

run: love-bundle
	love $(DEST)/love/$(NAME).love

# .love bundle
love-bundle: setup $(DEST)/love/$(NAME).love
$(DEST)/love/$(NAME).love: $(shell find $(SRC) -type f) $(DEST)/.assets
	mkdir -p $(DEST)/love && \
	cd $(SRC) && \
	rm -f ../$(@) && \
	zip -9r ../$(@) .

publish-love: $(DEST)/.published-love
$(DEST)/.published-love: $(DEST)/love/$(NAME).love
	butler push $(DEST)/love $(TARGET):love-bundle --userversion $(GAME_VERSION) && touch $(@)

# macOS version
osx: $(DEST)/osx/$(NAME).app
$(DEST)/osx/$(NAME).app: $(DEST)/love/$(NAME).love $(wildcard osx/*) $(DEST)/deps/love.app/Contents/MacOS/love
	mkdir -p $(DEST)/osx
	rm -rf $(@)
	cp -r "$(DEST)/deps/love.app" $(@) && \
	cp osx/Info.plist $(@)/Contents && \
	cp osx/*.icns $(@)/Contents/Resources/ && \
	cp $(DEST)/love/$(NAME).love $(@)/Contents/Resources

publish-osx: $(DEST)/.published-osx
$(DEST)/.published-osx: $(DEST)/osx/$(NAME).app
	butler push $(DEST)/osx $(TARGET):osx --userversion $(GAME_VERSION) && touch $(@)

# OSX build dependencies
$(DEST)/deps/love.app/Contents/MacOS/love:
	mkdir -p $(DEST)/deps/ && \
	cd $(DEST)/deps && \
	wget https://bitbucket.org/rude/love/downloads/love-$(LOVE_VERSION)-macosx-x64.zip && \
	unzip love-$(LOVE_VERSION)-macosx-x64.zip

# Windows build dependencies
WIN32_ROOT=$(DEST)/deps/love-$(LOVE_VERSION)-win32
WIN64_ROOT=$(DEST)/deps/love-$(LOVE_VERSION)-win64

$(WIN32_ROOT)/love.exe:
	mkdir -p $(DEST)/deps/ && \
	cd $(DEST)/deps && \
	wget https://bitbucket.org/rude/love/downloads/love-$(LOVE_VERSION)-win32.zip && \
	unzip love-$(LOVE_VERSION)-win32.zip

$(WIN64_ROOT)/love.exe:
	mkdir -p $(DEST)/deps/ && \
	cd $(DEST)/deps && \
	wget https://bitbucket.org/rude/love/downloads/love-$(LOVE_VERSION)-win64.zip && \
	unzip love-$(LOVE_VERSION)-win64.zip

# Win32 version
win32: $(DEST)/win32/$(NAME).exe
$(DEST)/win32/$(NAME).exe: $(WIN32_ROOT)/love.exe $(DEST)/love/$(NAME).love
	mkdir -p $(DEST)/win32
	cp -r $(wildcard $(WIN32_ROOT)/*.dll) $(WIN32_ROOT)/license.txt $(DEST)/win32
	cat $(^) > $(@)

publish-win32: $(DEST)/.published-win32
$(DEST)/.published-win32: $(DEST)/win32/$(NAME).exe
	butler push $(DEST)/win32 $(TARGET):win32 --userversion $(GAME_VERSION) && touch $(@)

# Win64 version
win64: $(DEST)/win64/$(NAME).exe
$(DEST)/win64/$(NAME).exe: $(WIN64_ROOT)/love.exe $(DEST)/love/$(NAME).love
	mkdir -p $(DEST)/win64
	cp -r $(wildcard $(WIN64_ROOT)/*.dll) $(WIN64_ROOT)/license.txt $(DEST)/win64
	cat $(^) > $(@)

publish-win64: $(DEST)/.published-win64
$(DEST)/.published-win64: $(DEST)/win64/$(NAME).exe
	butler push $(DEST)/win64 $(TARGET):win64 --userversion $(GAME_VERSION) && touch $(@)

