#include "store.h"

#include "bakimport.h"
#include "database.h"
#include "weekreport.h"

#include <QDesktopServices>
#include <QDir>
#include <QFileInfo>
#include <QPageLayout>
#include <QPrintDialog>
#include <QPrinter>
#include <QSettings>
#include <QStandardPaths>

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
        {QStringLiteral("from"), s.from},
        {QStringLiteral("to"), s.to},
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
    s.from = m.value(QStringLiteral("from")).toString().trimmed();
    s.to = m.value(QStringLiteral("to")).toString().trimmed();
    s.note = m.value(QStringLiteral("note")).toString();
    for (const QVariant &v : m.value(QStringLiteral("entries")).toList()) {
        const Entry e = entryFromMap(v.toMap());
        if (!entryIsBlank(e))
            s.entries.append(e);
    }
    return s;
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

QVariantList Store::athletes() const
{
    QVariantList list;
    for (const Athlete &a : Database::athletes()) {
        list.append(QVariantMap{
            {QStringLiteral("id"), a.id},
            {QStringLiteral("lastName"), a.lastName},
            {QStringLiteral("firstName"), a.firstName},
            {QStringLiteral("displayName"), a.displayName()},
            {QStringLiteral("sex"), a.sex},
            {QStringLiteral("born"), a.born.isValid() ? a.born.toString(QStringLiteral("dd.MM.yyyy")) : QString()},
            {QStringLiteral("address"), a.address},
            {QStringLiteral("phone"), a.phone},
        });
    }
    return list;
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
    // Suggest the times of another session with the same number this week.
    for (const Session &other : w.sessions) {
        if (other.number == number && !other.from.isEmpty()) {
            s.from = other.from;
            s.to = other.to;
            break;
        }
    }
    return sessionToMap(s, false);
}

bool Store::saveSession(const QString &athleteId, const QString &monday, const QString &variant,
                        const QVariantMap &session)
{
    const bool ok = Database::saveSession(athleteId, toDate(monday), toVariant(variant),
                                          sessionFromMap(session));
    bump();
    return ok;
}

bool Store::removeSession(const QString &athleteId, const QString &monday,
                          const QString &variant, int day, int number)
{
    const bool ok = Database::removeSession(athleteId, toDate(monday), toVariant(variant), day, number);
    bump();
    return ok;
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
    const int n = Database::copyWeek(m_clip->athleteId, m_clip->monday, m_clip->variant, athleteId,
                                     toDate(monday), toVariant(variant));
    bump();
    return n;
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
    a.sex = m.value(QStringLiteral("sex")).toInt();
    a.born = QDate::fromString(m.value(QStringLiteral("born")).toString(), QStringLiteral("dd.MM.yyyy"));
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
    const QDate d = toDate(isoDate);
    return d.isValid() ? d.toString(QStringLiteral("dd.MM.yyyy")) : QString();
}

QString Store::parseDate(const QString &text) const
{
    QDate d = QDate::fromString(text.trimmed(), QStringLiteral("d.M.yyyy"));
    return d.isValid() ? d.toString(Qt::ISODate) : QString();
}

QString Store::exerciseName(int id) const
{
    return Catalog::name(id);
}

QString Store::importBak(const QUrl &file)
{
    const BakImport::Result r = BakImport::importFile(file.toLocalFile());
    emit athletesChanged();
    bump();
    QString text = r.summary();
    if (!r.ok && r.errors.isEmpty())
        text += QStringLiteral("\nImport fehlgeschlagen.");
    return text;
}

bool Store::printWeek(const QString &athleteId, const QString &monday, const QString &variant)
{
    QPrinter printer(QPrinter::HighResolution);
    printer.setPageLayout(QPageLayout(QPageSize(QPageSize::A4), QPageLayout::Portrait,
                                      QMarginsF(12, 12, 12, 12), QPageLayout::Millimeter));
    const Athlete a = Database::athlete(athleteId);
    printer.setDocName(QStringLiteral("Wochenplan %1 %2").arg(a.fullName(), weekLabel(monday)));
    QPrintDialog dialog(&printer);
    if (dialog.exec() != QDialog::Accepted)
        return false;
    WeekReport::render(&printer, loadWeek(athleteId, monday, variant),
                       {trainer(), organisation(), a.fullName()});
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
                              {trainer(), organisation(), a.fullName()}))
        return QStringLiteral("PDF konnte nicht geschrieben werden.");
    if (!QFileInfo::exists(path))
        return QStringLiteral("PDF konnte nicht geschrieben werden: ") + QDir::toNativeSeparators(path);
    if (open)
        QDesktopServices::openUrl(file);
    return QString();
}
