#!/bin/bash

# AUR Publishing Helper Script for Omarchy Calculator

set -e

PKGNAME="omarchy-calculator"
VERSION="1.0.0"

echo "=== AUR Publishing Helper for $PKGNAME ==="

# Check if we're in the right directory
if [[ ! -f "PKGBUILD" ]]; then
    echo "Error: PKGBUILD not found. Run this script from the project root."
    exit 1
fi

# Function to check required tools
check_tools() {
    echo "Checking required tools..."
    local missing_tools=()
    
    for tool in git makepkg flutter; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "Error: Missing required tools: ${missing_tools[*]}"
        echo "Please install them and try again."
        exit 1
    fi
    
    echo "✓ All required tools found"
}

# Function to build package locally
build_package() {
    echo "Building package locally..."
    makepkg -f
    echo "✓ Package built successfully"
}

# Function to test installation
test_install() {
    echo "Testing package installation..."
    sudo pacman -U ${PKGNAME}-${VERSION}-*.pkg.tar.zst --noconfirm
    echo "✓ Package installed successfully"
    
    echo "Testing application launch..."
    if command -v omarchy-calculator >/dev/null 2>&1; then
        echo "✓ Application is available in PATH"
    else
        echo "⚠ Warning: Application not found in PATH"
    fi
}

# Function to generate .SRCINFO
generate_srcinfo() {
    echo "Generating .SRCINFO..."
    makepkg --printsrcinfo > .SRCINFO
    echo "✓ .SRCINFO generated"
}

# Function to prepare AUR repository
prepare_aur_repo() {
    local aur_dir="../${PKGNAME}-aur"
    
    echo "Preparing AUR repository in $aur_dir..."
    
    if [[ -d "$aur_dir" ]]; then
        echo "AUR directory already exists. Updating..."
        cd "$aur_dir"
        git pull
        cd ..
    else
        echo "Cloning AUR repository..."
        git clone ssh://aur@aur.archlinux.org/${PKGNAME}.git "$aur_dir"
    fi
    
    # Copy files to AUR directory
    cp PKGBUILD "$aur_dir/"
    cp .SRCINFO "$aur_dir/"
    
    echo "✓ AUR repository prepared"
    echo "Next steps:"
    echo "1. cd $aur_dir"
    echo "2. git add PKGBUILD .SRCINFO"
    echo "3. git commit -m 'Update to version $VERSION'"
    echo "4. git push"
}

# Main menu
show_menu() {
    echo ""
    echo "Choose an action:"
    echo "1) Check tools"
    echo "2) Build package locally"
    echo "3) Test installation (requires sudo)"
    echo "4) Generate .SRCINFO"
    echo "5) Prepare AUR repository"
    echo "6) All of the above"
    echo "q) Quit"
    echo ""
    read -p "Enter your choice: " choice
    
    case $choice in
        1) check_tools ;;
        2) build_package ;;
        3) test_install ;;
        4) generate_srcinfo ;;
        5) prepare_aur_repo ;;
        6) 
            check_tools
            build_package
            generate_srcinfo
            prepare_aur_repo
            ;;
        q|Q) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid choice. Please try again." ;;
    esac
}

# Main execution
if [[ $# -eq 0 ]]; then
    # Interactive mode
    while true; do
        show_menu
        echo ""
        read -p "Press Enter to continue or Ctrl+C to exit..."
    done
else
    # Command line mode
    case $1 in
        check) check_tools ;;
        build) build_package ;;
        test) test_install ;;
        srcinfo) generate_srcinfo ;;
        aur) prepare_aur_repo ;;
        all) 
            check_tools
            build_package
            generate_srcinfo
            prepare_aur_repo
            ;;
        *) 
            echo "Usage: $0 [check|build|test|srcinfo|aur|all]"
            exit 1
            ;;
    esac
fi
