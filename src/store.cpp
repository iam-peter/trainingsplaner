#include "store.h"

#include "bakexport.h"
#include "bakimport.h"
#include "competition.h"
#include "colorscheme.h"
#include "database.h"
#include "demo.h"
#include "exerciseweek.h"
#include "weekreport.h"

#include <QCoreApplication>
#include <QDateTime>
#include <QDesktopServices>
#include <QDir>
#include <QFileInfo>
#include <QPageLayout>
#include <QPainter>
#include <QPrintDialog>
#include <QPrinter>
#include <QSettings>
#include <QStandardPaths>

#include <cmath>

namespace {

Variant toVariant(const QString &v)
{
    return v == QLatin1String("I") ? Variant::Actual : Variant::Plan;
}

QDate toDate(const QString &iso)
{
    return QDate::fromString(iso, Qt::ISODate);
}

QVariantMap statsMap(const Stats &s)
{
    return {
        {QStringLiteral("wh"), s.wh},
        {QStringLiteral("mhg"), s.mhg},
        {QStringLiteral("bw"), s.bw},
        {QStringLiteral("repsSets"), s.bwRepsSets()},
        {QStringLiteral("tonnage"), s.tonnage},
        {QStringLiteral("empty"), s.isEmpty()},
    };
}

QVariantList stepsToList(const QList<Step> &steps)
{
    QVariantList list;
    for (const Step &s : steps) {
        list.append(QVariantMap{{QStringLiteral("kg"), s.kg},
                                {QStringLiteral("reps"), s.reps},
                                {QStringLiteral("sets"), s.sets},
                                {QStringLiteral("failed"), s.failed}});
    }
    return list;
}

QList<Step> stepsFromList(const QVariantList &list)
{
    QList<Step> steps;
    for (const QVariant &v : list) {
        const QVariantMap m = v.toMap();
        Step s;
        s.kg = m.value(QStringLiteral("kg")).toInt();
        s.reps = m.value(QStringLiteral("reps")).toInt();
        s.sets = m.value(QStringLiteral("sets")).toInt();
        s.failed = m.value(QStringLiteral("failed")).toInt();
        // A step needs a weight and a number of reps; one set is the default.
        if (s.kg <= 0 || s.reps <= 0)
            continue;
        if (s.sets <= 0)
            s.sets = 1;
        steps.append(s);
    }
    return steps;
}

QVariantMap entryToMap(const Entry &e)
{
    const Stats st = e.stats();
    QString line;
    switch (e.kind) {
    case Entry::Weights:
        line = st.isEmpty() ? QString()
                            : QStringLiteral("%1  %2  %3  %4").arg(st.wh).arg(st.mhg).arg(st.bw).arg(st.bwRepsSets());
        break;
    case Entry::ExerciseText:
        line = e.text;
        if (e.totalReps > 0)
            line += QStringLiteral("  (%1)").arg(e.totalReps);
        break;
    case Entry::FreeText:
        line = e.text;
        break;
    }
    return {
        {QStringLiteral("kind"), int(e.kind)},
        {QStringLiteral("exercise"), e.exercise},
        {QStringLiteral("name"), Catalog::name(e.exercise)},
        {QStringLiteral("steps"), stepsToList(e.steps)},
        {QStringLiteral("text"), e.text},
        {QStringLiteral("totalReps"), e.totalReps},
        {QStringLiteral("combination"), e.combination},
        {QStringLiteral("stats"), statsMap(st)},
        {QStringLiteral("line"), line},
    };
}

Entry entryFromMap(const QVariantMap &m)
{
    Entry e;
    e.kind = Entry::Kind(qBound(0, m.value(QStringLiteral("kind")).toInt(), 2));
    e.exercise = m.value(QStringLiteral("exercise")).toInt();
    e.steps = stepsFromList(m.value(QStringLiteral("steps")).toList());
    e.text = m.value(QStringLiteral("text")).toString().trimmed();
    e.text.remove(QLatin1Char('\n'));
    e.totalReps = m.value(QStringLiteral("totalReps")).toInt();
    e.combination = m.value(QStringLiteral("combination")).toInt();
    if (e.kind == Entry::FreeText)
        e.exercise = 0;
    if (e.kind == Entry::ExerciseText)
        e.text.remove(QLatin1Char(';'));
    return e;
}

bool entryIsBlank(const Entry &e)
{
    switch (e.kind) {
    case Entry::Weights:
        return e.exercise <= 0;
    case Entry::ExerciseText:
        return e.exercise <= 0 && e.text.isEmpty();
    case Entry::FreeText:
        return e.text.isEmpty();
    }
    return true;
}

QString sessionTitle(int day, int number)
{
    return QStringLiteral("%1 %2. TE").arg(Weeks::dayName(day)).arg(number);
}

QVariantMap sessionToMap(const Session &s, bool exists)
{
    QVariantList entries;
    for (const Entry &e : s.entries)
        entries.append(entryToMap(e));
    return {
        {QStringLiteral("day"), s.day},
        {QStringLiteral("number"), s.number},
        {QStringLiteral("from"), Times::text(s.from)},
        {QStringLiteral("to"), Times::text(s.to)},
        {QStringLiteral("note"), s.note},
        {QStringLiteral("entries"), entries},
        {QStringLiteral("exists"), exists},
        {QStringLiteral("title"), sessionTitle(s.day, s.number)},
    };
}

Session sessionFromMap(const QVariantMap &m)
{
    Session s;
    s.day = qBound(1, m.value(QStringLiteral("day")).toInt(), 7);
    s.number = qBound(1, m.value(QStringLiteral("number")).toInt(), 3);
    s.from = Times::parse(m.value(QStringLiteral("from")).toString());
    s.to = Times::parse(m.value(QStringLiteral("to")).toString());
    s.note = m.value(QStringLiteral("note")).toString();
    for (const QVariant &v : m.value(QStringLiteral("entries")).toList()) {
        const Entry e = entryFromMap(v.toMap());
        if (!entryIsBlank(e))
            s.entries.append(e);
    }
    return s;
}

// The time of a record keyed by date and time, from QML: empty for none,
// which is stored as midnight; invalid for unreadable text
QTime keyTime(const QString &text)
{
    return text.trimmed().isEmpty() ? QTime(0, 0) : Times::parse(text);
}

QSettings settings()
{
    return QSettings();
}

} // namespace

Store::Store(QObject *parent) : QObject(parent) {}

void Store::bump()
{
    ++m_dataVersion;
    emit dataChanged();
}

namespace {

const QStringList kAttributes = {
    QStringLiteral("Kader"), QStringLiteral("Verein"), QStringLiteral("BSP"),
    QStringLiteral("Bundeswehr"), QStringLiteral("Heimtrainer"), QStringLiteral("Landestrainer"),
    QStringLiteral("BSP-Trainer"), QStringLiteral("Bundestrainer")};

int ageOn(const QDate &born, const QDate &day)
{
    if (!born.isValid())
        return -1;
    int age = day.year() - born.year();
    if (QDate(day.year(), born.month(), qMin(born.day(), QDate(day.year(), born.month(), 1).daysInMonth())) > day)
        --age;
    return age;
}

} // namespace

