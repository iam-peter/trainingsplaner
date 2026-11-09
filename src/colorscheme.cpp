#include "colorscheme.h"

#include <QGuiApplication>
#include <QPalette>
#include <QSettings>
#include <QStyleHints>

namespace {

const QString kKey = QStringLiteral("ui/colorScheme");
QString g_active = QStringLiteral("system");

// The program's own dialogs follow the style's tokens; the system's file
// and message dialogs follow this palette, so each scheme has a complete
// palette of its own
QPalette palette(bool dark, bool classic)
{
    struct Colors
    {
        QRgb window, windowText, base, alternateBase, button, mid, dark, light, placeholder, disabled;
    };
    const Colors c = classic ? Colors{0xece9d8, 0x000000, 0xffffff, 0xf7f3ef, 0xf7f7f7,
                                      0x949a9c, 0x716f64, 0xffffff, 0x716f64, 0xaca899}
                     : dark  ? Colors{0x2b2a29, 0xeeecea, 0x1f1e1d, 0x2f2d2b, 0x353331,
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
    p.setColor(QPalette::Highlight, classic ? QColor(0x316ac5) : QColor(0xc2410c));
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
    return v == QLatin1String("light") || v == QLatin1String("dark") || v == QLatin1String("classic")
               ? v : QStringLiteral("system");
}

void save(const QString &scheme)
{
    QSettings().setValue(kKey, scheme);
}

void apply(const QString &scheme)
{
    auto *hints = QGuiApplication::styleHints();
    g_active = scheme;
    if (scheme == QLatin1String("light") || scheme == QLatin1String("dark") || scheme == QLatin1String("classic")) {
        const bool dark = scheme == QLatin1String("dark");
        hints->setColorScheme(dark ? Qt::ColorScheme::Dark : Qt::ColorScheme::Light);
        QGuiApplication::setPalette(palette(dark, scheme == QLatin1String("classic")));
    } else {
        // Back to the system's scheme and palette
        hints->unsetColorScheme();
        QGuiApplication::setPalette(QPalette());
    }
}

QString active()
{
    return g_active;
}

} // namespace ColorScheme
