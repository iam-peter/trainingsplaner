#include "update.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStringList>
#include <QVersionNumber>

namespace Update {

Platform currentPlatform()
{
#if defined(Q_OS_WIN)
    return Platform::Windows;
#elif defined(Q_OS_MACOS)
    return Platform::MacOS;
#else
    return Platform::Linux;
#endif
}

QString assetName(Platform platform)
{
    switch (platform) {
    case Platform::Windows:
        return QStringLiteral("trainingsplaner-windows-x64-setup.exe");
    case Platform::MacOS:
        return QStringLiteral("trainingsplaner-macos.dmg");
    case Platform::Linux:
        break;
    }
    return QStringLiteral("trainingsplaner-linux-x64.AppImage");
}

namespace {

// "v1.0.0-rc.1": the numbers 1.0.0 (trailing zeros dropped, so 0.2 equals
// 0.2.0) and the suffix "rc.1"
QVersionNumber splitVersion(const QString &text, QString *suffix)
{
    QString s = text.trimmed();
    if (s.startsWith(QLatin1Char('v')))
        s.remove(0, 1);
    qsizetype end = 0;
    const QVersionNumber v = QVersionNumber::fromString(s, &end);
    *suffix = s.mid(end);
    if (!suffix->isEmpty() && QStringLiteral("-+.").contains(suffix->front()))
        suffix->remove(0, 1);
    return v.normalized();
}

} // namespace

int compareVersions(const QString &a, const QString &b)
{
    QString sa, sb;
    const QVersionNumber va = splitVersion(a, &sa);
    const QVersionNumber vb = splitVersion(b, &sb);
    if (va.isNull() || vb.isNull())
        return QString::compare(a, b) < 0 ? -1 : (a == b ? 0 : 1);
    if (const int c = QVersionNumber::compare(va, vb))
        return c < 0 ? -1 : 1;
    // 1.0.0-rc.1 < 1.0.0; two pre-releases compare as text
    if (sa == sb)
        return 0;
    if (sa.isEmpty())
        return 1;
    if (sb.isEmpty())
        return -1;
    return sa < sb ? -1 : 1;
}

Release parseRelease(const QByteArray &json, Platform platform)
{
    Release r;
    const QJsonObject o = QJsonDocument::fromJson(json).object();
    if (o.value(QStringLiteral("draft")).toBool() || o.value(QStringLiteral("prerelease")).toBool())
        return r;
    QString tag = o.value(QStringLiteral("tag_name")).toString();
    if (tag.startsWith(QLatin1Char('v')))
        tag.remove(0, 1);
    if (tag.isEmpty() || !tag.front().isDigit())
        return r;
    r.version = tag;
    r.notes = o.value(QStringLiteral("body")).toString();
    r.page = QUrl(o.value(QStringLiteral("html_url")).toString());

    const QString wanted = assetName(platform);
    for (const QJsonValue &v : o.value(QStringLiteral("assets")).toArray()) {
        const QJsonObject asset = v.toObject();
        if (asset.value(QStringLiteral("name")).toString() != wanted)
            continue;
        r.asset = QUrl(asset.value(QStringLiteral("browser_download_url")).toString());
        r.size = asset.value(QStringLiteral("size")).toInteger();
        const QString digest = asset.value(QStringLiteral("digest")).toString();
        if (digest.startsWith(QLatin1String("sha256:")))
            r.sha256 = QByteArray::fromHex(digest.mid(7).toLatin1());
    }
    return r;
}

} // namespace Update
