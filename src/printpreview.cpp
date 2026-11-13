#include "printpreview.h"

#include <QGuiApplication>
#include <QPrintPreviewDialog>
#include <QPrintPreviewWidget>
#include <QPrinter>
#include <QScreen>

namespace PrintPreview {

bool show(QPrinter *printer, const QString &title, const std::function<void(QPrinter *)> &paint)
{
    QPrintPreviewDialog dialog(printer);
    dialog.setWindowTitle(QStringLiteral("Seitenvorschau – %1").arg(title));
    QObject::connect(&dialog, &QPrintPreviewDialog::paintRequested, &dialog,
                     [&paint](QPrinter *p) { paint(p); });
    // Large enough to read a page: most of the screen
    if (const QScreen *screen = QGuiApplication::primaryScreen()) {
        const QRect area = screen->availableGeometry();
        dialog.resize(int(area.width() * 0.7), int(area.height() * 0.9));
    }
    // A whole page in view to start with
    if (auto *preview = dialog.findChild<QPrintPreviewWidget *>())
        preview->fitInView();
    return dialog.exec() == QDialog::Accepted;
}

} // namespace PrintPreview