QVariantList Store::athletes() const
{
    const QDate today = QDate::currentDate();
    QMap<QString, QList<Database::InfoRecord>> info;
    for (const Database::InfoRecord &r : Database::infoRecords(kAttributes))
        info[r.athleteId + QLatin1Char('\x1f') + r.art].append(r);

    QVariantList list;
    for (const Athlete &a : Database::athletes()) {
        QVariantMap attributes;
        for (const QString &art : kAttributes) {
            const Database::InfoRecord *r = Database::infoAt(info.value(a.id + QLatin1Char('\x1f') + art), today);
            attributes.insert(art, r ? r->text : QString());
        }
        const int age = ageOn(a.born, today);
        list.append(QVariantMap{
            {QStringLiteral("id"), a.id},
            {QStringLiteral("lastName"), a.lastName},
            {QStringLiteral("firstName"), a.firstName},
            {QStringLiteral("displayName"), a.displayName()},
            {QStringLiteral("sex"), int(a.sex)},
            {QStringLiteral("born"), Dates::text(a.born)},
            {QStringLiteral("age"), age},
            {QStringLiteral("address"), a.address},
            {QStringLiteral("phone"), a.phone},
            {QStringLiteral("attributes"), attributes},
        });
    }
    return list;
}

QVariantList Store::selectableAthletes() const
{
    const QString kader = filterKader();
    const int sex = filterSex();
    QVariantList list;
    for (const QVariant &v : athletes()) {
        const QVariantMap a = v.toMap();
        if (sex >= 0 && a.value(QStringLiteral("sex")).toInt() != sex)
            continue;
        if (!kader.isEmpty()
            && a.value(QStringLiteral("attributes")).toMap().value(QStringLiteral("Kader")).toString() != kader)
            continue;
        list.append(a);
    }
    return list;
}

QStringList Store::attributeNames() const
{
    return kAttributes;
}

QString Store::filterKader() const
{
    return QSettings().value(QStringLiteral("filter/kader")).toString();
}

void Store::setFilterKader(const QString &v)
{
    QSettings().setValue(QStringLiteral("filter/kader"), v);
    emit athletesChanged();
}

int Store::filterSex() const
{
    return QSettings().value(QStringLiteral("filter/sex"), -1).toInt();
}

void Store::setFilterSex(int v)
{
    QSettings().setValue(QStringLiteral("filter/sex"), qBound(-1, v, 1));
    emit athletesChanged();
}

namespace {

// The categories the old program came with
QVariantList defaultInfoCategories()
{
    auto c = [](const char *name, const char *code, const char *unit, int decimals, const char *agg) {
        return QVariantMap{{QStringLiteral("name"), QString::fromUtf8(name)},
                           {QStringLiteral("code"), QString::fromLatin1(code)},
                           {QStringLiteral("unit"), QString::fromUtf8(unit)},
                           {QStringLiteral("decimals"), decimals},
                           {QStringLiteral("aggregate"), QString::fromLatin1(agg)}};
    };
    return {c("Körpergewicht", "KG", "kg", 1, "MAX"), c("Körperhöhe", "KH", "cm", 0, "MAX"),
            c("Körperfett", "KF", "%", 1, "MIN"), c("Creatin", "CRE", "g", 0, "SUM"),
            c("Glutaplast", "GPL", "g", 0, "SUM"), c("Protiplast", "PPL", "g", 0, "SUM"),
            c("Regenaplast", "RPL", "g", 0, "SUM"), c("Energoplast", "EPL", "g", 0, "SUM"),
            c("Protipur", "PP", "g", 0, "SUM"), c("Omega 3", "OM3", "g", 0, "SUM"),
            c("CH alpha", "CHA", "g", 0, "SUM")};
}

QString formatNumber(double v, int decimals)
{
    return QLocale(QLocale::German).toString(v, 'f', qBound(0, decimals, 3));
}

} // namespace

QVariantList Store::infoCategories() const
{
    const QVariant v = QSettings().value(QStringLiteral("info/categories"));
    const QVariantList list = v.toList();
    return list.isEmpty() ? defaultInfoCategories() : list;
}

void Store::setInfoCategories(const QVariantList &v)
{
    QVariantList clean;
    QStringList codes;
    for (const QVariant &item : v) {
        QVariantMap m = item.toMap();
        const QString code = m.value(QStringLiteral("code")).toString().trimmed().toUpper();
        const QString name = m.value(QStringLiteral("name")).toString().trimmed();
        // Codes must not collide with attribute names or each other
        if (code.isEmpty() || name.isEmpty() || codes.contains(code) || kAttributes.contains(code, Qt::CaseInsensitive))
            continue;
        codes.append(code);
        m.insert(QStringLiteral("code"), code);
        m.insert(QStringLiteral("name"), name);
        const QString agg = m.value(QStringLiteral("aggregate")).toString().toUpper();
        m.insert(QStringLiteral("aggregate"), agg == QLatin1String("MIN") || agg == QLatin1String("SUM") ? agg : QStringLiteral("MAX"));
        m.insert(QStringLiteral("decimals"), qBound(0, m.value(QStringLiteral("decimals")).toInt(), 3));
        clean.append(m);
    }
    QSettings().setValue(QStringLiteral("info/categories"), clean);
    emit settingsChanged();
}

QVariantList Store::dayInfo(const QString &athleteId, const QString &monday) const
{
    const QVariantList cats = infoCategories();
    QMap<QString, QVariantMap> byCode;
    QStringList codes;
    for (const QVariant &c : cats) {
        const QVariantMap m = c.toMap();
        byCode.insert(m.value(QStringLiteral("code")).toString(), m);
        codes.append(m.value(QStringLiteral("code")).toString());
    }
    const QDate from = QDate::fromString(monday, Qt::ISODate);
    QVariantList list;
    for (const Database::InfoRecord &r : Database::infoRecordsBetween(athleteId, codes, from, from.addDays(6))) {
        const QVariantMap c = byCode.value(r.art);
        list.append(QVariantMap{
            {QStringLiteral("date"), r.from.toString(Qt::ISODate)},
            {QStringLiteral("dateText"), Weeks::dayName(r.from.dayOfWeek()) + r.from.toString(QStringLiteral(", dd.MM."))},
            {QStringLiteral("time"), Times::optional(r.time)},
            {QStringLiteral("code"), r.art},
            {QStringLiteral("name"), c.value(QStringLiteral("name"))},
            {QStringLiteral("unit"), c.value(QStringLiteral("unit"))},
            {QStringLiteral("value"), r.number},
            {QStringLiteral("valueText"), formatNumber(r.number, c.value(QStringLiteral("decimals")).toInt())},
        });
    }
    return list;
}

