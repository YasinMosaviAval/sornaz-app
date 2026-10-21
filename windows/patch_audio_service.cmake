# audio_service_win 0.0.3 leaves COM globals alive beyond CoUninitialize and
# detaches thumbnail workers that reference them. Patch a build-local copy;
# never change the shared Pub cache or generated plugin registration files.
get_target_property(_smtc_dir audio_service_win_plugin SOURCE_DIR)
file(READ "${_smtc_dir}/audio_service_win_plugin.cpp" _smtc_source)
string(REPLACE "\r\n" "\n" _smtc_source "${_smtc_source}")
set(_smtc_destructor "AudioServiceWinPlugin::~AudioServiceWinPlugin() {}")
string(FIND "${_smtc_source}" "${_smtc_destructor}" _smtc_marker)
if(_smtc_marker EQUAL -1)
  message(FATAL_ERROR "Review the audio_service_win lifecycle patch for the new plugin version")
endif()
string(REPLACE "static std::string appId;" "static std::string appId;
static std::vector<std::thread> thumbnail_workers;
static winrt::event_token button_token{};
static HWND smtc_window = nullptr;
static flutter::PluginRegistrarWindows* smtc_registrar = nullptr;
static int smtc_delegate = -1;
static constexpr UINT kSmtcButton = WM_APP + 0x574;" _smtc_source "${_smtc_source}")
string(REPLACE "registrar->AddPlugin(std::move(plugin));" "smtc_registrar = registrar;
    smtc_window = GetAncestor(registrar->GetView()->GetNativeWindow(), GA_ROOT);
    smtc_delegate = registrar->RegisterTopLevelWindowProcDelegate(
      [](HWND, UINT message, WPARAM value, LPARAM) -> std::optional<LRESULT> {
        if (message != kSmtcButton) return std::nullopt;
        std::unique_ptr<std::string> method(reinterpret_cast<std::string*>(value));
        if (channel) channel->InvokeMethod(\"onSMTCButtonPressed\",
          std::make_unique<flutter::EncodableValue>(*method));
        return 0;
      });
    registrar->AddPlugin(std::move(plugin));" _smtc_source "${_smtc_source}")
set(_smtc_callback "channel->InvokeMethod(
                               \"onSMTCButtonPressed\",
                               std::make_unique<flutter::EncodableValue>(*method));
                           delete method;")
string(REPLACE "${_smtc_callback}" "if (!PostMessage(smtc_window, kSmtcButton,
                               reinterpret_cast<WPARAM>(method), 0)) delete method;" _smtc_source "${_smtc_source}")
string(FIND "${_smtc_source}" "channel->InvokeMethod(
                               \"onSMTCButtonPressed\"" _smtc_old_callback)
if(NOT _smtc_old_callback EQUAL -1)
  message(FATAL_ERROR "Review the audio_service_win callback patch")
endif()
string(REPLACE "smtc.ButtonPressed([]" "button_token = smtc.ButtonPressed([]" _smtc_source "${_smtc_source}")
string(REPLACE "std::thread([artUri]()" "thumbnail_workers.emplace_back([artUri]()" _smtc_source "${_smtc_source}")
string(REPLACE ".detach();" ";" _smtc_source "${_smtc_source}")
string(REPLACE "${_smtc_destructor}" "AudioServiceWinPlugin::~AudioServiceWinPlugin() {
    // The engine messenger has already shut down when registrars dispose plugins.
    // Releasing the channel is safe; calling SetMethodCallHandler here is not.
    if (smtc) smtc.ButtonPressed(button_token);
    if (smtc_registrar && smtc_delegate >= 0)
      smtc_registrar->UnregisterTopLevelWindowProcDelegate(smtc_delegate);
    MSG pending{};
    while (PeekMessage(&pending, smtc_window, kSmtcButton, kSmtcButton, PM_REMOVE))
      delete reinterpret_cast<std::string*>(pending.wParam);
    for (auto& worker : thumbnail_workers) if (worker.joinable()) worker.join();
    thumbnail_workers.clear();
    try {
      if (smtc) smtc.IsEnabled(false);
      updater = nullptr;
      smtc = nullptr;
      if (mediaPlayer) mediaPlayer.Close();
      mediaPlayer = nullptr;
    } catch (...) {
      updater = nullptr; smtc = nullptr; mediaPlayer = nullptr;
    }
    channel.reset();
  }" _smtc_source "${_smtc_source}")
set(_smtc_patched "${CMAKE_CURRENT_BINARY_DIR}/sornaz_audio_service_win.cpp")
file(WRITE "${_smtc_patched}" "${_smtc_source}")
get_target_property(_smtc_sources audio_service_win_plugin SOURCES)
list(REMOVE_ITEM _smtc_sources "audio_service_win_plugin.cpp")
list(APPEND _smtc_sources "${_smtc_patched}")
set_property(TARGET audio_service_win_plugin PROPERTY SOURCES "${_smtc_sources}")
target_include_directories(audio_service_win_plugin PRIVATE "${_smtc_dir}")
install(FILES "${_smtc_dir}/../LICENSE" DESTINATION "$<TARGET_FILE_DIR:${BINARY_NAME}>/licenses/audio_service_win"
  COMPONENT Runtime)
