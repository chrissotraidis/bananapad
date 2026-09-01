#pragma once

#include <cstdint>
#include <filesystem>

#include "ultramodern/ultramodern.hpp"

struct SDL_Window;

namespace bananapad::native {

void attach_window(SDL_Window* window);
void handle_events();
void poll_input();
bool get_input(int controller_num, uint16_t* buttons, float* x, float* y);
void get_right_analog(int controller_num, float* x, float* y);
void set_right_analog_suppressed(bool suppressed);
void set_rumble(int controller_num, bool rumble);
ultramodern::input::connected_device_info_t get_connected_device_info(int controller_num);

void get_window_size(int& width, int& height);
void show_message(const char* message);
std::filesystem::path app_support_path();
float audio_volume();

} // namespace bananapad::native
