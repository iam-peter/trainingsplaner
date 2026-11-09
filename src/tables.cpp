#include "tables.h"

#include "model.h"

#include <utility>

namespace {

using Pairs = QList<std::pair<const char *, const char *>>;

TableSpec spec(const char *fileName, const char *name, const Pairs &columns, const QStringList &fileKeys,
               const QMap<QString, ColumnFormat> &formats = {})
{
    TableSpec s;
    s.name = QString::fromLatin1(name);
    s.fileName = QString::fromLatin1(fileName);
    for (const auto &[file, stored] : columns) {
        s.fileColumns.append(QString::fromLatin1(file));
        if (*stored)
            s.columnOf.insert(QString::fromLatin1(file), QString::fromLatin1(stored));
    }
    s.fileKeys = fileKeys;
    s.formats = formats;
    return s;
}

bool isNone(const QVariant &v)
{
    return !v.isValid() || v.isNull();
}

} // namespace

QStringList TableSpec::keys() const
{
    QStringList list;
    for (const QString &k : fileKeys)
        list.append(column(k));
    return list;
}

QStringList TableSpec::stored() const
{
    QStringList list;
    for (const QString &c : fileColumns) {
        if (!column(c).isEmpty())
            list.append(column(c));
    }
    return list;
}

QVariant TableSpec::toStored(const QString &column, const QVariant &v) const
{
    switch (formats.value(column, ColumnFormat::Plain)) {
    case ColumnFormat::Plain:
        break;
    case ColumnFormat::YesNo: {
        // No value counts as yes, the old program's default
        const QString s = v.toString().trimmed();
        return s.compare(QLatin1String("N"), Qt::CaseInsensitive) == 0 || s == QLatin1String("0") ? 0 : 1;
    }
    case ColumnFormat::OptionalTime: {
        if (isNone(v))
            return QVariant();
        const QTime t = Times::parse(v.toString());
        if (t == QTime(0, 0) || v.toString().trimmed().isEmpty())
            return QVariant();
        return t.isValid() ? QVariant(Times::stored(t)) : v; // unreadable: kept as it came
    }
    }
    return v;
}

QVariant TableSpec::toFile(const QString &column, const QVariant &v) const
{
    switch (formats.value(column, ColumnFormat::Plain)) {
    case ColumnFormat::Plain:
        break;
    case ColumnFormat::YesNo:
        return isNone(v) || v.toInt() != 0 ? QStringLiteral("Y") : QStringLiteral("N");
    case ColumnFormat::OptionalTime:
        return isNone(v) ? QVariant(Times::stored(QTime(0, 0))) : v;
    }
    return v;
}

