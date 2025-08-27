# Maintainer: Miguel Santos <miguelandrelealsantos.business@gmail.com>
pkgname=omarchy-calculator-git
pkgver=1.0.0
pkgrel=1
pkgdesc="A minimal calculator app built with the Omarchy theme for Flutter"
arch=('x86_64')
url="https://github.com/yourusername/omarchy-calculator"
license=('MIT')
depends=('gtk3' 'glibc')
makedepends=('flutter' 'git')
source=("git+https://github.com/cakephone/omarchy_calculator.git#tag=v$pkgver")
sha256sums=('SKIP')

build() {
    cd "$pkgname"
    flutter pub get
    flutter build linux --release
}

package() {
    cd "$pkgname"
    make DESTDIR="$pkgdir" PREFIX=/usr install
}

# Optional: Add a .SRCINFO generation helper
# makepkg --printsrcinfo > .SRCINFO
