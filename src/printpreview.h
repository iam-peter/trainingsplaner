#pragma once

#include <functional>

class QPrinter;
class QString;

// Printing as WinWoTA did it: the pages first in a preview ("Seitenvorschau")
// with zoom and page buttons; its print button asks for the printer and
// prints. paint draws the pages onto the printer it is given, for the
// preview and again for printing.
namespace PrintPreview {

// False when the preview is closed without printing
bool show(QPrinter *printer, const QString &title, const std::function<void(QPrinter *)> &paint);

} // namespace PrintPreview
