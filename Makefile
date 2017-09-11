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
.PHONY: commit-check
.PHONY: love-bundle osx win32 win64
.PHONY: assets setup tests checks

all: checks tests love-bundle osx win32 win64

clean:
	rm -rf build

publish: publish-precheck publish-love publish-osx publish-win32 publish-win64 publish-status
	@echo "Done publishing build $(GAME_VERSION)"

publish-precheck: commit-check checks test-bundle

publish-status:
	butler status $(TARGET)
	@ echo "Current version: $(GAME_VERSION)"

publish-wait:
	@ while butler status $(TARGET) | grep '•' ; do sleep 5 ; done

commit-check:
	@ [ "$(GITSTATUS)" == "dirty" ] && echo "You have uncommitted changes" && exit 1 || exit 0

setup: $(DEST)/.setup-$(GAME_VERSION)
$(DEST)/.setup-$(GAME_VERSION):
	@which luacheck 1>/dev/null || (echo \
		"Luacheck (https://github.com/mpeterv/luacheck/) is required to run the static analysis checks" \
		&& false )
	mkdir -p $(DEST)
	touch $(@)

assets:
	@ ./update-art.sh

# TODO grab the binary out of the appropriate platform version
tests: setup
	love $(SRC) --cute-headless

test-bundle: setup $(DEST)/love/$(NAME).love
	love $(DEST)/love/$(NAME).love --cute-headless

checks: setup
	find src -name '*.lua' | grep -v thirdparty | xargs luacheck -q

run: love-bundle
	love $(DEST)/love/$(NAME).love

# .love bundle
love-bundle: setup assets $(DEST)/love/$(NAME).love
$(DEST)/love/$(NAME).love: $(shell find $(SRC) -type f)
	mkdir -p $(DEST)/love && \
	cd $(SRC) && \
	rm -f ../$(@) && \
	zip -9r ../$(@) .

publish-love: $(DEST)/.published-love-$(GAME_VERSION)
$(DEST)/.published-love-$(GAME_VERSION): $(DEST)/love/$(NAME).love
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

publish-osx: $(DEST)/.published-osx-$(GAME_VERSION)
$(DEST)/.published-osx-$(GAME_VERSION): $(DEST)/osx/$(NAME).app
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

publish-win32: $(DEST)/.published-win32-$(GAME_VERSION)
$(DEST)/.published-win32-$(GAME_VERSION): $(DEST)/win32/$(NAME).exe
	butler push $(DEST)/win32 $(TARGET):win32 --userversion $(GAME_VERSION) && touch $(@)

# Win64 version
win64: $(DEST)/win64/$(NAME).exe
$(DEST)/win64/$(NAME).exe: $(WIN64_ROOT)/love.exe $(DEST)/love/$(NAME).love
	mkdir -p $(DEST)/win64
	cp -r $(wildcard $(WIN64_ROOT)/*.dll) $(WIN64_ROOT)/license.txt $(DEST)/win64
	cat $(^) > $(@)

publish-win64: $(DEST)/.published-win64-$(GAME_VERSION)
$(DEST)/.published-win64-$(GAME_VERSION): $(DEST)/win64/$(NAME).exe
	butler push $(DEST)/win64 $(TARGET):win64 --userversion $(GAME_VERSION) && touch $(@)

#### asset rules go down here (someday, maybe)
