SDK    ?= $(shell cat "$(HOME)/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")
BIN     = $(SDK)/bin
DEVICE ?= venu445mm
KEY    ?= $(HOME)/.garmin/developer_key.der

.PHONY: build test run sim

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
