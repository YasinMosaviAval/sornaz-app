#ifndef SORNAZ_DESKTOP_SERVICES_H_
#define SORNAZ_DESKTOP_SERVICES_H_
#include <flutter/method_channel.h>
#include <flutter/encodable_value.h>
#include <windows.h>
#include <memory>
#include <mutex>
#include <thread>
#include <vector>

// In-process PDF/camera operations and window controls for desktop parity.
class DesktopServices {
 public:
  DesktopServices(flutter::BinaryMessenger* messenger, HWND window);
  ~DesktopServices();
  bool HandleMessage(UINT message);
 private:
  using Result = flutter::MethodResult<flutter::EncodableValue>;
  struct Completion {
    std::unique_ptr<Result> result;
    flutter::EncodableValue value;
    std::string error;
  };
  static constexpr UINT kCompleted = WM_APP + 53;
  HWND window_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> camera_channel_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> controls_channel_;
  RECT portrait_rect_{};
  bool landscape_ = false;
  std::mutex mutex_;
  std::vector<Completion> completed_;
  std::vector<std::thread> workers_;
};
#endif
