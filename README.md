# MT-desk

**MT-desk** is an Android application and companion project for running a Linux desktop environment on Android devices. The project includes a standalone Android app and a separate Termux-based setup path. The Android app uses an embedded Termux:X11 server; it does not use VNC for its on-device display.

> [!IMPORTANT]
> MT-desk is an independent GPL-3.0-only project. It is not affiliated with or endorsed by Termux, Termux:X11, TUR, Canonical, Ubuntu, or the upstream DroidDesk project. Third-party components retain their own copyrights and licences.
>
> - Repository: https://github.com/TEMMC/MT-desk
> - Termux:X11 upstream: https://github.com/termux/termux-x11

## Project maintainer

**Tinotenda Enock Mapfumo**

## Project scope and operating modes

### Standalone Android application

The standalone app automates setup and startup of a Linux graphical environment.

- **Rooted Android devices:** the app can use its root/chroot runtime path with a Linux filesystem.
- **Non-rooted Android devices:** the app uses its app-private Termux userspace and package repositories; this mode does not use PRoot.
- **Display:** the app embeds a Termux:X11 server and connects the desktop to `DISPLAY=:0`.
- **Graphics:** acceleration depends on the device GPU, Android vendor driver, kernel interfaces, and userspace compatibility. Adreno devices may use Turnip/Zink where supported. Other GPUs may fall back to software rendering. Hardware acceleration is not guaranteed on every device.
- **Package identity:** Android application ID is `com.mtdesk.desktop`.

The app is not a full Android replacement and does not replace the phone's kernel or Android system.

### Termux setup path

The repository also contains a Termux-oriented setup script for users who prefer to manage the Linux desktop from Termux. This path is separate from the standalone app and has separate prerequisites.

## Current app changes documented in this source revision

The following changes are included in the current feature branch:

### Startup and desktop readiness

- Desktop readiness checks now verify the selected desktop session and its window manager, desktop process, and panel instead of accepting only a partial desktop startup.
- Supported process checks include XFCE (`xfce4-session`, `xfwm4`, `xfdesktop`, `xfce4-panel`), LXQt (`lxqt-session`, `openbox`, `lxqt-panel`), MATE (`mate-session`, `marco`, `mate-panel`), and KDE (`plasmashell`, `kwin_x11`).
- Failed desktop readiness keeps the recovery/loading screen visible and reports that startup failed rather than revealing an empty desktop surface.
- Readiness polling groups process checks into fewer root-shell round trips to reduce polling overhead.

### Performance and graphics safeguards

- Software-rendering environments cap selected rendering thread pools with `LP_NUM_THREADS=2` and `OMP_NUM_THREADS=2`; Mesa GL threading is disabled with `MESA_GLTHREAD=false`.
- XFCE compositing is disabled in the configured startup path to reduce GPU/CPU and memory pressure on constrained devices.
- These are conservative safeguards, not a promise that every GPU is hardware accelerated or that every device will run smoothly.

### App catalogue responsiveness

- Broad package and installed-app scans are deferred until the user opens the relevant Browse or Installed view.
- Empty searches do not trigger broad package searches.
- Search work is started only for a non-empty query.

### Desktop appearance

- A Display & Wallpapers settings area is included.
- Available virtual display framebuffer presets are 1280×720, 1600×900, 1920×1080, 2560×1440, and Auto, subject to the active X server and display backend.
- Wallpaper choices include the bundled MT-desk SVG designs.
- XFCE desktop icon size can be adjusted through the supported desktop configuration path.

**Important:** a virtual framebuffer size is not the same as the phone panel's physical resolution. A higher virtual resolution does not increase the physical pixel count of the phone display and may increase rendering and memory costs.

## Device requirements and compatibility

### General requirements

- Android device with ARM64 support for the current app build.
- Sufficient free internal storage for the app, Linux userspace, package downloads, and installed applications.
- For rooted mode, a working root manager and compatible chroot support.
- For non-rooted mode, Android permissions and process limits must allow the app's private userspace and X11 processes to run.
- A supported desktop environment and package repository configuration.

The actual minimum Android version and device compatibility must be taken from the app's current Gradle/Android configuration; compatibility can vary by build and device.

### Low-memory devices

A full Linux desktop runs alongside Android. Android system services, the X11 server, desktop session, graphics buffers, and Linux applications all share the device's available memory.

For devices with around 2 GB RAM, start with a lightweight desktop and conservative settings:

- Use 1280×720 virtual display size first.
- Keep XFCE compositing disabled.
- Avoid starting several browsers or large applications at once.
- Disable nonessential desktop autostart applications and services.
- Close the Linux session when it is not being used.
- Keep free internal storage available for package operations and temporary files.

Swap can reduce out-of-memory terminations in some situations, but it is much slower than RAM and is not a substitute for physical memory. Do not increase swap blindly or install RAM-cleaner applications.

### GPU and Mesa notes

Mesa is a userspace graphics stack, not a universal driver that makes every GPU accelerated. The correct driver must match the physical GPU and kernel/vendor interfaces.

