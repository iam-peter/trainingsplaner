#pragma once

#include <QList>
#include <QString>
#include <QStringList>

// The Qt Quick Controls style: Fusion by default, Carbon or Shadcn (our own) or one
// of the styles Qt brings, as far as they are installed. It is set before
// the QML engine starts, so a new choice takes effect after a restart.
namespace UiStyle {

struct Info
{
    QString name;  // as QQuickStyle knows it: "Fusion", "Carbon", "Material" ...
    QString label; // for the settings
};

// Looks the styles up in the QML import paths; the result is kept for
// available()
QList<Info> detect(const QStringList &importPaths);
QList<Info> available();

QString saved();
void save(const QString &name);

// The requested style if it is available, otherwise Fusion
QString choose(const QString &requested);

// Sets the style and the colours of Material and Universal before the QML
// engine is created
void apply(const QString &name);

} // namespace UiStyle
