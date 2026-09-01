#include "bananapad_native.h"

#include <algorithm>
#include <array>
#include <atomic>
#include <cmath>
#include <cstdlib>
#include <cstdio>
#include <mutex>

#define SDL_MAIN_HANDLED
#include "SDL.h"

#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

#if defined(__APPLE__) && TARGET_OS_IPHONE
extern "C" void paperpad_touch_snapshot(uint16_t* buttons, float* x, float* y);
extern "C" void PaperPad_SetPhysicalControllerConnected(int connected);
#include "../app/native_ui_state.h"
#endif

namespace {

constexpr uint16_t A_BUTTON = 0x8000;
constexpr uint16_t B_BUTTON = 0x4000;
constexpr uint16_t Z_BUTTON = 0x2000;
constexpr uint16_t START_BUTTON = 0x1000;
constexpr uint16_t U_JPAD = 0x0800;
constexpr uint16_t D_JPAD = 0x0400;
constexpr uint16_t L_JPAD = 0x0200;
constexpr uint16_t R_JPAD = 0x0100;
constexpr uint16_t L_TRIG = 0x0020;
constexpr uint16_t R_TRIG = 0x0010;
constexpr uint16_t U_CBUTTONS = 0x0008;
constexpr uint16_t D_CBUTTONS = 0x0004;
constexpr uint16_t L_CBUTTONS = 0x0002;
constexpr uint16_t R_CBUTTONS = 0x0001;

enum class Action : size_t {
    A, B, Start, Z, L, R, CUp, CDown, CLeft, CRight,
    DUp, DDown, DLeft, DRight, StickUp, StickDown, StickLeft, StickRight,
    Count
};

constexpr size_t action_count = static_cast<size_t>(Action::Count);

struct ActionDescriptor {
    uint16_t button;
    float x;
    float y;
};

constexpr std::array<ActionDescriptor, action_count> actions{{
    {A_BUTTON, 0, 0}, {B_BUTTON, 0, 0}, {START_BUTTON, 0, 0}, {Z_BUTTON, 0, 0},
    {L_TRIG, 0, 0}, {R_TRIG, 0, 0}, {U_CBUTTONS, 0, 0}, {D_CBUTTONS, 0, 0},
    {L_CBUTTONS, 0, 0}, {R_CBUTTONS, 0, 0}, {U_JPAD, 0, 0}, {D_JPAD, 0, 0},
    {L_JPAD, 0, 0}, {R_JPAD, 0, 0}, {0, 0, 1}, {0, 0, -1}, {0, -1, 0}, {0, 1, 0}
}};

// These bindings intentionally match PaperPad's native runner.
constexpr std::array<SDL_Scancode, action_count> keyboard_bindings{{
    SDL_SCANCODE_Z, SDL_SCANCODE_X, SDL_SCANCODE_RETURN, SDL_SCANCODE_LSHIFT,
    SDL_SCANCODE_Q, SDL_SCANCODE_E, SDL_SCANCODE_I, SDL_SCANCODE_K,
    SDL_SCANCODE_J, SDL_SCANCODE_L, SDL_SCANCODE_W, SDL_SCANCODE_S,
    SDL_SCANCODE_A, SDL_SCANCODE_D, SDL_SCANCODE_UP, SDL_SCANCODE_DOWN,
    SDL_SCANCODE_LEFT, SDL_SCANCODE_RIGHT
}};

// Default-off fine controls for deterministic desktop acceptance runs. When the
// long-tap environment override is active, T/G/F/H provide four-frame analog
// taps while the arrow keys retain the requested sustained duration.
constexpr std::array<SDL_Scancode, 4> fine_stick_keyboard_bindings{{
    SDL_SCANCODE_T, SDL_SCANCODE_G, SDL_SCANCODE_F, SDL_SCANCODE_H
}};

// The accessibility bridge also rejects its documented arrow-key names. Keep a
// second, default-off set of nonmodifier aliases for sustained traversal and
// swimming while retaining T/G/F/H for fine alignment.
constexpr std::array<SDL_Scancode, 4> test_stick_keyboard_bindings{{
    SDL_SCANCODE_1, SDL_SCANCODE_2, SDL_SCANCODE_3, SDL_SCANCODE_4
}};

// The accessibility bridge cannot press two nonmodifier keys as one chord.
// Keep default-off aliases for the run+jump chord needed to enter DK64 barrels.
constexpr std::array<SDL_Scancode, 4> test_jump_stick_keyboard_bindings{{
    SDL_SCANCODE_5, SDL_SCANCODE_6, SDL_SCANCODE_7, SDL_SCANCODE_8
}};

// Floating barrel entry needs a held jump with only a small positional
// correction. Keep a separate precision chord: A uses the requested test
// duration while the stick is released after the normal four-frame tap.
constexpr std::array<SDL_Scancode, 4> test_precision_jump_stick_keyboard_bindings{{
    SDL_SCANCODE_9, SDL_SCANCODE_0, SDL_SCANCODE_MINUS, SDL_SCANCODE_EQUALS
}};

// Computer Use cannot emit a modifier-only key or hold a key across tool calls,
// so acceptance runs also get sustained nonmodifier aliases for N64 A and Z.
// These are active only with the same default-off test environment override as
// the fine stick controls and use its requested duration.
constexpr SDL_Scancode test_a_keyboard_binding = SDL_SCANCODE_U;
constexpr SDL_Scancode test_z_keyboard_binding = SDL_SCANCODE_V;

SDL_Window* app_window = nullptr;
SDL_GameController* controller = nullptr;
std::mutex controller_mutex;
std::array<std::atomic<uint8_t>, action_count> tap_latches{};
std::atomic<bool> right_analog_suppressed{false};
std::atomic<bool> controller_requires_neutral{true};
std::atomic<float> output_volume{1.0f};

uint8_t keyboard_tap_frames() {
    static const uint8_t frames = [] {
#if defined(__APPLE__) && !TARGET_OS_IPHONE
        const char* raw = std::getenv("BANANAPAD_TEST_KEY_TAP_FRAMES");
        if (raw != nullptr && raw[0] != '\0') {
            char* end = nullptr;
            const unsigned long parsed = std::strtoul(raw, &end, 10);
            if (end != raw && *end == '\0' && parsed >= 1 && parsed <= 240) {
                std::fprintf(stderr,
                    "[bananapad] test keyboard tap duration: %lu frames\n", parsed);
                return static_cast<uint8_t>(parsed);
            }
            std::fprintf(stderr,
                "[bananapad] ignoring invalid BANANAPAD_TEST_KEY_TAP_FRAMES=%s\n", raw);
        }
#endif
        return static_cast<uint8_t>(4);
    }();
    return frames;
}

float normalize_axis(Sint16 value) {
    if (std::abs(value) < 8000) return 0.0f;
    return std::clamp(static_cast<float>(value) / 32767.0f, -1.0f, 1.0f);
}

void apply(size_t index, float strength, uint16_t& buttons, float& x, float& y) {
    if (strength <= 0.0f) return;
    const auto& action = actions[index];
    if (action.button != 0 && strength >= 0.5f) buttons |= action.button;
    x += action.x * strength;
    y += action.y * strength;
}

void open_first_controller() {
    std::lock_guard lock(controller_mutex);
    if (controller != nullptr && SDL_GameControllerGetAttached(controller)) {
#if defined(__APPLE__) && TARGET_OS_IPHONE
        PaperPad_SetPhysicalControllerConnected(1);
#endif
        return;
    }
    if (controller != nullptr) {
        SDL_GameControllerClose(controller);
        controller = nullptr;
    }
    for (int i = 0; i < SDL_NumJoysticks(); ++i) {
        if (SDL_IsGameController(i)) {
            controller = SDL_GameControllerOpen(i);
            if (controller != nullptr) break;
        }
    }
#if defined(__APPLE__) && TARGET_OS_IPHONE
    PaperPad_SetPhysicalControllerConnected(controller != nullptr ? 1 : 0);
#endif
}

float controller_button(SDL_GameControllerButton button) {
    return SDL_GameControllerGetButton(controller, button) ? 1.0f : 0.0f;
}

float positive_axis(SDL_GameControllerAxis axis) {
    return std::max(normalize_axis(SDL_GameControllerGetAxis(controller, axis)), 0.0f);
}

float negative_axis(SDL_GameControllerAxis axis) {
    return std::max(-normalize_axis(SDL_GameControllerGetAxis(controller, axis)), 0.0f);
}

bool controller_is_neutral() {
    if (controller == nullptr || !SDL_GameControllerGetAttached(controller)) return true;
    for (int button = 0; button < SDL_CONTROLLER_BUTTON_MAX; ++button) {
        if (SDL_GameControllerGetButton(
                controller, static_cast<SDL_GameControllerButton>(button))) return false;
    }
    for (int axis = 0; axis < SDL_CONTROLLER_AXIS_MAX; ++axis) {
        if (std::abs(SDL_GameControllerGetAxis(
                controller, static_cast<SDL_GameControllerAxis>(axis))) >= 8000) return false;
    }
    return true;
}

} // namespace