QString Store::saveWeekInfo(const QString &athleteId, const QString &monday,
                            const QVariantList &rows)
{
    const QDate from = QDate::fromString(monday, Qt::ISODate);
    const QDate to = from.addDays(6);
    QStringList codes;
    for (const QVariant &c : infoCategories())
        codes.append(c.toMap().value(QStringLiteral("code")).toString());
    QList<Database::InfoRecord> records;
    for (int i = 0; i < rows.size(); ++i) {
        const QVariantMap row = rows.at(i).toMap();
        const QString value = row.value(QStringLiteral("value")).toString().trimmed();
        if (value.isEmpty())
            continue;
        const QString line = QStringLiteral("Zeile %1: ").arg(i + 1);
        Database::InfoRecord r;
        bool ok = false;
        r.number = QLocale(QLocale::German).toDouble(value, &ok);
        if (!ok)
            r.number = value.toDouble(&ok);
        if (!ok)
            return line + QStringLiteral("Bitte eine Zahl eingeben.");
        r.hasNumber = true;
        r.from = QDate::fromString(row.value(QStringLiteral("date")).toString(), Qt::ISODate);
        if (!r.from.isValid() || r.from < from || r.from > to)
            return line + QStringLiteral("Bitte einen Tag der Woche wählen.");
        r.art = row.value(QStringLiteral("code")).toString();
        if (!codes.contains(r.art))
            return line + QStringLiteral("Bitte eine Kategorie wählen.");
        const QString time = row.value(QStringLiteral("time")).toString();
        r.time = keyTime(time);
        if (!r.time.isValid())
            return line + QStringLiteral("Zeit ungültig: ") + time.trimmed();
        for (const Database::InfoRecord &other : std::as_const(records)) {
            if (other.art == r.art && other.from == r.from && other.time == r.time)
                return line + QStringLiteral("Dieselbe Kategorie steht schon für diesen Tag und diese Zeit da.");
        }
        records.append(r);
    }
    if (!Database::replaceInfoRecordsBetween(athleteId, codes, from, to, records))
        return QStringLiteral("Speichern fehlgeschlagen: ") + Database::lastError();
    bump();
    return QString();
}

QString Store::weekInfoSummary(const QString &athleteId, const QString &monday) const
{
    const QVariantList entries = dayInfo(athleteId, monday);
    QStringList parts;
    for (const QVariant &c : infoCategories()) {
        const QVariantMap cat = c.toMap();
        const QString code = cat.value(QStringLiteral("code")).toString();
        const QString agg = cat.value(QStringLiteral("aggregate")).toString();
        bool any = false;
        double v = 0;
        for (const QVariant &e : entries) {
            const QVariantMap m = e.toMap();
            if (m.value(QStringLiteral("code")).toString() != code)
                continue;
            const double x = m.value(QStringLiteral("value")).toDouble();
            if (!any)
                v = x;
            else if (agg == QLatin1String("SUM"))
                v += x;
            else if (agg == QLatin1String("MIN"))
                v = qMin(v, x);
            else
                v = qMax(v, x);
            any = true;
        }
        if (any) {
            parts.append(QStringLiteral("%1 %2 %3")
                             .arg(cat.value(QStringLiteral("name")).toString(),
                                  formatNumber(v, cat.value(QStringLiteral("decimals")).toInt()),
                                  cat.value(QStringLiteral("unit")).toString())
                             .trimmed());
        }
    }
    return parts.join(QStringLiteral("  ·  "));
}

QStringList Store::attributeValues(const QString &art) const
{
    return Database::infoValues(art);
}

bool Store::setAthleteAttributes(const QString &athleteId, const QVariantMap &values)
{
    bool ok = true;
    for (auto it = values.cbegin(); it != values.cend(); ++it) {
        if (kAttributes.contains(it.key()))
            ok = Database::setAttribute(athleteId, it.key(), it.value().toString(), QDate::currentDate()) && ok;
    }
    emit athletesChanged();
    return ok;
}

QVariantList Store::attributeHistory(const QString &athleteId, const QString &art) const
{
    QVariantList list;
    for (const Database::InfoRecord &r : Database::infoRecords(athleteId, art)) {
        list.append(QVariantMap{
            {QStringLiteral("from"), Dates::text(r.from)},
            {QStringLiteral("to"), Dates::text(r.to)},
            {QStringLiteral("text"), r.text},
        });
    }
    return list;
}

QString Store::saveAttributeHistory(const QString &athleteId, const QString &art,
                                   const QVariantList &rows)
{
    QList<Database::InfoRecord> records;
    for (int i = 0; i < rows.size(); ++i) {
        const QVariantMap row = rows.at(i).toMap();
        const QString from = row.value(QStringLiteral("from")).toString().trimmed();
        const QString to = row.value(QStringLiteral("to")).toString().trimmed();
        Database::InfoRecord r;
        r.text = row.value(QStringLiteral("text")).toString().trimmed();
        if (from.isEmpty() && to.isEmpty() && r.text.isEmpty())
            continue;
        const QString line = QStringLiteral("Zeile %1: ").arg(i + 1);
        r.from = Dates::parse(from);
        r.to = Dates::parse(to);
        if (!r.from.isValid())
            return line + QStringLiteral("„von“ ist kein gültiges Datum.");
        if (!to.isEmpty() && !r.to.isValid())
            return line + QStringLiteral("„bis“ ist kein gültiges Datum.");
        if (r.to.isValid() && r.to < r.from)
            return line + QStringLiteral("„bis“ liegt vor „von“.");
        for (const Database::InfoRecord &other : std::as_const(records)) {
            if (other.from == r.from)
                return line + QStringLiteral("Ein anderer Eintrag beginnt am selben Tag.");
        }
        records.append(r);
    }
    if (!Database::replaceInfoRecords(athleteId, art, records))
        return QStringLiteral("Speichern fehlgeschlagen: ") + Database::lastError();
    emit athletesChanged();
    return QString();
}

QVariantList Store::catalog() const
{
    QVariantList list;
    for (const Exercise &e : Catalog::all()) {
        list.append(QVariantMap{
            {QStringLiteral("id"), e.id},
            {QStringLiteral("name"), e.name},
            {QStringLiteral("group"), e.group},
            {QStringLiteral("text"), e.input == Exercise::Text},
        });
    }
    return list;
}

QString Store::trainer() const
{
    return settings().value(QStringLiteral("report/trainer")).toString();
}

void Store::setTrainer(const QString &v)
{
    if (v == trainer())
        return;
    QSettings s;
    s.setValue(QStringLiteral("report/trainer"), v);
    emit settingsChanged();
}

QString Store::organisation() const
{
    return settings().value(QStringLiteral("report/organisation")).toString();
}

void Store::setOrganisation(const QString &v)
{
    if (v == organisation())
        return;
    QSettings s;
    s.setValue(QStringLiteral("report/organisation"), v);
    emit settingsChanged();
}

