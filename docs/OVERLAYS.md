# Compressed code and overlay inventory

The machine-readable source of this table is [OVERLAYS.json](OVERLAYS.json). It is derived from the G1 generated `recomp_overlays.inl`, pinned `us.toml`, and the promoted `load_dk64_overlay` implementation. The generator fails unless all ten compressed classes are present.

| Class | Section | Compressed trigger | Decompressed start | Runtime RAM | Size | AOT functions |
|---|---:|---:|---:|---:|---:|---:|
| `global_asm` | 2 | `0x000113F0` | `0x02000000` | `0x805FB300` | `0x00165D50` | 3,600 |
| `menu` | 3 | `0x000CBE70` | `0x02165D50` | `0x80024000` | `0x0000FF10` | 114 |
| `multiplayer` | 4 | `0x000D4B00` | `0x02175C60` | `0x80024000` | `0x00003100` | 31 |
| `minecart` | 5 | `0x000D6B00` | `0x02178D60` | `0x80024000` | `0x00004E10` | 25 |
| `bonus` | 6 | `0x000D9A40` | `0x0217DB70` | `0x80024000` | `0x00009EF0` | 47 |
| `race` | 7 | `0x000DF600` | `0x02187A60` | `0x80024000` | `0x0000C160` | 113 |
| `critter` | 8 | `0x000E6780` | `0x02193BC0` | `0x80024000` | `0x000061B0` | 55 |
| `boss` | 9 | `0x000EA0B0` | `0x02199D70` | `0x80024000` | `0x00012DC0` | 80 |
| `arcade` | 10 | `0x000F41A0` | `0x021ACB30` | `0x80024000` | `0x00026C00` | 98 |
| `jetpac` | 11 | `0x000FD2F0` | `0x021D3730` | `0x80024000` | `0x0000AC30` | 108 |

The non-compressed entry and boot sections are also in the JSON manifest: section 0 at `0x80000400` and section 1 at `0x80000450`.

## Load model

The boot hook converts compressed ROM trigger `0x113F0` to the decompressed global section and fixed destination. Later DMA interception calls `load_dk64_overlay`, which maps a known compressed trigger to its decompressed section, destination, and exact size, then calls `load_overlays`. Generated sections are registered before game execution.

The nine non-global classes deliberately share `0x80024000`. Loading a new class replaces the function-map identity at that destination; it is not additive. Unknown compressed triggers register no overlay. The static patch profile remains present as a separate AOT patch table while game overlays change.

## Transition and test ownership

`menu` is the hub class. Minecart, bonus barrels, races, critter encounters, bosses, arcade, and Jetpac enter their named class and must return through menu/global code. Multiplayer remains disabled and is tested only for safe absence unless separately authorized.

Architecture evidence proves every class has an AOT table and exact loader mapping. It does not substitute for route evidence. The required gameplay checks are:

- menu → gameplay and gameplay → menu;
- enter/exit minecart, bonus, race, critter, and boss routes;
- earn the arcade coin and return;
- earn the Jetpac coin and return;
- verify the disabled multiplayer path cannot load stale code;
- test consecutive different classes to exercise the shared replacement boundary.

## Known generator warnings

N64Recomp reports an ambiguous `jal` destination at shared address `0x80024000` in `func_global_asm_805FBFF4` and an indirect tail call in `recomp_entrypoint`. The generated tables are deterministic, but these warnings remain explicit transition-test inputs. They are not suppressed.

Generated table SHA-256: `4e5c427c85d444076d1d924f09e6c87a8ab6b1087b8c6b14247bcefcfc0dbf3f`.