void bananapad::native::attach_window(SDL_Window* window) {
    app_window = window;
    open_first_controller();
}

void bananapad::native::handle_events() {
    SDL_Event event{};
    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_QUIT) {
            ultramodern::quit();
        } else if (event.type == SDL_CONTROLLERDEVICEADDED
                || event.type == SDL_CONTROLLERDEVICEREMOVED
                || event.type == SDL_CONTROLLERDEVICEREMAPPED
                || event.type == SDL_APP_DIDENTERFOREGROUND) {
            open_first_controller();
        } else if (event.type == SDL_KEYDOWN && event.key.repeat == 0) {
            for (size_t i = 0; i < action_count; ++i) {
                if (keyboard_bindings[i] == event.key.keysym.scancode) {
                    const auto frames = i >= static_cast<size_t>(Action::StickUp)
                        ? keyboard_tap_frames()
                        : static_cast<uint8_t>(4);
                    tap_latches[i].store(frames, std::memory_order_release);
                }
            }
            if (keyboard_tap_frames() != 4) {
                for (size_t i = 0; i < fine_stick_keyboard_bindings.size(); ++i) {
                    if (fine_stick_keyboard_bindings[i] == event.key.keysym.scancode) {
                        const auto action = static_cast<size_t>(Action::StickUp) + i;
                        tap_latches[action].store(4, std::memory_order_release);
                    }
                }
                const auto test_frames = keyboard_tap_frames();
                for (size_t i = 0; i < test_stick_keyboard_bindings.size(); ++i) {
                    if (test_stick_keyboard_bindings[i] == event.key.keysym.scancode) {
                        const auto action = static_cast<size_t>(Action::StickUp) + i;
                        tap_latches[action].store(test_frames, std::memory_order_release);
                    }
                }
                for (size_t i = 0; i < test_jump_stick_keyboard_bindings.size(); ++i) {
                    if (test_jump_stick_keyboard_bindings[i] == event.key.keysym.scancode) {
                        const auto action = static_cast<size_t>(Action::StickUp) + i;
                        tap_latches[static_cast<size_t>(Action::A)].store(
                            test_frames, std::memory_order_release);
                        tap_latches[action].store(test_frames, std::memory_order_release);
                    }
                }
                for (size_t i = 0;
                        i < test_precision_jump_stick_keyboard_bindings.size(); ++i) {
                    if (test_precision_jump_stick_keyboard_bindings[i]
                            == event.key.keysym.scancode) {
                        const auto action = static_cast<size_t>(Action::StickUp) + i;
                        tap_latches[static_cast<size_t>(Action::A)].store(
                            test_frames, std::memory_order_release);
                        tap_latches[action].store(4, std::memory_order_release);
                    }
                }
                if (test_a_keyboard_binding == event.key.keysym.scancode) {
                    tap_latches[static_cast<size_t>(Action::A)].store(
                        test_frames, std::memory_order_release);
                } else if (test_z_keyboard_binding == event.key.keysym.scancode) {
                    tap_latches[static_cast<size_t>(Action::Z)].store(
                        test_frames, std::memory_order_release);
                }
            }
        }
    }
}