namespace {

const char *kPrintBool[] = {"weekNote", "weekNoteCentered", "figures", "sessionNoteCentered", "landscape"};
const char *kPrintInt[] = {"blankHeader", "blankPerSession", "blankAfterNote", "marginTop", "marginLeft",
                           "marginRight", "marginBottom"};
const char *kPrintReal[] = {"fontSmall", "fontNormal", "fontLarge"};
// The paper sizes offered, by the name stored and shown
const QList<std::pair<QString, QPageSize::PageSizeId>> kPapers = {
    {QStringLiteral("A4"), QPageSize::A4}, {QStringLiteral("A5"), QPageSize::A5}, {QStringLiteral("A3"), QPageSize::A3}};

WeekReport::Options readPrintOptions()
{
    QSettings s;
    s.beginGroup(QStringLiteral("print"));
    WeekReport::Options o;
    o.weekNote = s.value(QStringLiteral("weekNote"), o.weekNote).toBool();
    o.weekNoteCentered = s.value(QStringLiteral("weekNoteCentered"), o.weekNoteCentered).toBool();
    o.figures = s.value(QStringLiteral("figures"), o.figures).toBool();
    o.sessionNoteCentered = s.value(QStringLiteral("sessionNoteCentered"), o.sessionNoteCentered).toBool();
    o.landscape = s.value(QStringLiteral("landscape"), o.landscape).toBool();
    const QString paper = s.value(QStringLiteral("paper")).toString();
    for (const auto &[name, id] : kPapers) {
        if (name == paper)
            o.paper = id;
    }
    o.notation = s.value(QStringLiteral("notation")).toString() == QLatin1String("slash")
                     ? WeekReport::Options::Slash : WeekReport::Options::Fraction;
    o.blankHeader = qBound(0, s.value(QStringLiteral("blankHeader"), 0).toInt(), 20);
    o.blankPerSession = qBound(0, s.value(QStringLiteral("blankPerSession"), 0).toInt(), 20);
    o.blankAfterNote = qBound(0, s.value(QStringLiteral("blankAfterNote"), 0).toInt(), 40);
    o.fontSmall = qBound(5.0, s.value(QStringLiteral("fontSmall"), o.fontSmall).toDouble(), 24.0);
    o.fontNormal = qBound(6.0, s.value(QStringLiteral("fontNormal"), o.fontNormal).toDouble(), 28.0);
    o.fontLarge = qBound(6.0, s.value(QStringLiteral("fontLarge"), o.fontLarge).toDouble(), 36.0);
    o.marginTop = qBound(0, s.value(QStringLiteral("marginTop"), o.marginTop).toInt(), 80);
    o.marginLeft = qBound(0, s.value(QStringLiteral("marginLeft"), o.marginLeft).toInt(), 80);
    o.marginRight = qBound(0, s.value(QStringLiteral("marginRight"), o.marginRight).toInt(), 80);
    o.marginBottom = qBound(0, s.value(QStringLiteral("marginBottom"), o.marginBottom).toInt(), 80);
    o.logoPath = s.value(QStringLiteral("logoPath")).toString();
    const QColor c(s.value(QStringLiteral("sessionColor"), QStringLiteral("#ffffff")).toString());
    o.sessionColor = c.isValid() ? c : QColor(Qt::white);
    return o;
}

} // namespace

QVariantMap Store::printOptions() const
{
    const WeekReport::Options o = readPrintOptions();
    return {
        {QStringLiteral("weekNote"), o.weekNote},
        {QStringLiteral("weekNoteCentered"), o.weekNoteCentered},
        {QStringLiteral("figures"), o.figures},
        {QStringLiteral("sessionNoteCentered"), o.sessionNoteCentered},
        {QStringLiteral("landscape"), o.landscape},
        {QStringLiteral("paper"), std::find_if(kPapers.begin(), kPapers.end(), [&](const auto &p) {
                                      return p.second == o.paper;
                                  })->first},
        {QStringLiteral("notation"), o.notation == WeekReport::Options::Slash ? QStringLiteral("slash")
                                                                              : QStringLiteral("fraction")},
        {QStringLiteral("blankHeader"), o.blankHeader},
        {QStringLiteral("blankPerSession"), o.blankPerSession},
        {QStringLiteral("blankAfterNote"), o.blankAfterNote},
        {QStringLiteral("fontSmall"), o.fontSmall},
        {QStringLiteral("fontNormal"), o.fontNormal},
        {QStringLiteral("fontLarge"), o.fontLarge},
        {QStringLiteral("marginTop"), o.marginTop},
        {QStringLiteral("marginLeft"), o.marginLeft},
        {QStringLiteral("marginRight"), o.marginRight},
        {QStringLiteral("marginBottom"), o.marginBottom},
        {QStringLiteral("logoPath"), o.logoPath},
        {QStringLiteral("sessionColor"), o.sessionColor.name()},
    };
}

void Store::setPrintOptions(const QVariantMap &v)
{
    QSettings s;
    s.beginGroup(QStringLiteral("print"));
    for (const char *k : kPrintBool) {
        if (v.contains(QLatin1String(k)))
            s.setValue(QLatin1String(k), v.value(QLatin1String(k)).toBool());
    }
    for (const char *k : kPrintInt) {
        if (v.contains(QLatin1String(k)))
            s.setValue(QLatin1String(k), v.value(QLatin1String(k)).toInt());
    }
    for (const char *k : kPrintReal) {
        if (v.contains(QLatin1String(k)))
            s.setValue(QLatin1String(k), v.value(QLatin1String(k)).toDouble());
    }
    for (const char *k : {"notation", "logoPath", "sessionColor", "paper"}) {
        if (v.contains(QLatin1String(k)))
            s.setValue(QLatin1String(k), v.value(QLatin1String(k)).toString());
    }
    s.endGroup();
    emit settingsChanged();
}

namespace {

// The default start ("from") or end ("to") of the 1st to 3rd session of a
// day; invalid if none is set
QString timeKey(int number, const char *which)
{
    return QStringLiteral("times/%1/%2").arg(number).arg(QLatin1String(which));
}

QTime defaultTime(int number, const char *which)
{
    return QSettings().value(timeKey(number, which)).toTime();
}

void setDefaultTime(QSettings &s, int number, const char *which, const QTime &time)
{
    if (time.isValid())
        s.setValue(timeKey(number, which), time);
    else
        s.remove(timeKey(number, which));
}

} // namespace

QVariantList Store::sessionTimes() const
{
    QVariantList list;
    for (int n = 1; n <= 3; ++n) {
        list.append(QVariantMap{
            {QStringLiteral("from"), Times::text(defaultTime(n, "from"))},
            {QStringLiteral("to"), Times::text(defaultTime(n, "to"))},
        });
    }
    return list;
}

void Store::setSessionTimes(const QVariantList &v)
{
    QSettings s;
    for (int n = 1; n <= 3 && n <= v.size(); ++n) {
        const QVariantMap m = v.at(n - 1).toMap();
        setDefaultTime(s, n, "from", Times::parse(m.value(QStringLiteral("from")).toString()));
        setDefaultTime(s, n, "to", Times::parse(m.value(QStringLiteral("to")).toString()));
    }
    emit settingsChanged();
}

double Store::weightStep() const
{
    return QSettings().value(QStringLiteral("general/weightStep"), 2.5).toDouble() == 1.0 ? 1.0 : 2.5;
}

void Store::setWeightStep(double v)
{
    QSettings().setValue(QStringLiteral("general/weightStep"), v == 1.0 ? 1.0 : 2.5);
    emit settingsChanged();
}

int Store::stepWeight(int kg, int direction) const
{
    return Steps::nextWeight(kg, weightStep(), direction);
}

QString Store::databasePath() const
{
    return QDir::toNativeSeparators(Database::path());
}

QString Store::clipboardLabel() const
{
    if (!m_clip)
        return QString();
    const Athlete a = Database::athlete(m_clip->athleteId);
    return QStringLiteral("%1, Woche %2 (%3)")
        .arg(a.displayName(), Weeks::label(m_clip->monday),
             m_clip->variant == Variant::Plan ? QStringLiteral("Plan") : QStringLiteral("Ist"));
}

Week Store::loadWeek(const QString &athleteId, const QString &monday, const QString &variant) const
{
    return Database::loadWeek(athleteId, toDate(monday), toVariant(variant));
}

