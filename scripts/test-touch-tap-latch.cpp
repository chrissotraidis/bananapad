#include "../apple/app/touch_tap_latch.h"

#include <cstdint>
#include <cstdio>

namespace {

constexpr uint16_t A_BUTTON = 0x8000;
constexpr uint16_t B_BUTTON = 0x4000;
constexpr uint16_t Z_BUTTON = 0x2000;

bool expect(PaperPadTouchTapLatch& latch, uint16_t value, const char* step) {
    const uint16_t actual = latch.consume();
    if (actual == value) return true;
    std::fprintf(stderr, "%s: expected 0x%04x, got 0x%04x\n", step, value, actual);
    return false;
}

} // namespace

int main() {
    PaperPadTouchTapLatch latch;

    latch.extend(A_BUTTON, 3);
    latch.extend(B_BUTTON, 2);
    if (!expect(latch, A_BUTTON | B_BUTTON, "independent fingers poll 1")) return 1;
    if (!expect(latch, A_BUTTON | B_BUTTON, "independent fingers poll 2")) return 1;
    if (!expect(latch, A_BUTTON, "independent fingers poll 3")) return 1;
    if (!expect(latch, 0, "independent fingers exhausted")) return 1;

    latch.extend(Z_BUTTON, 4);
    latch.extend(Z_BUTTON, 2);
    for (int poll = 0; poll < 4; ++poll) {
        if (!expect(latch, Z_BUTTON, "shorter tap must not truncate a held tap")) return 1;
    }
    if (!expect(latch, 0, "extended tap exhausted")) return 1;

    latch.extend(A_BUTTON | Z_BUTTON, 2);
    latch.clear(A_BUTTON);
    if (!expect(latch, Z_BUTTON, "masked clear preserves other fingers")) return 1;
    latch.clearAll();
    if (!expect(latch, 0, "clearAll releases every input")) return 1;

    return 0;
}
