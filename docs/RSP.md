# RSP and audio execution path

The complete fixed microcode identity is [RSP-MANIFEST.json](RSP-MANIFEST.json).

| Field | Value |
|---|---:|
| Decompressed ROM text offset | `0x02146010` |
| Text size | `0x00000C30` |
| RSP address | `0x04001080` |
| Output function | `n_aspMain` |
| Accepted task | `M_AUDTASK` |
| HLE fallback | none |

The 16 configured indirect targets are retained exactly, including repeated `0x00001C58` entries. `RSPRecomp` generates `rsp/n_aspMain.cpp`; its SHA-256 is `da1aed4b6ea7306d8fef72475b9c8a12fa1f1e23bd8801e7e5b90f72fc3a819d`.

`src/main/main.cpp` registers `get_rsp_microcode` with librecomp. `M_AUDTASK` returns the statically linked `n_aspMain`; any other task is logged and returns null. The runtime treats an unmatched microcode task as fatal. There is no silent audio disable or hidden HLE route.

The macOS and iPad Simulator artifacts compile and launch through this same registration. Full auditory correctness is intentionally not inferred from reaching the title. Music, ambience, voices, UI sounds, weapons, instruments, animal/vehicle sounds, bosses, arcade, Jetpac, transitions, credits, queue depth, underruns, pitch, drift, lifecycle, and route changes remain later audio evidence.