void bananapad::native::poll_input() {
    // SDL events are pumped by update_gfx on the window thread.
}

bool bananapad::native::get_input(int controller_num, uint16_t* buttons, float* x, float* y) {
    if (controller_num != 0) return false;
#if defined(__APPLE__) && TARGET_OS_IPHONE
    if (BananaPad_IsNativeUIInputSuppressed()) {
        controller_requires_neutral.store(true, std::memory_order_release);
        *buttons = 0;
        *x = 0.0f;
        *y = 0.0f;
        return true;
    }
#endif

    uint16_t out_buttons = 0;
    float out_x = 0.0f;
    float out_y = 0.0f;
    const Uint8* keys = SDL_GetKeyboardState(nullptr);
    for (size_t i = 0; i < action_count; ++i) {
        uint8_t remaining = tap_latches[i].load(std::memory_order_acquire);
        bool tapped = false;
        while (remaining != 0) {
            if (tap_latches[i].compare_exchange_weak(
                    remaining, static_cast<uint8_t>(remaining - 1),
                    std::memory_order_acq_rel, std::memory_order_acquire)) {
                tapped = true;
                break;
            }
        }
        if (tapped || keys[keyboard_bindings[i]]) apply(i, 1.0f, out_buttons, out_x, out_y);
    }

    {
        std::lock_guard lock(controller_mutex);
        if (controller != nullptr && SDL_GameControllerGetAttached(controller)) {
            if (controller_requires_neutral.load(std::memory_order_acquire)) {
                if (controller_is_neutral()) {
                    controller_requires_neutral.store(false, std::memory_order_release);
                }
            }
            if (!controller_requires_neutral.load(std::memory_order_acquire)) {
                apply(static_cast<size_t>(Action::A), controller_button(SDL_CONTROLLER_BUTTON_A), out_buttons, out_x, out_y);
            apply(static_cast<size_t>(Action::B), controller_button(SDL_CONTROLLER_BUTTON_X), out_buttons, out_x, out_y);
            apply(static_cast<size_t>(Action::Start), controller_button(SDL_CONTROLLER_BUTTON_START), out_buttons, out_x, out_y);
            apply(static_cast<size_t>(Action::Z), positive_axis(SDL_CONTROLLER_AXIS_TRIGGERLEFT), out_buttons, out_x, out_y);
            apply(static_cast<size_t>(Action::L), controller_button(SDL_CONTROLLER_BUTTON_LEFTSHOULDER), out_buttons, out_x, out_y);
            apply(static_cast<size_t>(Action::R), controller_button(SDL_CONTROLLER_BUTTON_RIGHTSHOULDER), out_buttons, out_x, out_y);
            apply(static_cast<size_t>(Action::CUp), negative_axis(SDL_CONTROLLER_AXIS_RIGHTY), out_buttons, out_x, out_y);
            apply(static_cast<size_t>(Action::CDown), positive_axis(SDL_CONTROLLER_AXIS_RIGHTY), out_buttons, out_x, out_y);
            apply(static_cast<size_t>(Action::CLeft), negative_axis(SDL_CONTROLLER_AXIS_RIGHTX), out_buttons, out_x, out_y);
            apply(static_cast<size_t>(Action::CRight), positive_axis(SDL_CONTROLLER_AXIS_RIGHTX), out_buttons, out_x, out_y);
            apply(static_cast<size_t>(Action::DUp), controller_button(SDL_CONTROLLER_BUTTON_DPAD_UP), out_buttons, out_x, out_y);
            apply(static_cast<size_t>(Action::DDown), controller_button(SDL_CONTROLLER_BUTTON_DPAD_DOWN), out_buttons, out_x, out_y);
            apply(static_cast<size_t>(Action::DLeft), controller_button(SDL_CONTROLLER_BUTTON_DPAD_LEFT), out_buttons, out_x, out_y);
            apply(static_cast<size_t>(Action::DRight), controller_button(SDL_CONTROLLER_BUTTON_DPAD_RIGHT), out_buttons, out_x, out_y);
            apply(static_cast<size_t>(Action::StickUp), negative_axis(SDL_CONTROLLER_AXIS_LEFTY), out_buttons, out_x, out_y);
            apply(static_cast<size_t>(Action::StickDown), positive_axis(SDL_CONTROLLER_AXIS_LEFTY), out_buttons, out_x, out_y);
            apply(static_cast<size_t>(Action::StickLeft), negative_axis(SDL_CONTROLLER_AXIS_LEFTX), out_buttons, out_x, out_y);
                apply(static_cast<size_t>(Action::StickRight), positive_axis(SDL_CONTROLLER_AXIS_LEFTX), out_buttons, out_x, out_y);
            }
        }
    }

#if defined(__APPLE__) && TARGET_OS_IPHONE
    uint16_t touch_buttons = 0;
    float touch_x = 0.0f;
    float touch_y = 0.0f;
    paperpad_touch_snapshot(&touch_buttons, &touch_x, &touch_y);
    out_buttons |= touch_buttons;
    out_x += touch_x;
    out_y += touch_y;
#endif

    *buttons = out_buttons;
    *x = std::clamp(out_x, -1.0f, 1.0f);
    *y = std::clamp(out_y, -1.0f, 1.0f);
    return true;
}

