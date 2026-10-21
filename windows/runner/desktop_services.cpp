#include "desktop_services.h"
#include <flutter/standard_method_codec.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Data.Pdf.h>
#include <winrt/Windows.Storage.h>
#include <winrt/Windows.Storage.Streams.h>
#include <winrt/Windows.Media.Capture.h>
#include <winrt/Windows.Media.MediaProperties.h>
#include <filesystem>
#include <algorithm>
#include <stdexcept>

DesktopServices::DesktopServices(flutter::BinaryMessenger* messenger, HWND window)
    : window_(window) {
  controls_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "sornaz/video_controls", &flutter::StandardMethodCodec::GetInstance());
  controls_channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    if (call.method_name() == "closeWindow") {
      result->Success();
      PostMessage(window_, WM_CLOSE, 0, 0);
      return;
    }
    if (call.method_name() == "activate") {
      ShowWindow(window_, SW_RESTORE); SetForegroundWindow(window_); result->Success(); return;
    }
    if (call.method_name() != "rotateWindow") { result->NotImplemented(); return; }
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) { result->Error("INVALID_ARGUMENT", "Orientation missing"); return; }
    const auto entry = args->find(flutter::EncodableValue("landscape"));
    if (entry == args->end() || !std::holds_alternative<bool>(entry->second)) {
      result->Error("INVALID_ARGUMENT", "Orientation missing"); return;
    }
    const bool landscape = std::get<bool>(entry->second);
    if (landscape != landscape_) {
      RECT rect{}; GetWindowRect(window_, &rect);
      if (landscape) portrait_rect_ = rect;
      MONITORINFO monitor{}; monitor.cbSize = sizeof(monitor);
      GetMonitorInfo(MonitorFromWindow(window_, MONITOR_DEFAULTTONEAREST), &monitor);
      const int width = landscape ? rect.bottom - rect.top : portrait_rect_.right - portrait_rect_.left;
      const int height = landscape ? rect.right - rect.left : portrait_rect_.bottom - portrait_rect_.top;
      const int safe_width = std::min(width, static_cast<int>(monitor.rcWork.right - monitor.rcWork.left));
      const int safe_height = std::min(height, static_cast<int>(monitor.rcWork.bottom - monitor.rcWork.top));
      SetWindowPos(window_, nullptr,
        std::clamp(static_cast<int>(rect.left), static_cast<int>(monitor.rcWork.left), static_cast<int>(monitor.rcWork.right) - safe_width),
        std::clamp(static_cast<int>(rect.top), static_cast<int>(monitor.rcWork.top), static_cast<int>(monitor.rcWork.bottom) - safe_height),
        safe_width, safe_height, SWP_NOZORDER | SWP_NOACTIVATE);
      landscape_ = landscape;
    }
    result->Success();
  });
  camera_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "sornaz/windows_camera", &flutter::StandardMethodCodec::GetInstance());
  camera_channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (call.method_name() != "capture" || !args) { result->NotImplemented(); return; }
    const auto entry = args->find(flutter::EncodableValue("path"));
    if (entry == args->end() || !std::holds_alternative<std::string>(entry->second)) {
      result->Error("INVALID_ARGUMENT", "Capture path missing"); return;
    }
    const auto path = std::get<std::string>(entry->second);
    workers_.emplace_back([this, path, result = std::move(result)]() mutable {
      Completion completion{std::move(result), flutter::EncodableValue(), ""};
      try {
        winrt::init_apartment(winrt::apartment_type::multi_threaded);
        const std::filesystem::path target(winrt::to_hstring(path).c_str());
        const auto folder = winrt::Windows::Storage::StorageFolder::GetFolderFromPathAsync(
          target.parent_path().wstring()).get();
        const auto file = folder.CreateFileAsync(target.filename().wstring(),
          winrt::Windows::Storage::CreationCollisionOption::FailIfExists).get();
        winrt::Windows::Media::Capture::MediaCaptureInitializationSettings settings;
        settings.StreamingCaptureMode(winrt::Windows::Media::Capture::StreamingCaptureMode::Video);
        winrt::Windows::Media::Capture::MediaCapture capture;
        capture.InitializeAsync(settings).get();
        capture.CapturePhotoToStorageFileAsync(
          winrt::Windows::Media::MediaProperties::ImageEncodingProperties::CreateJpeg(), file).get();
        capture.Close();
        completion.value = flutter::EncodableValue(path);
      } catch (const winrt::hresult_error& error) { completion.error = winrt::to_string(error.message()); }
        catch (const std::exception& error) { completion.error = error.what(); }
      { std::lock_guard<std::mutex> lock(mutex_); completed_.push_back(std::move(completion)); }
      PostMessage(window_, kCompleted, 0, 0);
    });
  });
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "sornaz/private_pdf", &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    if (call.method_name() != "render") { result->NotImplemented(); return; }
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) { result->Error("INVALID_ARGUMENT", "PDF arguments missing"); return; }
    const auto file = args->find(flutter::EncodableValue("path"));
    const auto page = args->find(flutter::EncodableValue("page"));
    if (file == args->end() || page == args->end() ||
        !std::holds_alternative<std::string>(file->second)) {
      result->Error("INVALID_ARGUMENT", "PDF path or page missing"); return;
    }
    const auto path = std::get<std::string>(file->second);
    int64_t index = -1;
    if (const auto value = std::get_if<int32_t>(&page->second)) index = *value;
    else if (const auto wide_value = std::get_if<int64_t>(&page->second)) index = *wide_value;
    workers_.emplace_back([this, path, index, result = std::move(result)]() mutable {
      Completion completion{std::move(result), flutter::EncodableValue(), ""};
      try {
        winrt::init_apartment(winrt::apartment_type::multi_threaded);
        const auto file = winrt::Windows::Storage::StorageFile::GetFileFromPathAsync(
          winrt::to_hstring(path)).get();
        const auto document = winrt::Windows::Data::Pdf::PdfDocument::LoadFromFileAsync(file).get();
        if (index < 0 || index >= static_cast<int64_t>(document.PageCount())) throw std::runtime_error("Invalid PDF page");
        const auto page = document.GetPage(static_cast<uint32_t>(index));
        winrt::Windows::Storage::Streams::InMemoryRandomAccessStream stream;
        winrt::Windows::Data::Pdf::PdfPageRenderOptions options;
        const auto size = page.Size();
        const float scale = std::min(2.0f, 2048.0f / std::max(size.Width, size.Height));
        options.DestinationWidth(static_cast<uint32_t>(std::max(1.0f, size.Width * scale)));
        options.DestinationHeight(static_cast<uint32_t>(std::max(1.0f, size.Height * scale)));
        page.RenderToStreamAsync(stream, options).get();
        if (stream.Size() > 32 * 1024 * 1024) throw std::runtime_error("PDF page is too large");
        winrt::Windows::Storage::Streams::DataReader reader(stream.GetInputStreamAt(0));
        reader.LoadAsync(static_cast<uint32_t>(stream.Size())).get();
        std::vector<uint8_t> bytes(static_cast<size_t>(stream.Size()));
        reader.ReadBytes(bytes);
        completion.value = flutter::EncodableValue(flutter::EncodableMap{
          {flutter::EncodableValue("bytes"), flutter::EncodableValue(bytes)},
          {flutter::EncodableValue("count"), flutter::EncodableValue(static_cast<int32_t>(document.PageCount()))},
        });
        reader.Close(); stream.Close(); page.Close();
      } catch (const winrt::hresult_error& error) {
        completion.error = winrt::to_string(error.message());
      } catch (const std::exception& error) { completion.error = error.what(); }
      {
        std::lock_guard<std::mutex> lock(mutex_);
        completed_.push_back(std::move(completion));
      }
      PostMessage(window_, kCompleted, 0, 0);
    });
  });
}

bool DesktopServices::HandleMessage(UINT message) {
  if (message != kCompleted) return false;
  std::vector<Completion> ready;
  { std::lock_guard<std::mutex> lock(mutex_); ready.swap(completed_); }
  for (auto& completion : ready) {
    if (completion.error.empty()) completion.result->Success(completion.value);
    else completion.result->Error("PDF_RENDER_FAILED", completion.error);
  }
  return true;
}

DesktopServices::~DesktopServices() {
  controls_channel_->SetMethodCallHandler(nullptr);
  channel_->SetMethodCallHandler(nullptr);
  camera_channel_->SetMethodCallHandler(nullptr);
  for (auto& worker : workers_) if (worker.joinable()) worker.join();
  HandleMessage(kCompleted);
}
