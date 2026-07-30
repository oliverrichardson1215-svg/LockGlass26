# LockGlass26

LockGlass26 is a rootless jailbreak tweak for Dopamine on iOS 16. It injects into SpringBoard and gives the native lock screen a large translucent liquid-glass clock inspired by the provided iOS 26 reference.

## Build

Install Theos in your jailbreak build environment, then run:

```sh
make package
```

You can also use GitHub Actions. Push this project to GitHub, open the `Build deb` workflow, run it manually or push to `main`, then download the `LockGlass26-deb` artifact.

The package is configured for rootless:

```make
export THEOS_PACKAGE_SCHEME = rootless
```

## Install

Copy the generated `.deb` to the device and install it with Sileo, Zebra, or:

```sh
sudo dpkg -i com.zm.liquidlock26_0.1.0_iphoneos-arm64.deb
sbreload
```

## Settings

After installation, open the iOS Settings app and go to `LockGlass26`.

Available options:

- `Enabled`: turn the lock screen effect on or off.
- `Time Size`: adjust the large iOS 26-style clock size.
- `Vertical Position`: move the clock up or down.
- `Glass Opacity`: adjust the liquid glass transparency.
- `Respring`: restart SpringBoard if a full refresh is needed.

## Notes

This first version targets iOS 16 SpringBoard classes used by the Cover Sheet lock screen. If Apple class names differ on a specific build, the tweak falls back to runtime view-tree detection for the clock labels.