void bananapad::native::get_right_analog(int controller_num, float* x, float* y) {
    *x = 0.0f;
    *y = 0.0f;
#if defined(__APPLE__) && TARGET_OS_IPHONE
    if (BananaPad_IsNativeUIInputSuppressed()) {
        controller_requires_neutral.store(true, std::memory_order_release);
        return;
    }
#endif
    if (controller_num != 0 || right_analog_suppressed.load(std::memory_order_relaxed)) return;
    std::lock_guard lock(controller_mutex);
    if (controller != nullptr && SDL_GameControllerGetAttached(controller)) {
        if (controller_requires_neutral.load(std::memory_order_acquire)) {
            if (controller_is_neutral()) {
                controller_requires_neutral.store(false, std::memory_order_release);
            } else {
                return;
            }
        }
        *x = normalize_axis(SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_RIGHTX));
        *y = -normalize_axis(SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_RIGHTY));
    }
}

void bananapad::native::set_right_analog_suppressed(bool suppressed) {
    right_analog_suppressed.store(suppressed, std::memory_order_relaxed);
}

void bananapad::native::set_rumble(int, bool rumble) {
    std::lock_guard lock(controller_mutex);
    if (controller != nullptr && SDL_GameControllerGetAttached(controller)) {
        const uint16_t strength = rumble ? 0xFFFF : 0;
        SDL_GameControllerRumble(controller, strength, strength, rumble ? 100 : 0);
    }
}