QVariantMap Store::week(const QString &athleteId, const QString &monday,
                        const QString &variant) const
{
    const Week w = loadWeek(athleteId, monday, variant);
    QVariantList sessions;
    for (const Session &s : w.sessions)
        sessions.append(sessionToMap(s, true));

    const WeekSummary sum = w.summary();
    QVariantList groups;
    for (const GroupSummary &g : sum.groups) {
        QVariantList lines;
        for (const ExerciseSummary &ex : g.exercises) {
            // Fixed widths so the columns line up in a monospace font.
            lines.append(QStringLiteral("%1 %2 %3 %4 %5")
                             .arg(ex.exercise, 2)
                             .arg(ex.stats.wh, 3)
                             .arg(ex.stats.mhg, 3)
                             .arg(ex.stats.bw, 3)
                             .arg(ex.stats.bwRepsSets(), 5));
        }
        groups.append(QVariantMap{
            {QStringLiteral("title"), g.stats.wh > 0 ? QStringLiteral("K%1: %2").arg(g.group).arg(g.stats.wh)
                                                     : QStringLiteral("K%1:").arg(g.group)},
            {QStringLiteral("lines"), lines},
        });
    }

    return {
        {QStringLiteral("monday"), monday},
        {QStringLiteral("label"), Weeks::label(w.monday)},
        {QStringLiteral("sessions"), sessions},
        {QStringLiteral("note"), w.note},
        {QStringLiteral("injured"), w.injured},
        {QStringLiteral("k17"), QStringLiteral("K1-7: ") + sum.groups1to7.summary()},
        {QStringLiteral("k15"), QStringLiteral("K1-5: ") + sum.groups1to5.summary()},
        {QStringLiteral("groups"), groups},
        {QStringLiteral("empty"), w.sessions.isEmpty()},
    };
}

QVariantMap Store::session(const QString &athleteId, const QString &monday,
                           const QString &variant, int day, int number) const
{
    const Week w = loadWeek(athleteId, monday, variant);
    if (const Session *s = w.session(day, number))
        return sessionToMap(*s, true);
    Session s;
    s.day = day;
    s.number = number;
    // The times of another session with the same number this week, else the
    // default times from the settings.
    for (const Session &other : w.sessions) {
        if (other.number == number && other.from.isValid()) {
            s.from = other.from;
            s.to = other.to;
            break;
        }
    }
    if (!s.from.isValid() && number >= 1 && number <= 3) {
        s.from = defaultTime(number, "from");
        s.to = defaultTime(number, "to");
    }
    return sessionToMap(s, false);
}

bool Store::saveSession(const QString &athleteId, const QString &monday, const QString &variant,
                        const QVariantMap &session)
{
    const Session s = sessionFromMap(session);
    // Nothing in it: no session, which the week would not show either. One
    // that was there goes, as with TE löschen.
    if (s.entries.isEmpty() && !s.from.isValid() && !s.to.isValid() && s.note.trimmed().isEmpty()) {
        if (!loadWeek(athleteId, monday, variant).session(s.day, s.number))
            return true;
        return removeSession(athleteId, monday, variant, s.day, s.number);
    }
    return changeWeek(sessionTitle(s.day, s.number) + QStringLiteral(" speichern"), athleteId, monday,
                      variant, [&] {
        return Database::saveSession(athleteId, toDate(monday), toVariant(variant), s);
    });
}

bool Store::removeSession(const QString &athleteId, const QString &monday,
                          const QString &variant, int day, int number)
{
    return changeWeek(sessionTitle(day, number) + QStringLiteral(" löschen"), athleteId, monday,
                      variant, [&] {
        return Database::removeSession(athleteId, toDate(monday), toVariant(variant), day, number);
    });
}

void Store::copySession(const QString &athleteId, const QString &monday, const QString &variant,
                        int day, int number)
{
    const Week w = loadWeek(athleteId, monday, variant);
    const Session *s = w.session(day, number);
    if (!s)
        return;
    m_sessionClip = *s;
    m_sessionClipLabel = QStringLiteral("%1, Woche %2 (%3)")
                             .arg(sessionTitle(day, number), Weeks::label(toDate(monday)),
                                  toVariant(variant) == Variant::Plan ? QStringLiteral("Plan") : QStringLiteral("Ist"));
    emit clipboardChanged();
}

bool Store::pasteSession(const QString &athleteId, const QString &monday, const QString &variant,
                         int day, int number)
{
    if (!m_sessionClip || day < 1 || day > 7 || number < 1 || number > 3)
        return false;
    Session s = *m_sessionClip;
    s.day = day;
    s.number = number;
    return changeWeek(sessionTitle(day, number) + QStringLiteral(" einfügen"), athleteId, monday,
                      variant, [&] {
        return Database::saveSession(athleteId, toDate(monday), toVariant(variant), s);
    });
}

bool Store::planToActual(const QString &athleteId, const QString &monday, int day, int number)
{
    const Week plan = loadWeek(athleteId, monday, QStringLiteral("P"));
    const Session *s = plan.session(day, number);
    if (!s)
        return false;
    const Session copy = *s;
    return changeWeek(sessionTitle(day, number) + QStringLiteral(": Ist = Plan"), athleteId, monday,
                      QStringLiteral("I"), [&] {
        return Database::saveSession(athleteId, toDate(monday), Variant::Actual, copy);
    });
}

namespace {

bool sameSessions(const QList<Session> &a, const QList<Session> &b)
{
    if (a.size() != b.size())
        return false;
    for (qsizetype i = 0; i < a.size(); ++i) {
        if (sessionToMap(a.at(i), true) != sessionToMap(b.at(i), true))
            return false;
    }
    return true;
}

constexpr qsizetype kUndoLimit = 100;

} // namespace

bool Store::changeWeek(const QString &label, const QString &athleteId, const QString &monday,
                       const QString &variant, const std::function<bool()> &op)
{
    WeekChange c;
    c.label = label;
    c.athleteId = athleteId;
    c.monday = toDate(monday);
    c.variant = toVariant(variant);
    c.before = Database::loadWeek(athleteId, c.monday, c.variant).sessions;
    const bool ok = op();
    c.after = Database::loadWeek(athleteId, c.monday, c.variant).sessions;
    if (!sameSessions(c.before, c.after)) {
        m_undo.append(c);
        if (m_undo.size() > kUndoLimit)
            m_undo.removeFirst();
        m_redo.clear();
        emit undoChanged();
    }
    bump();
    return ok;
}

QVariantMap Store::restore(const WeekChange &c, bool back)
{
    Database::replaceSessions(c.athleteId, c.monday, c.variant, back ? c.before : c.after);
    emit undoChanged();
    bump();
    return {
        {QStringLiteral("athleteId"), c.athleteId},
        {QStringLiteral("monday"), c.monday.toString(Qt::ISODate)},
        {QStringLiteral("variant"), c.variant == Variant::Plan ? QStringLiteral("P") : QStringLiteral("I")},
        {QStringLiteral("label"), c.label},
    };
}

QVariantMap Store::undo()
{
    if (m_undo.isEmpty())
        return {};
    const WeekChange c = m_undo.takeLast();
    m_redo.append(c);
    return restore(c, true);
}

QVariantMap Store::redo()
{
    if (m_redo.isEmpty())
        return {};
    const WeekChange c = m_redo.takeLast();
    m_undo.append(c);
    return restore(c, false);
}

QString Store::colorScheme() const
{
    return ColorScheme::saved();
}

bool Store::classicColors() const
{
    return ColorScheme::active() == QLatin1String("classic");
}

void Store::setColorScheme(const QString &scheme)
{
    if (scheme == colorScheme())
        return;
    ColorScheme::save(scheme);
    ColorScheme::apply(ColorScheme::saved());
    emit settingsChanged();
}

bool Store::firstStart() const
{
    return !QSettings().value(QStringLiteral("start/welcomed")).toBool() && Database::athletes().isEmpty();
}

