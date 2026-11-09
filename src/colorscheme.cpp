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
                     // The neutral greys of the style's light and dark schemes
                     : dark  ? Colors{0x1e1e1e, 0xe6e6e6, 0x242424, 0x2e2e2e, 0x323232,
                                      0x3a3a3a, 0x141414, 0x454545, 0xa0a0a0, 0x6e6e6e}
                             : Colors{0xf8f8f8, 0x2a2a2a, 0xffffff, 0xeeeeee, 0xeeeeee,
                                      0xe0e0e0, 0x9a9a9a, 0xffffff, 0x6e6e6e, 0xa0a0a0};
    QPalette p;
    p.setColor(QPalette::Window, QColor(c.window));
    p.setColor(QPalette::WindowText, QColor(c.windowText));
    p.setColor(QPalette::Base, QColor(c.base));
    p.setColor(QPalette::AlternateBase, QColor(c.alternateBase));
    p.setColor(QPalette::Text, QColor(c.windowText));
    p.setColor(QPalette::Button, QColor(c.button));
    p.setColor(QPalette::ButtonText, QColor(c.windowText));
    // Selections neutral like the program's, blue in the classic colours
    p.setColor(QPalette::Highlight, classic ? QColor(0x316ac5) : dark ? QColor(0xe0e0e0) : QColor(0x2a2a2a));
    p.setColor(QPalette::HighlightedText, dark && !classic ? QColor(0x1e1e1e) : QColor(Qt::white));
    p.setColor(QPalette::PlaceholderText, QColor(c.placeholder));
    p.setColor(QPalette::ToolTipBase, dark ? QColor(0xe0e0e0) : QColor(0x2a2a2a));
    p.setColor(QPalette::ToolTipText, dark ? QColor(0x1e1e1e) : QColor(0xfafafa));
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
