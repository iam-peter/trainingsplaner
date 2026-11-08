#include "colorscheme.h"

#include <QGuiApplication>
#include <QPalette>
#include <QSettings>
#include <QStyleHints>

namespace {

const QString kKey = QStringLiteral("ui/colorScheme");

// Fusion follows the scheme only where the platform supplies a palette
// for it, so both schemes come with a complete palette of their own
QPalette palette(bool dark)
{
    struct Colors
    {
        QRgb window, windowText, base, alternateBase, button, mid, dark, light, placeholder, disabled;
    };
    const Colors c = dark ? Colors{0x2b2a29, 0xeeecea, 0x1f1e1d, 0x2f2d2b, 0x353331,
                                   0x55524f, 0x1a1918, 0x4a4744, 0x9a9590, 0x777370}
                          : Colors{0xefeeec, 0x1c1917, 0xffffff, 0xf5f4f2, 0xefeeec,
                                   0xb8b4b0, 0x9f9b97, 0xffffff, 0x8a847e, 0x9f9b97};
    QPalette p;
    p.setColor(QPalette::Window, QColor(c.window));
    p.setColor(QPalette::WindowText, QColor(c.windowText));
    p.setColor(QPalette::Base, QColor(c.base));
    p.setColor(QPalette::AlternateBase, QColor(c.alternateBase));
    p.setColor(QPalette::Text, QColor(c.windowText));
    p.setColor(QPalette::Button, QColor(c.button));
    p.setColor(QPalette::ButtonText, QColor(c.windowText));
    p.setColor(QPalette::Highlight, QColor(0xc2410c));
    p.setColor(QPalette::HighlightedText, Qt::white);
    p.setColor(QPalette::PlaceholderText, QColor(c.placeholder));
    p.setColor(QPalette::ToolTipBase, dark ? QColor(c.button) : QColor(0xfffbeb));
    p.setColor(QPalette::ToolTipText, QColor(c.windowText));
    p.setColor(QPalette::Link, dark ? QColor(0x93c5fd) : QColor(0x1d4ed8));
    p.setColor(QPalette::LinkVisited, dark ? QColor(0xc4b5fd) : QColor(0x6d28d9));
    p.setColor(QPalette::Mid, QColor(c.mid));
    p.setColor(QPalette::Dark, QColor(c.dark));
    p.setColor(QPalette::Light, QColor(c.light));
    for (const auto role : {QPalette::Text, QPalette::ButtonText, QPalette::WindowText})
        p.setColor(QPalette::Disabled, role, QColor(c.disabled));
    return p;
}

} // namespace

namespace ColorScheme {

QString saved()
{
    const QString v = QSettings().value(kKey).toString();
    return v == QLatin1String("light") || v == QLatin1String("dark") ? v : QStringLiteral("system");
}

void save(const QString &scheme)
{
    QSettings().setValue(kKey, scheme);
}

void apply(const QString &scheme)
{
    auto *hints = QGuiApplication::styleHints();
    if (scheme == QLatin1String("light") || scheme == QLatin1String("dark")) {
        const bool dark = scheme == QLatin1String("dark");
        hints->setColorScheme(dark ? Qt::ColorScheme::Dark : Qt::ColorScheme::Light);
        QGuiApplication::setPalette(palette(dark));
    } else {
        // Back to the system's scheme and palette
        hints->unsetColorScheme();
        QGuiApplication::setPalette(QPalette());
    }
}

} // namespace ColorScheme
