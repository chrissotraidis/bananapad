#include <memory>
#include <cstring>
#include <algorithm>
#include <cstdint>
#include <cstdio>

#include "hle/rt64_application.h"
#include "contrib/xxHash/xxhash.h"

#include "ultramodern/ultramodern.hpp"
#include "ultramodern/config.hpp"

#include "bananapad_rt64_context.h"

namespace {

static RT64::UserConfiguration::Antialiasing device_max_msaa = RT64::UserConfiguration::Antialiasing::None;
static bool high_precision_fb_enabled = false;

static uint8_t DMEM[0x1000];
static uint8_t IMEM[0x1000];

unsigned int MI_INTR_REG = 0;

unsigned int DPC_START_REG = 0;
unsigned int DPC_END_REG = 0;
unsigned int DPC_CURRENT_REG = 0;
unsigned int DPC_STATUS_REG = 0;
unsigned int DPC_CLOCK_REG = 0;
unsigned int DPC_BUFBUSY_REG = 0;
unsigned int DPC_PIPEBUSY_REG = 0;
unsigned int DPC_TMEM_REG = 0;

void dummy_check_interrupts() {}

RT64::UserConfiguration::Antialiasing compute_max_supported_aa(plume::RenderSampleCounts bits) {
    if (bits & plume::RenderSampleCount::Bits::COUNT_2) {
        if (bits & plume::RenderSampleCount::Bits::COUNT_4) {
            if (bits & plume::RenderSampleCount::Bits::COUNT_8) {
                return RT64::UserConfiguration::Antialiasing::MSAA8X;
            }
            return RT64::UserConfiguration::Antialiasing::MSAA4X;
        }
        return RT64::UserConfiguration::Antialiasing::MSAA2X;
    };
    return RT64::UserConfiguration::Antialiasing::None;
}

RT64::UserConfiguration::AspectRatio to_rt64(ultramodern::renderer::AspectRatio option) {
    switch (option) {
        case ultramodern::renderer::AspectRatio::Original:
            return RT64::UserConfiguration::AspectRatio::Original;
        case ultramodern::renderer::AspectRatio::Expand:
            return RT64::UserConfiguration::AspectRatio::Expand;
        case ultramodern::renderer::AspectRatio::Manual:
            return RT64::UserConfiguration::AspectRatio::Manual;
        case ultramodern::renderer::AspectRatio::OptionCount:
            return RT64::UserConfiguration::AspectRatio::OptionCount;
    }
}

RT64::UserConfiguration::Antialiasing to_rt64(ultramodern::renderer::Antialiasing option) {
    switch (option) {
        case ultramodern::renderer::Antialiasing::None:
            return RT64::UserConfiguration::Antialiasing::None;
        case ultramodern::renderer::Antialiasing::MSAA2X:
            return RT64::UserConfiguration::Antialiasing::MSAA2X;
        case ultramodern::renderer::Antialiasing::MSAA4X:
            return RT64::UserConfiguration::Antialiasing::MSAA4X;
        case ultramodern::renderer::Antialiasing::MSAA8X:
            return RT64::UserConfiguration::Antialiasing::MSAA8X;
        case ultramodern::renderer::Antialiasing::OptionCount:
            return RT64::UserConfiguration::Antialiasing::OptionCount;
    }
}

RT64::UserConfiguration::RefreshRate to_rt64(ultramodern::renderer::RefreshRate option) {
    switch (option) {
        case ultramodern::renderer::RefreshRate::Original:
            return RT64::UserConfiguration::RefreshRate::Original;
        case ultramodern::renderer::RefreshRate::Display:
            return RT64::UserConfiguration::RefreshRate::Display;
        case ultramodern::renderer::RefreshRate::Manual:
            return RT64::UserConfiguration::RefreshRate::Manual;
        case ultramodern::renderer::RefreshRate::OptionCount:
            return RT64::UserConfiguration::RefreshRate::OptionCount;
    }
}

RT64::UserConfiguration::InternalColorFormat to_rt64(ultramodern::renderer::HighPrecisionFramebuffer option) {
    switch (option) {
        case ultramodern::renderer::HighPrecisionFramebuffer::Off:
            return RT64::UserConfiguration::InternalColorFormat::Standard;
        case ultramodern::renderer::HighPrecisionFramebuffer::On:
            return RT64::UserConfiguration::InternalColorFormat::High;
        case ultramodern::renderer::HighPrecisionFramebuffer::Auto:
            return RT64::UserConfiguration::InternalColorFormat::Automatic;
        case ultramodern::renderer::HighPrecisionFramebuffer::OptionCount:
            return RT64::UserConfiguration::InternalColorFormat::OptionCount;
    }
}

RT64::EnhancementConfiguration::Presentation::Mode to_rt64(ultramodern::renderer::PresentationMode mode) {
    switch (mode) {
        case ultramodern::renderer::PresentationMode::Console:
            return RT64::EnhancementConfiguration::Presentation::Mode::Console;
        case ultramodern::renderer::PresentationMode::SkipBuffering:
            return RT64::EnhancementConfiguration::Presentation::Mode::SkipBuffering;
        case ultramodern::renderer::PresentationMode::PresentEarly:
            return RT64::EnhancementConfiguration::Presentation::Mode::PresentEarly;
    }
}

void set_application_user_config(RT64::Application* application, const ultramodern::renderer::GraphicsConfig& config) {
    switch (config.res_option) {
        default:
        case ultramodern::renderer::Resolution::Auto:
            application->userConfig.resolution = RT64::UserConfiguration::Resolution::WindowIntegerScale;
            application->userConfig.downsampleMultiplier = 1;
            break;
        case ultramodern::renderer::Resolution::Original:
            application->userConfig.resolution = RT64::UserConfiguration::Resolution::Manual;
            application->userConfig.resolutionMultiplier = std::max(config.ds_option, 1);
            application->userConfig.downsampleMultiplier = std::max(config.ds_option, 1);
            break;
        case ultramodern::renderer::Resolution::Original2x:
            application->userConfig.resolution = RT64::UserConfiguration::Resolution::Manual;
            application->userConfig.resolutionMultiplier = 2.0 * std::max(config.ds_option, 1);
            application->userConfig.downsampleMultiplier = std::max(config.ds_option, 1);
            break;
        case ultramodern::renderer::Resolution::Manual:
            application->userConfig.resolution = RT64::UserConfiguration::Resolution::Manual;
            application->userConfig.resolutionMultiplier =
                std::clamp(config.resolution_multiplier, 1.0, 32.0) * std::max(config.ds_option, 1);
            application->userConfig.downsampleMultiplier = std::max(config.ds_option, 1);
            break;
    }

    switch (config.hr_option) {
        default:
        case ultramodern::renderer::HUDRatioMode::Original:
            application->userConfig.extAspectRatio = RT64::UserConfiguration::AspectRatio::Original;
            break;
        case ultramodern::renderer::HUDRatioMode::Clamp16x9:
            application->userConfig.extAspectRatio = RT64::UserConfiguration::AspectRatio::Manual;
            application->userConfig.extAspectTarget = 16.0/9.0;
            break;
        case ultramodern::renderer::HUDRatioMode::Full:
            application->userConfig.extAspectRatio = RT64::UserConfiguration::AspectRatio::Expand;
            break;
    }

    application->userConfig.aspectRatio = to_rt64(config.ar_option);
    application->userConfig.antialiasing = to_rt64(config.msaa_option);
    application->userConfig.refreshRate = to_rt64(config.rr_option);
    application->userConfig.refreshRateTarget = config.rr_manual_value;
    application->userConfig.internalColorFormat = to_rt64(config.hpfb_option);
    application->userConfig.displayBuffering = RT64::UserConfiguration::DisplayBuffering::Triple;
}

ultramodern::renderer::SetupResult map_setup_result(RT64::Application::SetupResult rt64_result) {
    switch (rt64_result) {
        case RT64::Application::SetupResult::Success:
            return ultramodern::renderer::SetupResult::Success;
        case RT64::Application::SetupResult::DynamicLibrariesNotFound:
            return ultramodern::renderer::SetupResult::DynamicLibrariesNotFound;
        case RT64::Application::SetupResult::InvalidGraphicsAPI:
            return ultramodern::renderer::SetupResult::InvalidGraphicsAPI;
        case RT64::Application::SetupResult::GraphicsAPINotFound:
            return ultramodern::renderer::SetupResult::GraphicsAPINotFound;
        case RT64::Application::SetupResult::GraphicsDeviceNotFound:
            return ultramodern::renderer::SetupResult::GraphicsDeviceNotFound;
    }

    fprintf(stderr, "Unhandled `RT64::Application::SetupResult` ?\n");
    assert(false);
    std::exit(EXIT_FAILURE);
}

ultramodern::renderer::GraphicsApi map_graphics_api(RT64::UserConfiguration::GraphicsAPI api) {
    switch (api) {
        case RT64::UserConfiguration::GraphicsAPI::D3D12:
            return ultramodern::renderer::GraphicsApi::D3D12;
        case RT64::UserConfiguration::GraphicsAPI::Vulkan:
            return ultramodern::renderer::GraphicsApi::Vulkan;
        case RT64::UserConfiguration::GraphicsAPI::Metal:
            return ultramodern::renderer::GraphicsApi::Metal;
        case RT64::UserConfiguration::GraphicsAPI::Automatic:
            return ultramodern::renderer::GraphicsApi::Auto;
        default:
            break;
    }

    fprintf(stderr, "Unhandled `RT64::UserConfiguration::GraphicsAPI` ?\n");
    assert(false);
    std::exit(EXIT_FAILURE);
}

} // namespace

