build:
	swift build -c release

run:
	swift run

clean:
	swift package clean

.PHONY: build run clean