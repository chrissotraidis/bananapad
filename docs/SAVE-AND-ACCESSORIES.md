# Save and accessory contract

The machine-readable contract is [SAVE-MANIFEST.json](SAVE-MANIFEST.json).

## EEPROM

DK64 registers `SaveType::Eep16k`. In this runtime that name means the N64 16-kilobit EEPROM profile:

- guest probe value: `EEPROM_TYPE_16K` / `0x02`;
- logical block size: 8 bytes;
- host allocation and file length: `0x800` bytes (2,048 bytes);
- file: `saves/DK64.bin` beneath the app configuration directory.

It must not be described as a 16-KiB file. Upstream selected it instead of `Eep4k` (`0x200` bytes) to retain room for the released extra save data.

EEPROM read/write offsets are the guest block address multiplied by eight. Long operations require a multiple of eight. Runtime assertions guard every read and write against the allocated buffer.

## Persistence and recovery

Writes update an in-memory buffer under a mutex and signal the saving thread. Coalesced writes are written to `DK64.bin.temp`. Finalization copies the previous primary file to `DK64.bin.bak`, copies the completed temporary file to the primary, and removes the temporary file. Reads try the primary first and the backup only when the primary cannot be opened.

The archived macOS baseline and BananaPad use the same runtime representation and filename contract. Existing save/reload evidence proves a normal write and relaunch at the pinned source; destructive/interrupted-write, explicit import, erase, and cross-version round trips remain dedicated save-gate tests.

## Slot-preserving capture imports

BananaPad's 2,048-byte EEPROM image contains four CRC-protected `0x1AC`-byte physical blocks: three visible game files and one rotating temporary file. Each block stores its logical file number in byte `0x1A0` (mask `0x0C`) and ends with a big-endian CRC32 over the preceding `0x1A8` bytes. Physical block order must not be assumed.

Use the checked importer when a privately obtained compatible save is needed for capture or testing:

```sh
scripts/inject-dk64-save-slot.py \
  --target generated/private/current-DK64.bin \
  --donor generated/private/capture-donor.eep \
  --source-slot 1 \
  --target-slot 2 \
  --output generated/private/DK64-slot2.bin
```

Stop BananaPad and back up both `DK64.bin` and `DK64.bin.bak` before replacing the primary file. The importer validates every source and target block, follows the embedded logical-file mapping, rewrites only the selected destination block, recalculates its CRC, and proves all bytes outside that block are unchanged. Keep every input and output under an ignored private path. ROMs and save files must never be committed, released, or redistributed.

A private 101% Game 1 donor was remapped into Game 2 without changing the device's Game 1, Game 3, temporary block, or global bytes. The resulting Game 2 was visually opened and loaded in a disposable iPad Simulator, then copied to the stopped hardware app. Hardware readback matched the validated image exactly after launch while the original on-device backup remained byte-identical. This is local capture evidence, not a distributable project asset.

## Accessories

Player-one controller input is required. Controller Pak operations return integer `1`, named `PFS_ERR_NOPACK` by the pinned source, and file-count queries return zero files. This is the safe no-Pak default. The earlier PRD wording `PFS_ERR_DEVICE` was inaccurate and has been corrected to match the implementation.

Rumble is capability-dependent and must fail cleanly when absent. Controller gyro may remain experimental. Mobile device motion, Controller Pak support, and multiplayer accessory claims are not baseline requirements.
