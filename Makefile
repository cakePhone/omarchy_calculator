PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
DATADIR = $(PREFIX)/share
ICONDIR = $(DATADIR)/icons/hicolor/scalable/apps
DESKTOPDIR = $(DATADIR)/applications

.PHONY: all build install uninstall clean

all: build

build:
	flutter build linux --release

install: build
	install -Dm755 build/linux/x64/release/bundle/example $(DESTDIR)$(BINDIR)/omarchy-calculator
	install -Dm644 omarchy-calculator.desktop $(DESTDIR)$(DESKTOPDIR)/omarchy-calculator.desktop
	install -Dm644 omarchy-calculator.svg $(DESTDIR)$(ICONDIR)/omarchy-calculator.svg
	
	# Install Flutter libraries and data
	mkdir -p $(DESTDIR)$(DATADIR)/omarchy-calculator
	cp -r build/linux/x64/release/bundle/lib $(DESTDIR)$(DATADIR)/omarchy-calculator/
	cp -r build/linux/x64/release/bundle/data $(DESTDIR)$(DATADIR)/omarchy-calculator/
	
	# Create wrapper script
	mkdir -p $(DESTDIR)$(BINDIR)
	echo '#!/bin/bash' > $(DESTDIR)$(BINDIR)/omarchy-calculator
	echo 'cd $(DATADIR)/omarchy-calculator' >> $(DESTDIR)$(BINDIR)/omarchy-calculator
	echo 'exec ./omarchy_calculator "$$@"' >> $(DESTDIR)$(BINDIR)/omarchy-calculator
	chmod +x $(DESTDIR)$(BINDIR)/omarchy-calculator
	
	# Copy the main executable to the data directory
	cp build/linux/x64/release/bundle/example $(DESTDIR)$(DATADIR)/omarchy-calculator/omarchy_calculator

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/omarchy-calculator
	rm -f $(DESTDIR)$(DESKTOPDIR)/omarchy-calculator.desktop
	rm -f $(DESTDIR)$(ICONDIR)/omarchy-calculator.svg
	rm -rf $(DESTDIR)$(DATADIR)/omarchy-calculator

clean:
	flutter clean
	rm -rf build