void Store::finishFirstStart()
{
    QSettings().setValue(QStringLiteral("start/welcomed"), true);
    emit settingsChanged();
}

bool Store::hasDemoData() const
{
    const QStringList ids = QSettings().value(QStringLiteral("demo/athletes")).toStringList();
    for (const Athlete &a : Database::athletes()) {
        if (ids.contains(a.id))
            return true;
    }
    return false;
}

QString Store::createDemoData()
{
    const QStringList ids = Demo::create(QDate::currentDate());
    QSettings s;
    s.setValue(QStringLiteral("demo/athletes"),
               s.value(QStringLiteral("demo/athletes")).toStringList() + ids);
    emit athletesChanged();
    bump();
    return ids.value(0);
}

void Store::removeDemoData()
{
    QSettings s;
    for (const QString &id : s.value(QStringLiteral("demo/athletes")).toStringList())
        removeAthlete(id);
    s.remove(QStringLiteral("demo/athletes"));
    emit athletesChanged();
}

QString Store::undoLabel() const
{
    return m_undo.isEmpty() ? QString() : m_undo.last().label;
}

QString Store::redoLabel() const
{
    return m_redo.isEmpty() ? QString() : m_redo.last().label;
}

// Forgets the changes of one athlete, or all changes
void Store::clearUndo(const QString &athleteId)
{
    const auto match = [&](const WeekChange &c) { return athleteId.isEmpty() || c.athleteId == athleteId; };
    const qsizetype n = m_undo.removeIf(match) + m_redo.removeIf(match);
    if (n > 0)
        emit undoChanged();
}

bool Store::saveWeekNote(const QString &athleteId, const QString &monday, const QString &variant,
                         const QString &note, bool injured)
{
    const Week w = loadWeek(athleteId, monday, variant);
    if (w.note == note && w.injured == injured)
        return true;
    return Database::saveWeekNote(athleteId, toDate(monday), toVariant(variant), note, injured);
}

void Store::copyWeek(const QString &athleteId, const QString &monday, const QString &variant)
{
    m_clip = Clip{athleteId, toDate(monday), toVariant(variant)};
    emit clipboardChanged();
}

int Store::pasteWeek(const QString &athleteId, const QString &monday, const QString &variant)
{
    if (!m_clip)
        return -1;
    int n = -1;
    changeWeek(QStringLiteral("Woche %1 einfügen").arg(Weeks::label(toDate(monday))), athleteId,
               monday, variant, [&] {
        n = Database::copyWeek(m_clip->athleteId, m_clip->monday, m_clip->variant, athleteId,
                               toDate(monday), toVariant(variant));
        return n >= 0;
    });
    return n;
}

QVariantMap Store::exerciseWeek(const QString &athleteId, const QString &monday,
                                const QString &variant, int exercise) const
{
    QVariantList rows;
    for (const ExerciseRow &r : ExerciseWeek::rows(loadWeek(athleteId, monday, variant), exercise)) {
        rows.append(QVariantMap{
            {QStringLiteral("origDay"), r.origDay},
            {QStringLiteral("origNumber"), r.origNumber},
            {QStringLiteral("origIndex"), r.origIndex},
            {QStringLiteral("day"), r.day},
            {QStringLiteral("number"), r.number},
            {QStringLiteral("steps"), stepsToList(r.steps)},
        });
    }
    return {
        {QStringLiteral("exercise"), exercise},
        {QStringLiteral("name"), Catalog::name(exercise)},
        {QStringLiteral("valid"), Catalog::isWeightExercise(exercise)},
        {QStringLiteral("rows"), rows},
    };
}

bool Store::saveExerciseWeek(const QString &athleteId, const QString &monday,
                             const QString &variant, int exercise, const QVariantList &rows)
{
    if (!Catalog::isWeightExercise(exercise))
        return false;
    QList<ExerciseRow> edited;
    for (const QVariant &v : rows) {
        const QVariantMap m = v.toMap();
        ExerciseRow r;
        r.origDay = m.value(QStringLiteral("origDay")).toInt();
        r.origNumber = m.value(QStringLiteral("origNumber")).toInt();
        r.origIndex = m.value(QStringLiteral("origIndex"), -1).toInt();
        r.day = qBound(1, m.value(QStringLiteral("day")).toInt(), 7);
        r.number = qBound(1, m.value(QStringLiteral("number")).toInt(), 3);
        r.steps = stepsFromList(m.value(QStringLiteral("steps")).toList());
        edited.append(r);
    }

    const QDate date = toDate(monday);
    const Variant v = toVariant(variant);
    return changeWeek(QStringLiteral("Übung %1 bearbeiten").arg(exercise), athleteId, monday, variant, [&] {
        Week w = Database::loadWeek(athleteId, date, v);
        bool ok = true;
        for (const auto &key : ExerciseWeek::apply(w, exercise, edited)) {
            const Session *s = w.session(key.first, key.second);
            if (!s)
                continue;
            // A session that lost its last line and has no note is gone.
            if (s->entries.isEmpty() && s->note.trimmed().isEmpty())
                ok = Database::removeSession(athleteId, date, v, s->day, s->number) && ok;
            else
                ok = Database::saveSession(athleteId, date, v, *s) && ok;
        }
        return ok;
    });
}

namespace {

QString stepsText(const QList<Step> &steps)
{
    QStringList parts;
    for (const Step &s : steps)
        parts.append(QStringLiteral("%1/%2/%3").arg(s.kg).arg(s.reps).arg(qMax(1, s.sets)));
    return parts.join(QStringLiteral("  "));
}

} // namespace

QStringList Store::competitionTypes() const
{
    return Competitions::typeNames();
}

QVariantList Store::competitions(const QString &athleteId) const
{
    QVariantList list;
    for (const Competition &c : Competitions::forAthlete(athleteId)) {
        QVariantList sn, cj;
        for (int i = 0; i < 3; ++i) {
            sn.append(c.snatch[i]);
            cj.append(c.cleanJerk[i]);
        }
        list.append(QVariantMap{
            {QStringLiteral("athleteId"), c.athleteId},
            {QStringLiteral("date"), c.date.toString(Qt::ISODate)},
            {QStringLiteral("dateText"), Dates::text(c.date)},
            {QStringLiteral("time"), Times::optional(c.time)},
            {QStringLiteral("type"), c.type},
            {QStringLiteral("typeName"), Competitions::typeShortNames().value(c.type)},
            {QStringLiteral("name"), c.name},
            {QStringLiteral("place"), c.place},
            {QStringLiteral("bodyWeight"), c.bodyWeight},
            {QStringLiteral("snatch"), sn},
            {QStringLiteral("cleanJerk"), cj},
            {QStringLiteral("bestSnatch"), c.bestSnatch()},
            {QStringLiteral("bestCleanJerk"), c.bestCleanJerk()},
            {QStringLiteral("total"), c.total()},
            {QStringLiteral("note"), c.note},
        });
    }
    return list;
}

