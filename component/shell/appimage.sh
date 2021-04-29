sudo pacman -Sy python-pip python-setuptools binutils patchelf desktop-file-utils gdk-pixbuf2 wget fakeroot strace

# Install appimagetool AppImage
sudo wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O /usr/local/bin/appimagetool
sudo chmod +x /usr/local/bin/appimagetool
