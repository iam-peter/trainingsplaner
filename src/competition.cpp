#include "competition.h"

#include "database.h"
#include "model.h"

#include <QMap>
#include <QSqlQuery>
#include <QVariant>

#include <algorithm>

namespace {

int best(const int attempts[3])
{
    int b = 0;
    for (int i = 0; i < 3; ++i)
        b = qMax(b, attempts[i]); // invalid ones are negative
    return b;
}

QVariant intOrNull(int v)
{
    return v == 0 ? QVariant() : QVariant(v);
}

QList<Competition> read(QSqlQuery &q)
{
    QList<Competition> list;
    while (q.next()) {
        Competition c;
        c.athleteId = q.value(0).toString();
        c.date = QDate::fromString(q.value(1).toString(), Qt::ISODate);
        c.time = Times::parse(q.value(2).toString());
        c.type = q.value(3).toInt();
        c.name = q.value(4).toString();
        c.place = q.value(5).toString();
        c.bodyWeight = q.value(6).toDouble();
        for (int i = 0; i < 3; ++i) {
            c.snatch[i] = q.value(7 + i).toInt();
            c.cleanJerk[i] = q.value(10 + i).toInt();
        }
        c.note = q.value(13).toString();
        list.append(c);
    }
    return list;
}

const QString kColumns = QStringLiteral(
    "spid, datum, zeit, wkart, wk, ort, gew, rei1, rei2, rei3, sto1, sto2, sto3, bem");

} // namespace

int Competition::bestSnatch() const
{
    return best(snatch);
}

int Competition::bestCleanJerk() const
{
    return best(cleanJerk);
}

int Competition::total() const
{
    const int s = bestSnatch(), c = bestCleanJerk();
    return s > 0 && c > 0 ? s + c : 0;
}

namespace Competitions {

const QStringList &typeNames()
{
    static const QStringList names = {
        QStringLiteral("Nationales Turnier"), QStringLiteral("Deutsche Meisterschaft"),
        QStringLiteral("Internationales Turnier"), QStringLiteral("Bundesliga"),
        QStringLiteral("Europameisterschaft"), QStringLiteral("Weltmeisterschaft"),
        QStringLiteral("Olympische Spiele")};
    return names;
}

const QStringList &typeShortNames()
{
    static const QStringList names = {QStringLiteral("NT"), QStringLiteral("DM"), QStringLiteral("IT"),
                                      QStringLiteral("BL"), QStringLiteral("EM"), QStringLiteral("WM"),
                                      QStringLiteral("OS")};
    return names;
}

QList<Competition> forAthlete(const QString &athleteId)
{
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT %1 FROM wk WHERE spid = ? ORDER BY datum DESC, zeit DESC").arg(kColumns));
    q.addBindValue(athleteId);
    if (!q.exec())
        return {};
    return read(q);
}

QList<Competition> between(const QString &athleteId, const QDate &from, const QDate &to)
{
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT %1 FROM wk WHERE spid = ? AND datum BETWEEN ? AND ? ORDER BY datum, zeit")
                  .arg(kColumns));
    q.addBindValue(athleteId);
    q.addBindValue(from.toString(Qt::ISODate));
    q.addBindValue(to.toString(Qt::ISODate));
    if (!q.exec())
        return {};
    return read(q);
}

