#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <flutter_windows.h>
#include <algorithm>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();
  const bool smoke_test = std::any_of(command_line_arguments.begin(), command_line_arguments.end(),
    [](const std::string& value) { return value.rfind("--desktop-smoke-test=", 0) == 0; });

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project, !smoke_test);
  Win32Window::Point origin(10, 10);
  const HMONITOR monitor = MonitorFromPoint(POINT{10, 10}, MONITOR_DEFAULTTONEAREST);
  MONITORINFO info{}; info.cbSize = sizeof(info);
  GetMonitorInfo(monitor, &info);
  const double scale = FlutterDesktopGetDpiForMonitor(monitor) / 96.0;
  const int height = std::max(320, std::min(850,
    static_cast<int>((info.rcWork.bottom - info.rcWork.top) / scale) - 24));
  const int width = std::max(240, std::min({480, height * 3 / 5,
    static_cast<int>((info.rcWork.right - info.rcWork.left) / scale) - 24}));
  Win32Window::Size size(static_cast<unsigned int>(width), static_cast<unsigned int>(height));
  if (!window.Create(L"sornaz", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