QString Store::saveCompetition(const QVariantMap &m, const QString &oldDate, const QString &oldTime)
{
    Competition c;
    c.athleteId = m.value(QStringLiteral("athleteId")).toString();
    c.date = Dates::parse(m.value(QStringLiteral("date")).toString());
    if (!c.date.isValid())
        c.date = QDate::fromString(m.value(QStringLiteral("date")).toString(), Qt::ISODate);
    if (c.athleteId.isEmpty())
        return QStringLiteral("Bitte einen Sportler wählen.");
    if (!c.date.isValid())
        return QStringLiteral("Datum ungültig.");
    c.time = keyTime(m.value(QStringLiteral("time")).toString());
    if (!c.time.isValid())
        return QStringLiteral("Zeit ungültig.");
    c.type = qBound(0, m.value(QStringLiteral("type")).toInt(), int(Competitions::typeNames().size()) - 1);
    c.name = m.value(QStringLiteral("name")).toString().trimmed();
    c.place = m.value(QStringLiteral("place")).toString().trimmed();
    c.bodyWeight = QLocale(QLocale::German).toDouble(m.value(QStringLiteral("bodyWeight")).toString());
    const QVariantList sn = m.value(QStringLiteral("snatch")).toList();
    const QVariantList cj = m.value(QStringLiteral("cleanJerk")).toList();
    for (int i = 0; i < 3; ++i) {
        c.snatch[i] = qBound(-999, sn.value(i).toInt(), 999);
        c.cleanJerk[i] = qBound(-999, cj.value(i).toInt(), 999);
    }
    c.note = m.value(QStringLiteral("note")).toString().trimmed();
    const QDate od = QDate::fromString(oldDate, Qt::ISODate);
    const QTime ot = keyTime(oldTime);
    if (od.isValid() && (od != c.date || ot != c.time))
        Competitions::remove(c.athleteId, od, ot);
    if (!Competitions::save(c))
        return QStringLiteral("Speichern fehlgeschlagen.");
    bump();
    return QString();
}

bool Store::removeCompetition(const QString &athleteId, const QString &date, const QString &time)
{
    const bool ok = Competitions::remove(athleteId, QDate::fromString(date, Qt::ISODate), keyTime(time));
    bump();
    return ok;
}

QVariantMap Store::competitionTrend(const QString &athleteId, int fromYear, int toYear, int period,
                                    const QVariantList &types) const
{
    QList<Competition> list;
    for (const Competition &c : Competitions::between(athleteId, QDate(fromYear, 1, 1), QDate(toYear, 12, 31))) {
        for (const QVariant &t : types) {
            if (t.toInt() == c.type) {
                list.append(c);
                break;
            }
        }
    }
    QVariantList labels, total, snatch, cleanJerk;
    for (const Competitions::Point &p : Competitions::bestResults(list, period)) {
        labels.append(p.label);
        total.append(p.total > 0 ? QVariant(p.total) : QVariant());
        snatch.append(p.snatch > 0 ? QVariant(p.snatch) : QVariant());
        cleanJerk.append(p.cleanJerk > 0 ? QVariant(p.cleanJerk) : QVariant());
    }
    // The reference total for the latest competition's class
    int normValue = 0;
    if (!list.isEmpty()) {
        const Competition &last = list.last();
        const Athlete a = Database::athlete(athleteId);
        normValue = Competitions::norm(a.sex, a.born.isValid() ? last.date.year() - a.born.year() : 0,
                                       last.bodyWeight);
    }
    return {{QStringLiteral("labels"), labels}, {QStringLiteral("total"), total},
            {QStringLiteral("snatch"), snatch}, {QStringLiteral("cleanJerk"), cleanJerk},
            {QStringLiteral("norm"), normValue}};
}

QVariantList Store::exerciseHistory(const QString &athleteId, const QString &monday,
                                    const QString &variant, int exercise, int weeks) const
{
    const QDate to = toDate(monday);
    const QDate from = to.addDays(-7 * (qMax(1, weeks) - 1));
    QList<Database::ExerciseUse> uses = Database::exerciseUses(athleteId, toVariant(variant), exercise, from, to);
    QVariantList list;
    for (auto it = uses.crbegin(); it != uses.crend(); ++it) {
        const Stats st = Steps::compute(it->steps);
        list.append(QVariantMap{
            {QStringLiteral("week"), Weeks::label(it->monday)},
            {QStringLiteral("monday"), it->monday.toString(Qt::ISODate)},
            {QStringLiteral("day"), Weeks::dayName(it->day) + QStringLiteral(" (%1. TE)").arg(it->number)},
            {QStringLiteral("date"), Dates::text(it->monday.addDays(it->day - 1))},
            {QStringLiteral("bw"), st.bw},
            {QStringLiteral("mhg"), st.mhg},
            {QStringLiteral("wh"), st.wh},
            {QStringLiteral("repsSets"), st.bwRepsSets()},
            {QStringLiteral("steps"), stepsText(it->steps)},
        });
    }
    return list;
}

QVariantMap Store::exerciseTrend(const QString &athleteId, const QString &monday, const QString &variant,
                                 int exercise, int weeks) const
{
    const int n = qBound(1, weeks, 260);
    const QDate to = toDate(monday);
    const QDate from = to.addDays(-7 * (n - 1));
    QMap<QDate, QList<Step>> perWeek;
    for (const Database::ExerciseUse &u : Database::exerciseUses(athleteId, toVariant(variant), exercise, from, to))
        perWeek[u.monday] += u.steps;
    QVariantList labels, wh, mhg, bw;
    for (int i = 0; i < n; ++i) {
        const QDate m = from.addDays(7 * i);
        const Stats st = Steps::compute(perWeek.value(m));
        labels.append(Weeks::label(m));
        wh.append(st.wh);
        // No training that week: no point on the intensity lines
        mhg.append(st.wh > 0 ? QVariant(st.mhg) : QVariant());
        bw.append(st.wh > 0 ? QVariant(st.bw) : QVariant());
    }
    return {{QStringLiteral("labels"), labels}, {QStringLiteral("wh"), wh},
            {QStringLiteral("mhg"), mhg}, {QStringLiteral("bw"), bw}};
}

QVariantMap Store::stats(const QVariantList &steps) const
{
    return statsMap(Steps::compute(stepsFromList(steps)));
}

QVariantMap Store::weekStats(const QString &athleteId, const QString &monday,
                             const QString &variant, int day, int number,
                             const QVariantList &entries) const
{
    Week w = loadWeek(athleteId, monday, variant);
    Session edited;
    edited.day = day;
    edited.number = number;
    for (const QVariant &v : entries)
        edited.entries.append(entryFromMap(v.toMap()));
    bool replaced = false;
    for (Session &s : w.sessions) {
        if (s.day == day && s.number == number) {
            s = edited;
            replaced = true;
        }
    }
    if (!replaced)
        w.sessions.append(edited);

    QVariantMap result;
    const WeekSummary sum = w.summary();
    for (auto it = sum.perExercise.cbegin(); it != sum.perExercise.cend(); ++it)
        result.insert(QString::number(it.key()), statsMap(it.value()));
    return result;
}

QString Store::saveAthlete(const QVariantMap &m)
{
    Athlete a;
    a.id = m.value(QStringLiteral("id")).toString();
    a.lastName = m.value(QStringLiteral("lastName")).toString().trimmed();
    a.firstName = m.value(QStringLiteral("firstName")).toString().trimmed();
    a.sex = sexFromInt(m.value(QStringLiteral("sex")).toInt());
    a.born = Dates::parse(m.value(QStringLiteral("born")).toString());
    a.address = m.value(QStringLiteral("address")).toString();
    a.phone = m.value(QStringLiteral("phone")).toString();
    if (a.lastName.isEmpty())
        return QString();
    const QString id = Database::saveAthlete(a);
    emit athletesChanged();
    return id;
}