ultramodern::input::connected_device_info_t bananapad::native::get_connected_device_info(int controller_num) {
    if (controller_num != 0) {
        return {ultramodern::input::Device::None, ultramodern::input::Pak::None};
    }
    return {ultramodern::input::Device::Controller, ultramodern::input::Pak::RumblePak};
}

void bananapad::native::get_window_size(int& width, int& height) {
    width = 1600;
    height = 900;
    if (app_window != nullptr) SDL_GetWindowSize(app_window, &width, &height);
}

void bananapad::native::show_message(const char* message) {
    std::fprintf(stderr, "%s\n", message ? message : "BananaPad error");
    SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "BananaPad", message, app_window);
}

std::filesystem::path bananapad::native::app_support_path() {
#if defined(__APPLE__) && TARGET_OS_IPHONE
    // The UIKit shell creates and enters the app's private support directory
    // before starting the recompiled runtime.
    return std::filesystem::current_path();
#else
    // An empty organization keeps the path compatible with the existing
    // BananaPad install at Application Support/BananaPad on Apple platforms.
    char* pref = SDL_GetPrefPath("", "BananaPad");
    if (pref == nullptr) return std::filesystem::current_path() / "user";
    std::filesystem::path result(pref);
    SDL_free(pref);
    std::filesystem::create_directories(result);
    return result;
#endif
}

float bananapad::native::audio_volume() {
    return output_volume.load(std::memory_order_relaxed);
}

extern "C" void PaperPad_SetAudioVolume(float volume) {
    output_volume.store(std::clamp(volume, 0.0f, 1.0f), std::memory_order_relaxed);
}

extern "C" void PaperPad_SetGraphicsConfig(int resolution_mode, int aspect_mode, int) {
    auto config = ultramodern::renderer::get_graphics_config();
    const int fixed_scale = std::clamp(resolution_mode, 0, 4);
    config.resolution_multiplier = fixed_scale > 0 ? fixed_scale : 2.0;
    switch (fixed_scale) {
        case 1: config.res_option = ultramodern::renderer::Resolution::Original; break;
        case 2: config.res_option = ultramodern::renderer::Resolution::Original2x; break;
        case 3:
        case 4: config.res_option = ultramodern::renderer::Resolution::Manual; break;
        default: config.res_option = ultramodern::renderer::Resolution::Auto; break;
    }
    config.ar_option = aspect_mode == 1
        ? ultramodern::renderer::AspectRatio::Expand
        : ultramodern::renderer::AspectRatio::Original;
    config.api_option = ultramodern::renderer::GraphicsApi::Metal;
    ultramodern::renderer::set_graphics_config(config);
}

extern "C" int PaperPad_GetEffectiveRenderState(
        uint32_t* scale_milli, uint32_t* internal_width, uint32_t* internal_height) {
    constexpr float N64ReferenceWidth = 320.0f;
    constexpr float N64ReferenceHeight = 240.0f;
    const float effective_scale = std::max(ultramodern::get_resolution_scale(), 0.0f);
    if (scale_milli) {
        *scale_milli = static_cast<uint32_t>(std::lround(effective_scale * 1000.0f));
    }
    if (internal_width) {
        *internal_width = static_cast<uint32_t>(std::lround(N64ReferenceWidth * effective_scale));
    }
    if (internal_height) {
        *internal_height = static_cast<uint32_t>(std::lround(N64ReferenceHeight * effective_scale));
    }
    return app_window != nullptr ? 1 : 0;
}
