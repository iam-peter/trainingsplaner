#pragma once

#include <QByteArray>
#include <QString>
#include <QUrl>

// What the update check needs from GitHub's "latest release" answer.
namespace Update {

enum class Platform { Windows, MacOS, Linux };

Platform currentPlatform();

// The download for a platform among a release's files
QString assetName(Platform platform);

// Compares versions such as "0.2.0", "v0.10.1" or "1.0.0-rc.1": -1, 0 or 1.
// Numbers compare as numbers; a pre-release suffix sorts before the
// release itself.
int compareVersions(const QString &a, const QString &b);

struct Release
{
    QString version; // without the "v"
    QString notes;   // Markdown
    QUrl page;       // the release on GitHub
    QUrl asset;      // the platform's download, empty if the release has none
    qint64 size = 0;
    QByteArray sha256; // from GitHub's digest, empty if not given

    bool isValid() const { return !version.isEmpty(); }
};

// Reads GitHub's JSON for one release; invalid on anything unexpected.
Release parseRelease(const QByteArray &json, Platform platform);

} // namespace Update