namespace Tables {

const QList<TableSpec> &all()
{
    // Each: the files' table name, the database's, the columns in the
    // files' order with their database names, the files' key columns
    static const QList<TableSpec> specs = {
        // Athletes
        spec("sp", "athletes",
             {{"spid", "id"}, {"del", ""}, {"korrektur", "changed_at"}, {"korrektur2", ""},
              {"user", "changed_by"}, {"name", "last_name"}, {"vorname", "first_name"}, {"sex", "sex"},
              {"geb", "born"}, {"adresse", "address"}, {"telefon", "phone"}},
             {"spid"}),
        // Training sessions
        spec("te", "sessions",
             {{"spid", "athlete_id"}, {"wodate", "monday"}, {"tag", "day"}, {"te", "number"},
              {"spi", "variant"}, {"del", ""}, {"korrektur", "changed_at"}, {"korrektur2", ""},
              {"user", "changed_by"}, {"art", "kind"}, {"von", "start_time"}, {"bis", "end_time"},
              {"bem", "note"}},
             {"spid", "wodate", "tag", "te", "spi"},
             {{QStringLiteral("start_time"), ColumnFormat::OptionalTime}, {QStringLiteral("end_time"), ColumnFormat::OptionalTime}}),
        // The lines of a session
        spec("te_ueb", "session_entries",
             {{"spid", "athlete_id"}, {"wodate", "monday"}, {"tag", "day"}, {"te", "number"},
              {"pos", "position"}, {"spi", "variant"}, {"del", ""}, {"korrektur", "changed_at"},
              {"korrektur2", ""}, {"user", "changed_by"}, {"ueb", "exercise"}, {"lststbem", "content"},
              {"art", "kind"}, {"kombi", "combination"}},
             {"spid", "wodate", "tag", "te", "pos", "spi"}),
        // Week notes, and the framework plan's week data
        spec("wo", "weeks",
             {{"spid", "owner"}, {"wodate", "monday"}, {"del", ""}, {"korrektur", "changed_at"},
              {"korrektur2", ""}, {"user", "changed_by"}, {"bel", "load"}, {"wklg", "competition_position"},
              {"verletzt", "injured"}, {"bem_soll", "target_note"}, {"bem_plan", "plan_note"}, {"bem_ist", "actual_note"}},
             {"spid", "wodate"}),
        // Reference totals
        spec("normen", "reference_totals",
             {{"sex", "sex"}, {"akl", "age_class"}, {"gkl", "weight_class"}, {"del", ""},
              {"korrektur", "changed_at"}, {"korrektur2", ""}, {"user", "changed_by"}, {"gklbez", "weight_class_name"},
              {"zk", "total"}},
             {"sex", "akl", "gkl"}),
        // Athlete attributes and extra info per day
        spec("spinfo", "athlete_info",
             {{"spid", "athlete_id"}, {"art", "kind"}, {"von", "from_date"}, {"zeit", "time"},
              {"del", ""}, {"korrektur", "changed_at"}, {"korrektur2", ""}, {"user", "changed_by"},
              {"bis", "to_date"}, {"info_text", "text"}, {"info_zahl", "number"}},
             {"spid", "art", "von", "zeit"}),
        // Competitions
        spec("wk", "competitions",
             {{"spid", "athlete_id"}, {"datum", "date"}, {"zeit", "time"}, {"del", ""},
              {"korrektur", "changed_at"}, {"korrektur2", ""}, {"user", "changed_by"}, {"wkart", "type"},
              {"wk", "name"}, {"ort", "place"}, {"gew", "body_weight"}, {"rei1", "snatch1"},
              {"rei2", "snatch2"}, {"rei3", "snatch3"}, {"sto1", "clean_jerk1"}, {"sto2", "clean_jerk2"},
              {"sto3", "clean_jerk3"}, {"zk", "total"}, {"bem", "note"}},
             {"spid", "datum", "zeit"}),
        // Macrocycles
        spec("maz", "macrocycles",
             {{"id", "id"}, {"del", ""}, {"korrektur", "changed_at"}, {"korrektur2", ""},
              {"user", "changed_by"}, {"sex", "sex"}, {"bez", "name"}, {"kbez", "short_name"},
              {"von", "first_monday"}, {"bis", "last_monday"}, {"abp_von", "build_up_monday"}, {"lap_von", "peak_monday"},
              {"bem", "note"}},
             {"id"}),
        // The athletes of a macrocycle
        spec("maz_sp", "macrocycle_athletes",
             {{"mazid", "macrocycle_id"}, {"spid", "athlete_id"}, {"del", ""}, {"korrektur", "changed_at"},
              {"korrektur2", ""}, {"user", "changed_by"}, {"gew", "weight_class"}, {"ziel_rei", "target_snatch"},
              {"ziel_sto", "target_clean_jerk"}, {"wk_rei", "competition_snatch"}, {"wk_sto", "competition_clean_jerk"}, {"auswahl", "selected"},
              {"bem", "note"}},
             {"mazid", "spid"},
             {{QStringLiteral("selected"), ColumnFormat::YesNo}}),
        // Week targets: ITP of an athlete, or framework plan of a macrocycle
        spec("ueb", "week_targets",
             {{"spid", "owner"}, {"wodate", "monday"}, {"ueb", "exercise"}, {"spi", "variant"},
              {"del", ""}, {"korrektur", "changed_at"}, {"korrektur2", ""}, {"user", "changed_by"},
              {"wh", "reps"}, {"mhg", "mean_weight"}, {"bw", "top_weight"}, {"bwsg", "top_weight_reps"},
              {"bwsganz", "top_weight_sets"}},
             {"spid", "wodate", "ueb", "spi"}),
        // Planned weight steps (new in this program)
        spec("itp_ls", "planned_steps",
             {{"spid", "owner"}, {"wodate", "monday"}, {"ueb", "exercise"}, {"del", ""},
              {"korrektur", "changed_at"}, {"korrektur2", ""}, {"user", "changed_by"}, {"lststbem", "steps"}},
             {"spid", "wodate", "ueb"}),
    };
    return specs;
}

QString label(const QString &name)
{
    static const QMap<QString, QString> names = {
        {QStringLiteral("athletes"), QStringLiteral("Sportler")},
        {QStringLiteral("sessions"), QStringLiteral("Trainingseinheiten")},
        {QStringLiteral("session_entries"), QStringLiteral("Übungen")},
        {QStringLiteral("weeks"), QStringLiteral("Wochen")},
        {QStringLiteral("reference_totals"), QStringLiteral("Normen")},
        {QStringLiteral("athlete_info"), QStringLiteral("Sportlerinfos")},
        {QStringLiteral("competitions"), QStringLiteral("Wettkämpfe")},
        {QStringLiteral("macrocycles"), QStringLiteral("MAZ")},
        {QStringLiteral("macrocycle_athletes"), QStringLiteral("MAZ-Sportler")},
        {QStringLiteral("week_targets"), QStringLiteral("ITP/RO-Werte")},
        {QStringLiteral("planned_steps"), QStringLiteral("ITP-Laststufen")},
    };
    return names.value(name, name);
}

const TableSpec *find(const QString &name)
{
    for (const TableSpec &s : all()) {
        if (s.name == name)
            return &s;
    }
    return nullptr;
}

const TableSpec *findFile(const QString &fileName)
{
    for (const TableSpec &s : all()) {
        if (fileName.compare(s.fileName, Qt::CaseInsensitive) == 0)
            return &s;
    }
    return nullptr;
}

} // namespace Tables
