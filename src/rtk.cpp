#include "rtk.h"

#include "planning.h"

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSqlDatabase>

namespace Rtk {

namespace {

const QJsonArray &data()
{
    static const QJsonArray templates = [] {
        QFile f(QStringLiteral(":/rtk-ro.json"));
        if (!f.open(QIODevice::ReadOnly))
            return QJsonArray();
        return QJsonDocument::fromJson(f.readAll()).object().value(QStringLiteral("templates")).toArray();
    }();
    return templates;
}

QJsonObject object(const QString &key)
{
    for (const QJsonValue &v : data()) {
        if (v.toObject().value(QStringLiteral("key")).toString() == key)
            return v.toObject();
    }
    return {};
}

} // namespace

QList<Template> templates()
{
    QList<Template> list;
    for (const QJsonValue &v : data()) {
        const QJsonObject o = v.toObject();
        Template t;
        t.key = o.value(QStringLiteral("key")).toString();
        t.weeks = o.value(QStringLiteral("weeks")).toInt();
        t.buildUp = o.value(QStringLiteral("buildUp")).toInt();
        t.peak = o.value(QStringLiteral("peak")).toInt();
        t.title = QStringLiteral("RTK %1 (%2 Wochen)").arg(t.key).arg(t.weeks);
        list.append(t);
    }
    return list;
}

Template find(const QString &key)
{
    for (const Template &t : templates()) {
        if (t.key == key)
            return t;
    }
    return {};
}

bool fillRo(const QString &mazId, const QString &key)
{
    const Maz m = Planning::maz(mazId);
    const QJsonObject t = object(key);
    if (!m.from.isValid() || t.isEmpty())
        return false;
    const QString owner = Planning::roOwner(mazId);
    const QJsonArray rows = t.value(QStringLiteral("rows")).toArray();
    const int weeks = qMin(int(rows.size()), m.weeks());

    QSqlDatabase db = QSqlDatabase::database();
    db.transaction();
    bool ok = true;
    for (int i = 0; i < weeks; ++i) {
        const QJsonObject row = rows[i].toObject();
        const QDate monday = m.from.addDays(7 * i);

        WeekMeta meta;
        meta.monday = monday;
        meta.load = qMax(0, Planning::loadFromText(row.value(QStringLiteral("load")).toString()));
        meta.position = row.value(QStringLiteral("position")).toString();
        ok = ok && Planning::setMeta(owner, meta);

        // WH per complex
        const QJsonObject complexes = row.value(QStringLiteral("complexes")).toObject();
        for (auto it = complexes.begin(); it != complexes.end(); ++it) {
            WeekTarget group;
            group.monday = monday;
            group.exercise = -it.key().toInt();
            group.wh = it.value().toInt();
            ok = ok && Planning::setTarget(owner, group);
        }
        // MHG and BW in percent, reps and sets at BW, per exercise
        const QJsonObject exercises = row.value(QStringLiteral("exercises")).toObject();
        for (auto it = exercises.begin(); it != exercises.end(); ++it) {
            const QJsonArray v = it.value().toArray();
            WeekTarget e;
            e.monday = monday;
            e.exercise = it.key().toInt();
            e.mhg = v.at(0).toInt();
            e.bw = v.at(1).toInt();
            e.bwReps = v.at(2).toInt();
            e.bwSets = v.at(3).toInt();
            ok = ok && Planning::setTarget(owner, e);
        }
    }
    if (!ok) {
        db.rollback();
        return false;
    }
    return db.commit();
}

IntensityBand intensityBand(int exercise)
{
    switch (exercise) {
    case 13: case 14: case 22: case 24:
        return {QStringLiteral("Schnellkraft"), 55, 100};
    case 15: case 16: case 17: case 18: case 19: case 20: case 21:
        return {QStringLiteral("Maximalkraft"), 65, 110};
    default:
        return {};
    }
}

} // namespace Rtk