bananapad::renderer::RT64Context::RT64Context(uint8_t* rdram, ultramodern::renderer::WindowHandle window_handle, ultramodern::renderer::PresentationMode presentation_mode, bool debug) {
    static unsigned char dummy_rom_header[0x40];

    // Set up the RT64 application core fields.
    RT64::Application::Core appCore{};
#if defined(_WIN32)
    appCore.window = window_handle.window;
#elif defined(__linux__) || defined(__ANDROID__)
    appCore.window = window_handle;
#elif defined(__APPLE__)
    appCore.window.window = window_handle.window;
    appCore.window.view = window_handle.view;
#endif

    appCore.checkInterrupts = dummy_check_interrupts;

    appCore.HEADER = dummy_rom_header;
    appCore.RDRAM = rdram;
    appCore.DMEM = DMEM;
    appCore.IMEM = IMEM;

    appCore.MI_INTR_REG = &MI_INTR_REG;

    appCore.DPC_START_REG = &DPC_START_REG;
    appCore.DPC_END_REG = &DPC_END_REG;
    appCore.DPC_CURRENT_REG = &DPC_CURRENT_REG;
    appCore.DPC_STATUS_REG = &DPC_STATUS_REG;
    appCore.DPC_CLOCK_REG = &DPC_CLOCK_REG;
    appCore.DPC_BUFBUSY_REG = &DPC_BUFBUSY_REG;
    appCore.DPC_PIPEBUSY_REG = &DPC_PIPEBUSY_REG;
    appCore.DPC_TMEM_REG = &DPC_TMEM_REG;

    ultramodern::renderer::ViRegs *vi_regs = ultramodern::renderer::get_vi_regs();
    appCore.VI_STATUS_REG = &vi_regs->VI_STATUS_REG;
    appCore.VI_ORIGIN_REG = &vi_regs->VI_ORIGIN_REG;
    appCore.VI_WIDTH_REG = &vi_regs->VI_WIDTH_REG;
    appCore.VI_INTR_REG = &vi_regs->VI_INTR_REG;
    appCore.VI_V_CURRENT_LINE_REG = &vi_regs->VI_V_CURRENT_LINE_REG;
    appCore.VI_TIMING_REG = &vi_regs->VI_TIMING_REG;
    appCore.VI_V_SYNC_REG = &vi_regs->VI_V_SYNC_REG;
    appCore.VI_H_SYNC_REG = &vi_regs->VI_H_SYNC_REG;
    appCore.VI_LEAP_REG = &vi_regs->VI_LEAP_REG;
    appCore.VI_H_START_REG = &vi_regs->VI_H_START_REG;
    appCore.VI_V_START_REG = &vi_regs->VI_V_START_REG;
    appCore.VI_V_BURST_REG = &vi_regs->VI_V_BURST_REG;
    appCore.VI_X_SCALE_REG = &vi_regs->VI_X_SCALE_REG;
    appCore.VI_Y_SCALE_REG = &vi_regs->VI_Y_SCALE_REG;

    // Set up the RT64 application configuration fields.
    RT64::ApplicationConfiguration appConfig;
    appConfig.useConfigurationFile = false;

    // Create the RT64 application.
    app = std::make_unique<RT64::Application>(appCore, appConfig);

    // Set initial user config settings based on the current settings.
    auto& cur_config = ultramodern::renderer::get_graphics_config();
    set_application_user_config(app.get(), cur_config);
    app->userConfig.developerMode = debug;
    // Force gbi depth branches to prevent LODs from kicking in.
    app->enhancementConfig.f3dex.forceBranch = true;
    // Scale LODs based on the output resolution.
    app->enhancementConfig.textureLOD.scale = true;
    // Set the target presentation mode.
    app->enhancementConfig.presentation.mode = to_rt64(presentation_mode);
    // Pick an API if the user has set an override.
    switch (cur_config.api_option) {
        case ultramodern::renderer::GraphicsApi::D3D12:
            app->userConfig.graphicsAPI = RT64::UserConfiguration::GraphicsAPI::D3D12;
            break;
        case ultramodern::renderer::GraphicsApi::Vulkan:
            app->userConfig.graphicsAPI = RT64::UserConfiguration::GraphicsAPI::Vulkan;
            break;
        case ultramodern::renderer::GraphicsApi::Metal:
            app->userConfig.graphicsAPI = RT64::UserConfiguration::GraphicsAPI::Metal;
            break;
        case ultramodern::renderer::GraphicsApi::Auto:
        default:
            app->userConfig.graphicsAPI = RT64::UserConfiguration::GraphicsAPI::Automatic;
            break;
    }

    // Set up the RT64 application.
    uint32_t thread_id = 0;
#ifdef _WIN32
    thread_id = window_handle.thread_id;
#endif
    setup_result = map_setup_result(app->setup(thread_id));
    // Get the API that RT64 chose.
    chosen_api = map_graphics_api(app->chosenGraphicsAPI);
    if (setup_result != ultramodern::renderer::SetupResult::Success) {
        app = nullptr;
        return;
    }

    // Set the application's fullscreen state.
    app->setFullScreen(cur_config.wm_option == ultramodern::renderer::WindowMode::Fullscreen);

    // Check if the selected device actually supports MSAA sample positions and MSAA for for the formats that will be used
    // and downgrade the configuration accordingly.
    if (app->device->getCapabilities().sampleLocations) {
        plume::RenderSampleCounts color_sample_counts = app->device->getSampleCountsSupported(plume::RenderFormat::R8G8B8A8_UNORM);
        plume::RenderSampleCounts depth_sample_counts = app->device->getSampleCountsSupported(plume::RenderFormat::D32_FLOAT);
        plume::RenderSampleCounts common_sample_counts = color_sample_counts & depth_sample_counts;
        device_max_msaa = compute_max_supported_aa(common_sample_counts);
    } else {
        device_max_msaa = RT64::UserConfiguration::Antialiasing::None;
    }

    high_precision_fb_enabled = app->shaderLibrary->usesHDR;
}

