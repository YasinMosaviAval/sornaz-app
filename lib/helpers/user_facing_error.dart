String userFacingError(Object error, {bool english = false}) {
  final text = error.toString();
  if (RegExp(
    r'https?://|api/|SocketException|ClientException|Exception:|SQLSTATE|stack trace|FileSystemException|TimeoutException',
    caseSensitive: false,
  ).hasMatch(text)) {
    return english
        ? 'The service is unavailable. Check your connection and try again.'
        : 'ارتباط با سرویس برقرار نشد. اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.';
  }
  return text.length > 250
      ? (english
            ? 'The operation could not be completed.'
            : 'عملیات انجام نشد. دوباره تلاش کنید.')
      : text;
}
