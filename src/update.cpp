#include "update.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QStringList>

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

int compareVersions(const QString &a, const QString &b)
{
    static const QRegularExpression format(QStringLiteral("^v?(\\d+(?:\\.\\d+)*)(?:[-+.]?(.*))?$"));
    const QRegularExpressionMatch ma = format.match(a.trimmed());
    const QRegularExpressionMatch mb = format.match(b.trimmed());
    if (!ma.hasMatch() || !mb.hasMatch())
        return QString::compare(a, b) < 0 ? -1 : (a == b ? 0 : 1);

    const QStringList na = ma.captured(1).split(QLatin1Char('.'));
    const QStringList nb = mb.captured(1).split(QLatin1Char('.'));
    for (qsizetype i = 0; i < qMax(na.size(), nb.size()); ++i) {
        const qlonglong x = na.value(i, QStringLiteral("0")).toLongLong();
        const qlonglong y = nb.value(i, QStringLiteral("0")).toLongLong();
        if (x != y)
            return x < y ? -1 : 1;
    }
    // 1.0.0-rc.1 < 1.0.0; two pre-releases compare as text
    const QString sa = ma.captured(2), sb = mb.captured(2);
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