bananapad::renderer::RT64Context::~RT64Context() = default;

void bananapad::renderer::RT64Context::send_dl(const OSTask* task) {
    app->state->rsp->reset();
    const uint32_t text_address = task->t.ucode & 0x3FFFFFF;
    const uint32_t data_address = task->t.ucode_data & 0x3FFFFFF;
    app->interpreter->loadUCodeGBI(text_address, data_address, true);
    if (app->interpreter->hleGBI == nullptr) {
        // RT64's release build otherwise dereferences the null GBI in
        // processDisplayLists. A transiently changing ucode region must cost
        // at most one frame: invalidate the failed address cache so the next
        // task hashes it again, then let the normal SP/DP completion path run.
        const uint64_t text_hash = XXH3_64bits(&app->core.RDRAM[text_address], 0x1390);
        const uint64_t data_hash = XXH3_64bits(&app->core.RDRAM[data_address], 0x420);
        std::fprintf(stderr,
            "[bananapad] RT64 rejected ucode text=0x%08X hash=0x%016llX "
            "data=0x%08X hash=0x%016llX; "
            "skipping this display list and retrying the next task\n",
            static_cast<unsigned int>(text_address),
            static_cast<unsigned long long>(text_hash),
            static_cast<unsigned int>(data_address),
            static_cast<unsigned long long>(data_hash));
        app->interpreter->UCode.textAddress = UINT32_MAX;
        app->interpreter->UCode.dataAddress = UINT32_MAX;
        return;
    }
    app->processDisplayLists(app->core.RDRAM, task->t.data_ptr & 0x3FFFFFF, 0, true);
}

