#include "settings.h"

#include "database.h"
#include "model.h"

#include <QSettings>

namespace Settings {

namespace {

constexpr int kVersion = 2;

// Text read back as a time or date-time, or removed if unreadable
template<typename T, typename Parse>
void retype(QSettings &s, const QString &key, Parse parse)
{
    const QVariant v = s.value(key);
    if (v.typeId() != QMetaType::QString)
        return;
    const T value = parse(v.toString());
    if (value.isValid())
        s.setValue(key, value);
    else
        s.remove(key);
}

} // namespace

void migrate(QSettings &s)
{
    const QString versionKey = QStringLiteral("settings/version");
    if (s.value(versionKey, 1).toInt() >= kVersion)
        return;
    for (int n = 1; n <= 3; ++n) {
        for (const char *which : {"from", "to"})
            retype<QTime>(s, QStringLiteral("times/%1/%2").arg(n).arg(QLatin1String(which)), Times::parse);
    }
    retype<QDateTime>(s, QStringLiteral("export/last"), Database::stampTime);
    s.setValue(versionKey, kVersion);
}

} // namespace Settings
