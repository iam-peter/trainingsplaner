#include "tables.h"

#include "model.h"

namespace {

QStringList withMeta(const QStringList &keys, const QStringList &data)
{
    // keys, then del/korrektur/korrektur2/user, then the data columns
    return keys + QStringList{QStringLiteral("del"), QStringLiteral("korrektur"),
                              QStringLiteral("korrektur2"), QStringLiteral("user")}
           + data;
}

TableSpec spec(const char *name, const QStringList &columns, const QStringList &keys,
               const QMap<QString, ColumnFormat> &formats = {})
{
    TableSpec s;
    s.name = QString::fromLatin1(name);
    s.columns = columns;
    s.keys = keys;
    s.formats = formats;
    for (const QString &c : columns) {
        if (c != QLatin1String("del") && c != QLatin1String("korrektur2"))
            s.stored.append(c);
    }
    return s;
}

bool isNone(const QVariant &v)
{
    return !v.isValid() || v.isNull();
}

} // namespace

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
    using L = QStringList;
    static const QList<TableSpec> specs = {
        // As in the old program
        spec("sp", L{"spid", "del", "korrektur", "korrektur2", "user", "name", "vorname", "sex", "geb",
                     "adresse", "telefon"},
             {"spid"}),
        spec("te", L{"spid", "wodate", "tag", "te", "spi", "del", "korrektur", "korrektur2", "user", "art",
                     "von", "bis", "bem"},
             {"spid", "wodate", "tag", "te", "spi"},
             {{QStringLiteral("von"), ColumnFormat::OptionalTime},
              {QStringLiteral("bis"), ColumnFormat::OptionalTime}}),
        spec("te_ueb", L{"spid", "wodate", "tag", "te", "pos", "spi", "del", "korrektur", "korrektur2", "user",
                         "ueb", "lststbem", "art", "kombi"},
             {"spid", "wodate", "tag", "te", "pos", "spi"}),
        spec("wo", L{"spid", "wodate", "del", "korrektur", "korrektur2", "user", "bel", "wklg", "verletzt",
                     "bem_soll", "bem_plan", "bem_ist"},
             {"spid", "wodate"}),
        spec("normen", L{"sex", "akl", "gkl", "del", "korrektur", "korrektur2", "user", "gklbez", "zk"},
             {"sex", "akl", "gkl"}),
        // Athlete attributes and extra info per day
        spec("spinfo", L{"spid", "art", "von", "zeit", "del", "korrektur", "korrektur2", "user", "bis",
                         "info_text", "info_zahl"},
             {"spid", "art", "von", "zeit"}),
        // Competitions
        spec("wk", L{"spid", "datum", "zeit", "del", "korrektur", "korrektur2", "user", "wkart", "wk", "ort",
                     "gew", "rei1", "rei2", "rei3", "sto1", "sto2", "sto3", "zk", "bem"},
             {"spid", "datum", "zeit"}),
        // Macrocycles and their athletes
        spec("maz", L{"id", "del", "korrektur", "korrektur2", "user", "sex", "bez", "kbez", "von", "bis",
                      "abp_von", "lap_von", "bem"},
             {"id"}),
        spec("maz_sp", L{"mazid", "spid", "del", "korrektur", "korrektur2", "user", "gew", "ziel_rei",
                         "ziel_sto", "wk_rei", "wk_sto", "auswahl", "bem"},
             {"mazid", "spid"}, {{QStringLiteral("auswahl"), ColumnFormat::YesNo}}),
        // Week targets per exercise: ITP of an athlete, or framework plan of
        // a MAZ (spid "#<mazid>")
        spec("ueb", L{"spid", "wodate", "ueb", "spi", "del", "korrektur", "korrektur2", "user", "wh", "mhg",
                      "bw", "bwsg", "bwsganz"},
             {"spid", "wodate", "ueb", "spi"}),
        // Planned weight steps per week and exercise (new in this program)
        spec("itp_ls", withMeta({"spid", "wodate", "ueb"}, {"lststbem"}), {"spid", "wodate", "ueb"}),
    };
    return specs;
}

const TableSpec *find(const QString &name)
{
    for (const TableSpec &s : all()) {
        if (name.compare(s.name, Qt::CaseInsensitive) == 0)
            return &s;
    }
    return nullptr;
}

} // namespace Tables