void bananapad::renderer::RT64Context::send_dummy_workload(uint32_t fb_address) {
    app->state->listProcessBegin();
    app->state->rdp->setColorImage(G_IM_FMT_RGBA, G_IM_SIZ_16b, 320, fb_address);
    // G_AD_DISABLE | G_CD_MAGICSQ | G_CK_NONE | G_TC_FILT | G_TF_BILERP | G_TT_NONE | G_TL_TILE | G_TD_CLAMP | G_TP_PERSP | G_CYC_FILL | G_PM_NPRIMITIVE
    // G_AC_NONE | G_ZS_PIXEL | G_RM_NOOP | G_RM_NOOP2
    app->state->rdp->setOtherMode(0x382C30, 0);
    app->state->rdp->fillRect(0, 0, 320 << 2, 240 << 2);
    app->state->fullSync();
    app->state->listProcessEnd();
}

void bananapad::renderer::RT64Context::update_screen() {
    app->updateScreen();
}

void bananapad::renderer::RT64Context::shutdown() {
    if (app != nullptr) {
        app->end();
    }
}

bool bananapad::renderer::RT64Context::update_config(const ultramodern::renderer::GraphicsConfig& old_config, const ultramodern::renderer::GraphicsConfig& new_config) {
    if (old_config == new_config) {
        return false;
    }

    if (new_config.wm_option != old_config.wm_option) {
        app->setFullScreen(new_config.wm_option == ultramodern::renderer::WindowMode::Fullscreen);
    }

    set_application_user_config(app.get(), new_config);

    // When updating the user configuration, only discard framebuffers if an option was changed that affects the resolution.
    bool resolution_changed = new_config.res_option != old_config.res_option ||
        new_config.resolution_multiplier != old_config.resolution_multiplier;
    bool aspect_ratio_changed = new_config.ar_option != old_config.ar_option;
    bool downsampling_changed = new_config.ds_option != old_config.ds_option;
    bool msaa_changed = new_config.msaa_option != old_config.msaa_option;
    app->updateUserConfig(resolution_changed || aspect_ratio_changed || downsampling_changed || msaa_changed);

    if (msaa_changed) {
        app->updateMultisampling();
    }
    return true;
}

