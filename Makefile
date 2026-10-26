SDK    ?= $(shell cat "$(HOME)/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")
BIN     = $(SDK)/bin
DEVICE ?= venu445mm
KEY    ?= $(HOME)/.garmin/developer_key.der

.PHONY: build test run sim icons export

build:
	mkdir -p bin
	"$(BIN)/monkeyc" -f monkey.jungle -d $(DEVICE) -o bin/GarminBus-$(DEVICE).prg -y "$(KEY)" -w

# Simulator must be running (make sim)
test:
	mkdir -p bin
	"$(BIN)/monkeyc" -f test.jungle -d $(DEVICE) -o bin/GarminBusTest.prg -y "$(KEY)" -t
	"$(BIN)/monkeydo" bin/GarminBusTest.prg $(DEVICE) -t | tee bin/test-output.txt; grep -q '^PASSED (' bin/test-output.txt

# Simulator must be running (make sim)
run: build
	"$(BIN)/monkeydo" bin/GarminBus-$(DEVICE).prg $(DEVICE)

sim:
	"$(BIN)/connectiq" &

icons:
	python3 -I tools/make_icon.py 70 resources/drawables/launcher_icon.png
	mkdir -p store
	python3 -I tools/make_icon.py 500 store/icon-500.png
	for s in 38 40 54 56 60 61 65; do \
		mkdir -p resources-icon$$s/drawables; \
		cp resources/drawables/drawables.xml resources-icon$$s/drawables/; \
		python3 -I tools/make_icon.py $$s resources-icon$$s/drawables/launcher_icon.png; \
	done

export:
	mkdir -p bin
	"$(BIN)/monkeyc" -e -r -w -f monkey.jungle -o bin/NesteAvgang.iq -y "$(KEY)"
