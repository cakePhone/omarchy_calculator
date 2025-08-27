#!/bin/bash

set -e

echo "Building Omarchy Calculator..."
flutter build linux --release

echo "Installing to ~/.local/..."

# Create directories
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/applications
mkdir -p ~/.local/share/icons/hicolor/scalable/apps
mkdir -p ~/.local/share/omarchy-calculator

# Copy files
cp build/linux/x64/release/bundle/example ~/.local/share/omarchy-calculator/omarchy_calculator
cp -r build/linux/x64/release/bundle/lib ~/.local/share/omarchy-calculator/
cp -r build/linux/x64/release/bundle/data ~/.local/share/omarchy-calculator/

# Create wrapper script
cat > ~/.local/bin/omarchy-calculator << 'EOF'
#!/bin/bash
cd ~/.local/share/omarchy-calculator
exec ./omarchy_calculator "$@"
EOF

chmod +x ~/.local/bin/omarchy-calculator

# Install desktop entry
cp omarchy-calculator.desktop ~/.local/share/applications/
cp omarchy-calculator.svg ~/.local/share/icons/hicolor/scalable/apps/

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database ~/.local/share/applications
fi

# Update icon cache
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache ~/.local/share/icons/hicolor
fi

echo "Installation complete!"
echo "You can now run 'omarchy-calculator' from the command line"
echo "or find it in your application menu."
