#include "uistyle.h"

#include <QDir>
#include <QFile>
#include <QQuickStyle>
#include <QSettings>

namespace {

const QString kKey = QStringLiteral("ui/style");
const QString kDefault = QStringLiteral("Fusion");

QList<UiStyle::Info> g_available;

} // namespace

namespace UiStyle {

QList<Info> detect(const QStringList &importPaths)
{
    // The order of the list in the settings
    const QList<Info> known = {
        {QStringLiteral("Fusion"), QStringLiteral("Fusion (Standard)")},
        {QStringLiteral("Carbon"), QStringLiteral("Carbon (IBM Design System)")},
        {QStringLiteral("Material"), QStringLiteral("Material")},
        {QStringLiteral("Universal"), QStringLiteral("Universal")},
        {QStringLiteral("FluentWinUI3"), QStringLiteral("Fluent (WinUI 3)")},
        {QStringLiteral("Basic"), QStringLiteral("Basic")},
        {QStringLiteral("Imagine"), QStringLiteral("Imagine")},
        {QStringLiteral("macOS"), QStringLiteral("macOS")},
        {QStringLiteral("Windows"), QStringLiteral("Windows")},
    };
    g_available.clear();
    for (const Info &style : known) {
        bool found = false;
        if (style.name == QLatin1String("Carbon")) {
            // Built into the program
            found = QFile::exists(QStringLiteral(":/qt/qml/Carbon/qmldir"));
        } else {
            for (const QString &path : importPaths) {
                const QString dir = path.startsWith(QLatin1String("qrc:")) ? path.mid(3) : path;
                if (QFile::exists(QDir(dir).filePath(QStringLiteral("QtQuick/Controls/%1/qmldir").arg(style.name)))) {
                    found = true;
                    break;
                }
            }
        }
        if (found)
            g_available.append(style);
    }
    return g_available;
}

QList<Info> available()
{
    return g_available;
}

QString saved()
{
    return QSettings().value(kKey, kDefault).toString();
}

void save(const QString &name)
{
    QSettings().setValue(kKey, name);
}

QString choose(const QString &requested)
{
    for (const Info &style : g_available) {
        if (style.name.compare(requested, Qt::CaseInsensitive) == 0)
            return style.name;
    }
    return kDefault;
}

void apply(const QString &name)
{
    QQuickStyle::setStyle(name);
    // Our own style builds on Basic for the controls it leaves out
    if (name == QLatin1String("Carbon"))
        QQuickStyle::setFallbackStyle(QStringLiteral("Basic"));
    // Material and Universal: follow the colour scheme, with the program's
    // orange as accent, unless set from outside
    const auto setDefault = [](const char *var, const QByteArray &value) {
        if (!qEnvironmentVariableIsSet(var))
            qputenv(var, value);
    };
    setDefault("QT_QUICK_CONTROLS_MATERIAL_THEME", "System");
    setDefault("QT_QUICK_CONTROLS_MATERIAL_ACCENT", "#C2410C");
    // The compact variant suits a desktop program (32 instead of 48 px)
    setDefault("QT_QUICK_CONTROLS_MATERIAL_VARIANT", "Dense");
    setDefault("QT_QUICK_CONTROLS_UNIVERSAL_THEME", "System");
    setDefault("QT_QUICK_CONTROLS_UNIVERSAL_ACCENT", "#C2410C");
}

} // namespace UiStyle
