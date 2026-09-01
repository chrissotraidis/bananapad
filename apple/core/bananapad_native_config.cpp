#include "donk_config.h"
#include "donk_draw.h"
#include "donk_sound.h"

void dk64::init_config() {}

dk64::CameraInvertMode dk64::get_camera_invert_mode() { return CameraInvertMode::InvertNone; }
dk64::CameraInvertMode dk64::get_third_person_camera_mode() { return CameraInvertMode::InvertNone; }
dk64::CameraInvertMode dk64::get_swimming_invert_mode() { return CameraInvertMode::InvertY; }
dk64::CameraInvertMode dk64::get_first_person_invert_mode() { return CameraInvertMode::InvertY; }
uint32_t dk64::get_analog_cam_sensitivity() { return 3; }
dk64::StorySkipMode dk64::get_story_skip() { return StorySkipMode::Off; }
dk64::CameraTypeMode dk64::get_camera_type() { return CameraTypeMode::Free; }
dk64::LightningFlashMode dk64::get_lightning_flash() { return LightningFlashMode::Reduced; }
dk64::CutsceneBordersMode dk64::get_cutscene_borders() { return CutsceneBordersMode::On; }
dk64::MultiplayerEnabled dk64::get_multiplayer_enabled() { return MultiplayerEnabled::Off; }
int dk64::get_bgm_volume() { return 100; }
int dk64::get_sfx_volume() { return 100; }
int dk64::get_draw_distance() { return 0; }
