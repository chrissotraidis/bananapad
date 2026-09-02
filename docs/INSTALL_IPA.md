# Install the BananaPad IPA

BananaPad's preview IPA is an unsigned, ROM-free iPhoneOS app for arm64 iPhone
and iPad devices running iOS or iPadOS 15 or newer. It does not include Donkey
Kong 64 and does not require JIT.

1. Download the IPA and matching `.sha256` file from BananaPad's official
   GitHub release.
2. Verify the download on macOS from the directory containing both files:

   ```sh
   shasum -a 256 -c BananaPad-v0.1.0-preview.1-unsigned.ipa.sha256
   ```

3. Re-sign and install the IPA with your own Apple Account using a compatible
   sideloading tool such as AltStore Classic or SideStore.
4. Launch BananaPad, choose your own legally obtained unmodified Donkey Kong 64
   US/NTSC-U 1.0 ROM from Files, and wait for validation.

Keep the same BananaPad bundle identifier and signing path for updates if you
want iOS to retain the app's private ROM, saves, and settings. Back up important
saves before changing signing tools, Apple Accounts, or bundle identifiers.

BananaPad is unofficial and is not affiliated with or endorsed by Nintendo,
Rare, Microsoft, or any upstream project. Do not redistribute ROMs, saves,
generated game code, signed copies, or packages containing user data.
