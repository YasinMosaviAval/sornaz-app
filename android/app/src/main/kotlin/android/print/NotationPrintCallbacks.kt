package android.print

// Android's SDK gives these callback constructors package visibility. Keep only
// the constructor bridge here; rendering and storage stay in the app package.
abstract class NotationLayoutCallback : PrintDocumentAdapter.LayoutResultCallback()
abstract class NotationWriteCallback : PrintDocumentAdapter.WriteResultCallback()