bool save(const Competition &c)
{
    if (c.athleteId.isEmpty() || !c.date.isValid())
        return false;
    QSqlQuery q;
    q.prepare(QStringLiteral("INSERT OR REPLACE INTO wk (%1, zk, user, korrektur)"
                             " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
                  .arg(kColumns));
    q.addBindValue(c.athleteId);
    q.addBindValue(c.date.toString(Qt::ISODate));
    q.addBindValue(Times::stored(c.time));
    q.addBindValue(c.type);
    q.addBindValue(c.name);
    q.addBindValue(c.place);
    q.addBindValue(c.bodyWeight > 0 ? QVariant(c.bodyWeight) : QVariant());
    for (int i = 0; i < 3; ++i)
        q.addBindValue(intOrNull(c.snatch[i]));
    for (int i = 0; i < 3; ++i)
        q.addBindValue(intOrNull(c.cleanJerk[i]));
    q.addBindValue(c.note);
    q.addBindValue(c.total());
    q.addBindValue(QStringLiteral("local"));
    q.addBindValue(Database::now());
    return q.exec();
}

bool remove(const QString &athleteId, const QDate &date, const QTime &time)
{
    return Database::deleteRows(QStringLiteral("wk"), QStringLiteral("spid = ? AND datum = ? AND zeit = ?"),
                                {athleteId, date.toString(Qt::ISODate), Times::stored(time)}, Database::now());
}

bool inWeek(const QString &athleteId, const QDate &monday)
{
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT 1 FROM wk WHERE spid = ? AND datum BETWEEN ? AND ? LIMIT 1"));
    q.addBindValue(athleteId);
    q.addBindValue(monday.toString(Qt::ISODate));
    q.addBindValue(monday.addDays(6).toString(Qt::ISODate));
    return q.exec() && q.next();
}

QList<Point> bestResults(const QList<Competition> &list, int period)
{
    QList<Competition> sorted = list;
    std::sort(sorted.begin(), sorted.end(), [](const Competition &a, const Competition &b) {
        return a.date < b.date;
    });
    QList<Point> points;
    QMap<QString, int> index; // period key -> position in points
    for (const Competition &c : sorted) {
        if (c.total() <= 0 && c.bestSnatch() <= 0 && c.bestCleanJerk() <= 0)
            continue;
        QString key, label;
        if (period == 1) {
            const int half = c.date.month() <= 6 ? 1 : 2;
            key = QStringLiteral("%1-%2").arg(c.date.year()).arg(half);
            label = QStringLiteral("%1/%2").arg(half).arg(c.date.year());
        } else if (period == 2) {
            key = label = QString::number(c.date.year());
        } else {
            key = c.date.toString(Qt::ISODate) + Times::stored(c.time);
            label = c.date.toString(QStringLiteral("dd.MM.yy"));
        }
        Point p{label, c.date, c.total(), c.bestSnatch(), c.bestCleanJerk()};
        if (!index.contains(key)) {
            index.insert(key, int(points.size()));
            points.append(p);
        } else {
            Point &b = points[index.value(key)];
            b.total = qMax(b.total, p.total);
            b.snatch = qMax(b.snatch, p.snatch);
            b.cleanJerk = qMax(b.cleanJerk, p.cleanJerk);
        }
    }
    return points;
}

int norm(int sex, int age, double bodyWeight)
{
    if (bodyWeight <= 0 || age <= 0)
        return 0;
    // The IAT table starts at age class 14 and ends with the oldest class
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT akl FROM normen WHERE sex = ? ORDER BY akl"));
    q.addBindValue(sex);
    if (!q.exec())
        return 0;
    QList<int> classes;
    while (q.next()) {
        if (!classes.contains(q.value(0).toInt()))
            classes.append(q.value(0).toInt());
    }
    if (classes.isEmpty())
        return 0;
    int akl = classes.first();
    for (int c : std::as_const(classes)) {
        if (c <= age)
            akl = c;
    }
    // Weight class: the lightest class the body weight fits in; "+" classes last
    QSqlQuery w;
    w.prepare(QStringLiteral("SELECT gkl, gklbez, zk FROM normen WHERE sex = ? AND akl = ? ORDER BY gkl"));
    w.addBindValue(sex);
    w.addBindValue(akl);
    if (!w.exec())
        return 0;
    int heaviest = 0;
    while (w.next()) {
        const int limit = w.value(0).toInt();
        const bool plus = w.value(1).toString().startsWith(QLatin1Char('+'));
        heaviest = w.value(2).toInt();
        if (!plus && bodyWeight <= limit)
            return w.value(2).toInt();
    }
    return heaviest;
}

} // namespace Competitions
