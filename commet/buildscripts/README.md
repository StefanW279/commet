> [!NOTE]
> These Scripts are made for and tested on Arch Linux
> When using Arch Linux all required packages can be installed using:
> ```bash
> sudo pacman -Syu cmake clang ninja rustup gtk3 mpv ffmpeg mimalloc webkit2gtk-4.1 libkeybinder3 flatpak flatpak-builder git git-lfs fvm jdk17-openjdk
> ```
> for building android apps, we also need some packages from the [AUR](https://aur.archlinux.org), if you're using [yay](https://github.com/jguer/yay) then you can use the following command:
> ```bash
> yay -S android-sdk-cmdline-tools-latest
> ```
> ```bash
> android --sdk=$HOME/Android/Sdk sdk install ndk/28.2.13676358 extras/google/market_licensing cmake/3.22.1 build-tools/35.0.0 platforms/android-36 sources/android-36 cmdline-tools/latest
> ```
> after installing the packages run the following command in the root of the repository
> ```bash
> fvm install
> ```
> after this use the following command to select the correct Java version and Android SDK
> ```bash
> fvm flutter config --jdk-dir /usr/lib/jvm/java-17-openjdk/
> fvm flutter config --android-sdk ~/Android/Sdk/
> ```
> And now just reboot once, and you're ready to build

> [!IMPORTANT]
> if you get an error like this: 
>```
> error: the 'cargo' binary, normally provided by the 'cargo' component, is not applicable to the 'stable-x86_64-unknown-linux-gnu' toolchain 
> ```
> you need to reinstall the cargo component, done using the following commands
> ```bash
> rustup component remove cargo
> rustup component add cargo
> ```

> [!NOTE]
> To use the Android buildscripts, you need to generate a Signing Key, which needs to be put in commet/android/key.jks and a key.properties, which you can make using the given key.properties.example.
> ```bash
> keytool -genkey -v -keystore key.jks -keyalg RSA -storetype JKS -keysize 4096 -validity 10000 -alias key
>```
> 