void bananapad::renderer::RT64Context::enable_instant_present() {
    // Enable the present early presentation mode for minimal latency.
    app->enhancementConfig.presentation.mode = RT64::EnhancementConfiguration::Presentation::Mode::PresentEarly;

    app->updateEnhancementConfig();
}

uint32_t bananapad::renderer::RT64Context::get_display_framerate() const {
    return app->presentQueue->ext.sharedResources->swapChainRate;
}

float bananapad::renderer::RT64Context::get_resolution_scale() const {
    constexpr int ReferenceHeight = 240;
    switch (app->userConfig.resolution) {
        case RT64::UserConfiguration::Resolution::WindowIntegerScale:
            if (app->sharedQueueResources->swapChainHeight > 0) {
                return std::max(float((app->sharedQueueResources->swapChainHeight + ReferenceHeight - 1) / ReferenceHeight), 1.0f);
            }
            else {
                return 1.0f;
            }
        case RT64::UserConfiguration::Resolution::Manual:
            return float(app->userConfig.resolutionMultiplier);
        case RT64::UserConfiguration::Resolution::Original:
        default:
            return 1.0f;
    }
}


std::unique_ptr<ultramodern::renderer::RendererContext> bananapad::renderer::create_render_context(
    uint8_t* rdram,
    ultramodern::renderer::WindowHandle window_handle,
    ultramodern::renderer::PresentationMode presentation_mode,
    bool developer_mode) {
    return std::make_unique<bananapad::renderer::RT64Context>(
        rdram, window_handle, presentation_mode, developer_mode);
}

bool bananapad::renderer::high_precision_framebuffer_enabled() {
    return high_precision_fb_enabled;
}
