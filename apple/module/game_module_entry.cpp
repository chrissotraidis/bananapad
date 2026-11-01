#include "game_module.h"

extern "C" void recomp_entrypoint(uint8_t*, recomp_context*);
gpr get_entrypoint_address();
extern RspUcodeFunc n_aspMain;
namespace dk64 { void register_bk_overlays(); void register_bk_patches(); }

extern "C" __attribute__((visibility("default")))
const BananaPadGameModule* bananapad_get_game_module() {
    static const BananaPadGameModule module{
        bananapad_game_module_version, sizeof(BananaPadGameModule), BANANAPAD_MODULE_ID,
        get_entrypoint_address, recomp_entrypoint, n_aspMain,
        dk64::register_bk_overlays, dk64::register_bk_patches
    };
    return &module;
}