- Adreno-specific Turnip support does not apply to PowerVR GPUs.
- Panfrost targets supported Mali GPUs, not PowerVR GE8320.
- LLVMpipe is CPU-based software rendering and can be slow on low-end phones.
- Zink translates OpenGL to Vulkan; it still requires a compatible Vulkan implementation underneath.
- PowerVR GE8320 devices commonly rely on vendor graphics components. Compatibility with Mesa/PVR drivers must be verified for the exact GPU variant and system; do not assume that a generic Mesa package enables acceleration.

For diagnosis, inspect the renderer from inside the Linux desktop with `glxinfo -B` when `glxinfo` is installed. The renderer string helps distinguish hardware acceleration from software rendering.

## Installation

### Standalone Android app

1. Open the [MT-desk Releases page](https://github.com/TEMMC/MT-desk/releases).
2. Download the APK asset for the release.
3. Allow installation from the source used to download the APK if Android requests it.
4. Install and open MT-desk.
5. Follow the in-app setup prompts and grant only the permissions required by the selected runtime mode.

Do not install an APK from an untrusted mirror. Check the SHA-256 checksum published with the release when available.

### Termux-based setup

This is the separate Termux workflow. Install Termux from a trusted F-Droid distribution and install the compatible Termux:X11 APK from its upstream release page. Do not mix incompatible Termux app sources/signatures.

Run the setup script from the repository:

```bash
curl -fL https://raw.githubusercontent.com/TEMMC/MT-desk/main/termux-linux-setup.sh -o setup.sh
bash setup.sh
```

The setup script's options and package availability may change. Review the script before executing it, especially when running commands with elevated privileges.

## Building the Android app

The Android app source is in `app/`. The release workflow is `.github/workflows/build-apk.yml`.

The current workflow:

1. Checks out the selected repository revision.
2. Sets up Java 17 and Flutter stable.
3. Restores the configured release keystore from GitHub Actions secrets.
4. Resolves Flutter dependencies.
5. Builds the release APK.
6. Verifies APK signature and package ID `com.mtdesk.desktop`.
7. Prints the signing certificate information and computes a SHA-256 checksum.
8. Uploads the signed APK and checksum as a workflow artifact.

The workflow requires the repository secrets configured in `.github/workflows/build-apk.yml`. Never put keystores, passwords, API tokens, or private signing material in the repository.

A successful CI build confirms that the configured build and APK verification steps passed. It does not, by itself, prove that every desktop environment or GPU works on every physical device. Test the APK on target devices before calling the release production-ready.

## Recent performance and startup fixes

The current feature branch contains these recent changes:

| Area | Change |
|---|---|
| App catalogue | Defer expensive package/installed-app scans until the relevant tab is opened |
| Search | Avoid broad searches for an empty query |
| Desktop startup | Check session, window manager, desktop and panel processes |
| Failure handling | Keep recovery UI visible when desktop readiness fails |
| Root polling | Reduce repeated root-shell calls during readiness checks |
| Software rendering | Bound selected rendering thread counts and disable Mesa GL threading |
| XFCE | Disable compositing in the configured startup path |
| Appearance | Add display-size presets, wallpaper selection and icon-size control |

## Known limitations and troubleshooting

- **Desktop did not start:** the selected session or window manager may be missing, fail to launch, or exit immediately. Check the runtime log and installed desktop packages before retrying repeatedly.
- **Blank desktop:** a running X server does not prove that a desktop session is ready. MT-desk's readiness check is intended to detect incomplete sessions and keep the recovery screen visible.
- **Heavy lag:** software rendering, high virtual resolution, multiple Linux applications, Android background apps, and low available RAM can all contribute.
- **GPU acceleration:** support is device-specific. Do not install a driver for a different GPU family.
- **Package installation failures:** verify network access, repository configuration, free storage, and package architecture.
- **Monitor output:** USB-C video output depends on the phone's hardware. Most phones do not gain wired display output merely by installing this app.

If startup fails, stop the Linux session before retrying. Repeatedly starting a failing desktop can create extra load and make diagnosis harder.

## Repository scripts and optional monitor workflow

The repository includes helper scripts for the Termux workflow, such as `start-x11.sh`, `start-vnc.sh`, `start-proot.sh`, and `proot-menu-sync.sh`, plus an optional Raspberry Pi bridge script. These scripts are not prerequisites for the standalone Android app.

VNC is an optional remote/monitor workflow; the standalone app's on-device display uses its embedded X11 server.

## Privacy and security

- Review permissions requested by the app and grant only what is necessary.
- Root mode grants the runtime powerful access to the device. Use it only if you understand the implications.
- Do not run untrusted Linux scripts as root.
- Do not publish diagnostic logs containing personal paths, tokens, account details, or other private information.

## Credits and third-party software

MT-desk is an independent project and includes or depends on third-party software. Their names and trademarks remain the property of their respective owners.

See:

- [LICENSE](LICENSE)
- [NOTICE.md](NOTICE.md)
- [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
- [COMPLIANCE.md](COMPLIANCE.md)

The compliance checklist currently contains unresolved source-provenance, reproducible-build, bootstrap, and asset-licensing work. This repository does not claim that those outstanding items have been completed. Do not describe the APK as fully licence-compliant until the checklist has been resolved and reviewed.

## Maintainer

**Tinotenda Enock Mapfumo**

MT-desk is maintained as an independent project under the TEMMC GitHub account.