bool Store::removeAthlete(const QString &athleteId)
{
    const bool ok = Database::removeAthlete(athleteId);
    clearUndo(athleteId);
    if (m_clip && m_clip->athleteId == athleteId) {
        m_clip.reset();
        emit clipboardChanged();
    }
    emit athletesChanged();
    bump();
    return ok;
}

int Store::sessionCount(const QString &athleteId) const
{
    return Database::sessionCount(athleteId);
}

QString Store::today() const
{
    return QDate::currentDate().toString(Qt::ISODate);
}

QString Store::mondayOf(const QString &date) const
{
    return Weeks::mondayOf(toDate(date)).toString(Qt::ISODate);
}

QString Store::addWeeks(const QString &monday, int weeks) const
{
    return toDate(monday).addDays(7 * weeks).toString(Qt::ISODate);
}

QString Store::weekLabel(const QString &monday) const
{
    return Weeks::label(toDate(monday));
}

QString Store::weekFromLabel(const QString &label) const
{
    const QDate d = Weeks::fromLabel(label);
    return d.isValid() ? d.toString(Qt::ISODate) : QString();
}

QString Store::weekRange(const QString &monday) const
{
    const QDate d = toDate(monday);
    return d.toString(QStringLiteral("dd.MM.")) + QStringLiteral(" – ")
           + d.addDays(6).toString(QStringLiteral("dd.MM.yyyy"));
}

QString Store::dayName(int day) const
{
    return Weeks::dayName(day);
}

QString Store::dayDate(const QString &monday, int day) const
{
    return toDate(monday).addDays(day - 1).toString(QStringLiteral("dd.MM."));
}

QString Store::formatDate(const QString &isoDate) const
{
    return Dates::text(toDate(isoDate));
}

QString Store::parseDate(const QString &text) const
{
    const QDate d = Dates::parse(text);
    return d.isValid() ? d.toString(Qt::ISODate) : QString();
}

QString Store::exerciseName(int id) const
{
    return Catalog::name(id);
}

QString Store::exportBak(const QUrl &file, const QString &mode, const QString &sinceDate,
                         const QString &sinceTime, const QString &athleteId, const QString &fromWeek,
                         const QString &toWeek)
{
    BakExport::Filter f;
    if (mode == QLatin1String("since")) {
        const QDate d = Dates::parse(sinceDate);
        QTime t = Times::parse(sinceTime);
        if (!d.isValid())
            return QStringLiteral("Datum ungültig: ") + sinceDate;
        if (!t.isValid())
            t = QTime(0, 0);
        f.mode = BakExport::Filter::ChangedSince;
        f.since = QDateTime(d, t);
    } else if (mode == QLatin1String("athlete")) {
        f.mode = BakExport::Filter::AthleteWeeks;
        f.athleteId = athleteId;
        f.fromMonday = Weeks::fromLabel(fromWeek);
        f.toMonday = Weeks::fromLabel(toWeek);
        if (athleteId.isEmpty() || !f.fromMonday.isValid() || !f.toMonday.isValid())
            return QStringLiteral("Bitte Sportler und Wochen angeben.");
        if (f.toMonday < f.fromMonday)
            std::swap(f.fromMonday, f.toMonday);
    }
    const BakExport::Result r = BakExport::exportFile(file.toLocalFile(), f);
    if (r.ok)
        QSettings().setValue(QStringLiteral("export/last"), Database::now());
    return r.summary();
}

QUrl Store::suggestedExportUrl() const
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    return QUrl::fromLocalFile(QDir(dir).filePath(
        QStringLiteral("trainingsplaner_%1.bak").arg(QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd")))));
}

QString Store::lastExport() const
{
    const QDateTime t = QSettings().value(QStringLiteral("export/last")).toDateTime();
    return t.isValid() ? t.toString(QStringLiteral("dd.MM.yyyy HH:mm")) : QString();
}

QString Store::importBak(const QUrl &file, bool ignoreTimestamps)
{
    const BakImport::Result r = BakImport::importFile(file.toLocalFile(), ignoreTimestamps);
    clearUndo();
    emit athletesChanged();
    bump();
    QString text = r.summary();
    if (!r.ok && r.errors.isEmpty())
        text += QStringLiteral("\nImport fehlgeschlagen.");
    return text;
}

bool Store::printImage(const QImage &image, const QString &title)
{
    if (image.isNull())
        return false;
    QPrinter printer(QPrinter::HighResolution);
    printer.setPageLayout(QPageLayout(QPageSize(QPageSize::A4),
                                      image.width() > image.height() ? QPageLayout::Landscape : QPageLayout::Portrait,
                                      QMarginsF(12, 12, 12, 12), QPageLayout::Millimeter));
    printer.setDocName(title);
    QPrintDialog dialog(&printer);
    if (dialog.exec() != QDialog::Accepted)
        return false;
    QPainter p(&printer);
    const QRect page(0, 0, printer.width(), printer.height());
    p.setFont(QFont(QStringLiteral("Inter"), 12, QFont::Bold));
    const int titleH = p.fontMetrics().height() * 2;
    p.drawText(QRect(0, 0, page.width(), titleH), Qt::AlignLeft | Qt::AlignVCenter, title);
    const QSize fitted = image.size().scaled(page.width(), page.height() - titleH, Qt::KeepAspectRatio);
    p.setRenderHint(QPainter::SmoothPixmapTransform);
    p.drawImage(QRect(0, titleH, fitted.width(), fitted.height()), image);
    return true;
}

bool Store::printWeek(const QString &athleteId, const QString &monday, const QString &variant)
{
    const WeekReport::Options options = readPrintOptions();
    QPrinter printer(QPrinter::HighResolution);
    printer.setPageLayout(options.pageLayout());
    const Athlete a = Database::athlete(athleteId);
    printer.setDocName(QStringLiteral("Wochenplan %1 %2").arg(a.fullName(), weekLabel(monday)));
    QPrintDialog dialog(&printer);
    if (dialog.exec() != QDialog::Accepted)
        return false;
    WeekReport::render(&printer, loadWeek(athleteId, monday, variant),
                       {trainer(), organisation(), a.fullName()}, options);
    return true;
}

QUrl Store::suggestedPdfUrl(const QString &athleteId, const QString &monday) const
{
    const Athlete a = Database::athlete(athleteId);
    QString name = QStringLiteral("Wochenplan_%1_%2.pdf")
                       .arg(a.lastName.isEmpty() ? athleteId : a.lastName + QLatin1Char('_') + a.firstName,
                            weekLabel(monday).replace(QLatin1Char('/'), QLatin1Char('-')));
    name.replace(QLatin1Char(' '), QLatin1Char('_'));
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    return QUrl::fromLocalFile(QDir(dir).filePath(name));
}

QString Store::exportPdf(const QString &athleteId, const QString &monday, const QString &variant,
                         const QUrl &file, bool open)
{
    const QString path = file.toLocalFile();
    if (path.isEmpty())
        return QStringLiteral("Kein Dateiname angegeben.");
    const Athlete a = Database::athlete(athleteId);
    if (!WeekReport::writePdf(path, loadWeek(athleteId, monday, variant),
                              {trainer(), organisation(), a.fullName()}, readPrintOptions()))
        return QStringLiteral("PDF konnte nicht geschrieben werden.");
    if (!QFileInfo::exists(path))
        return QStringLiteral("PDF konnte nicht geschrieben werden: ") + QDir::toNativeSeparators(path);
    if (open)
        QDesktopServices::openUrl(file);
    return QString();
}
