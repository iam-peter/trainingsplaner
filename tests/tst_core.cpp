#include "bakexport.h"
#include "bakimport.h"
#include "competition.h"
#include "planning.h"
#include "analysis.h"
#include "database.h"
#include "exerciseweek.h"
#include "model.h"
#include "steps.h"
#include "tmk.h"
#include "update.h"
#include "weekreport.h"
#include "report.h"
#include "youth.h"

#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QPdfWriter>
#include <QPageLayout>
#include <QTimeZone>

#include <QSqlDatabase>
#include <QSqlQuery>
#include <QTemporaryDir>
#include <QtTest>

class TestCore : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void cleanupTestCase();

    void parseSteps();
    void formatSteps();
    void loadLetters();
    void jumpOnHalfGrid();
    void youthRules();
    void tmkCaps();
    void tmkVolumes();
    void etappen();
    void statsMatchOldProgram();
    void entryEncoding();
    void weekLabels();
    void bakParser();
    void importAndMerge();
    void oldFormatColumns();
    void otherLayoutRefused();
    void projectFilesOnly();
    void saveAndLoadSession();
    void copyWeek();
    void weekSummary();
    void exerciseWeekRows();
    void nextWeight();
    void printWithAllOptions();
    void exportRoundTrip();
    void reportRoundTripAndPdf();
    void bvdgSampleWeeks();
    void attributesWithHistory();
    void competitions();
    void planningBasics();
    void itpFromRo();
    void scalePlan();
    void countdown();
    void sectionAnalysis();
    void exerciseWeekApply();
    void compareVersions();
    void times();
    void stamps();
    void parseRelease();

private:
    QTemporaryDir m_dir;
};

void TestCore::initTestCase()
{
    QVERIFY(m_dir.isValid());
    QString error;
    QVERIFY2(Database::open(m_dir.filePath(QStringLiteral("test.sqlite")), &error),
             qPrintable(error));
}

void TestCore::cleanupTestCase()
{
    Database::close();
}

// The load of a week as h / m / g; the numbers are an assumption until
// checked against WinWoTA, so the mapping is tested in both directions
// The DGJ's rules: age class by year, the IWF's youth weight classes from
// August 2026, the DM Nachwuchs norms by weight class (AK 16-17) and by
// body weight (AK 14-15)
// The Trainingsmittelkatalog 2018 as caps: its cells read, the complexes
// of an age, and the RTK's framework plans within it but for the
// competition
void TestCore::tmkCaps()
{
    QCOMPARE(Tmk::stage(9), Tmk::Kinder);
    QCOMPARE(Tmk::stage(13), Tmk::Kinder);
    QCOMPARE(Tmk::stage(14), Tmk::Schueler);
    QCOMPARE(Tmk::stage(17), Tmk::Jugend);
    QCOMPARE(Tmk::stage(18), Tmk::Junioren);
    QCOMPARE(Tmk::stage(23), Tmk::U23);
    QCOMPARE(Tmk::stage(24), Tmk::Senioren);
    QCOMPARE(Tmk::stageName(Tmk::Schueler), QStringLiteral("Schüler (AK 14–15)"));

    // "95/2": BW and set size; a range up to its end; ">100" no cap
    Tmk::Entry e = Tmk::entry(1, Tmk::Schueler);
    QVERIFY(e.allowed);
    QCOMPARE(e.bw, 95);
    QCOMPARE(e.text, QStringLiteral("95/2"));
    QCOMPARE(Tmk::entry(1, Tmk::Junioren).bw, 101);
    QCOMPARE(Tmk::entry(3, Tmk::Senioren).bw, 100);
    QCOMPARE(Tmk::entry(29, Tmk::U23).bw, 0);
    QVERIFY(Tmk::entry(29, Tmk::U23).allowed);
    QCOMPARE(Tmk::entry(17, Tmk::Senioren).bw, 140);
    // Hatched: Lastheben before the Junioren, Halbkniebeuge never; the
    // AMKT has no percent
    QVERIFY(!Tmk::entry(15, Tmk::Jugend).allowed);
    QVERIFY(Tmk::entry(15, Tmk::Junioren).allowed);
    for (int s = Tmk::Kinder; s <= Tmk::Senioren; ++s)
        QVERIFY(!Tmk::entry(21, Tmk::Stage(s)).allowed);
    QVERIFY(!Tmk::entry(30, Tmk::Kinder).allowed);
    QCOMPARE(Tmk::entry(30, Tmk::Schueler).bw, 0);
    QVERIFY(Tmk::entry(30, Tmk::Schueler).allowed);
    QVERIFY(Tmk::entry(99, Tmk::Kinder).allowed);

    // Complexes: K3 from the Schüler, K6 from the Jugend, K4 from the
    // Junioren; K5 and K7 for children too
    QVERIFY(!Tmk::entry(-3, Tmk::Kinder).allowed);
    QVERIFY(Tmk::entry(-3, Tmk::Schueler).allowed);
    QVERIFY(!Tmk::entry(-6, Tmk::Schueler).allowed);
    QVERIFY(Tmk::entry(-6, Tmk::Jugend).allowed);
    QVERIFY(!Tmk::entry(-4, Tmk::Jugend).allowed);
    QVERIFY(Tmk::entry(-4, Tmk::Junioren).allowed);
    QVERIFY(Tmk::entry(-5, Tmk::Kinder).allowed);
    QVERIFY(Tmk::entry(-7, Tmk::Kinder).allowed);
    QCOMPARE(Tmk::notForStage(-4, Tmk::Jugend),
             QStringLiteral("K4 ist im TMK 2018 nicht für Jugend (AK 16–17) vorgesehen."));
    QCOMPARE(Tmk::notForStage(-4, Tmk::Junioren), QString());

    QVERIFY(Tmk::exemptInCompetition(1, QStringLiteral("HWK")));
    QVERIFY(Tmk::exemptInCompetition(3, QStringLiteral(" wk")));
    QVERIFY(!Tmk::exemptInCompetition(4, QStringLiteral("HWK")));
    QVERIFY(!Tmk::exemptInCompetition(1, QStringLiteral("LG")));

    // The RTK's plans: U13 for Kinder, U15 Schüler, U17 Jugend, U20
    // Junioren. Nothing of another age, no BW above the cap but in the
    // competition.
    QFile f(QStringLiteral(":/rtk-ro.json"));
    QVERIFY(f.open(QIODevice::ReadOnly));
    const QJsonArray templates = QJsonDocument::fromJson(f.readAll()).object().value(QStringLiteral("templates")).toArray();
    QCOMPARE(templates.size(), 4);
    const Tmk::Stage stages[] = {Tmk::Kinder, Tmk::Schueler, Tmk::Jugend, Tmk::Junioren};
    int checked = 0;
    for (int i = 0; i < 4; ++i) {
        for (const QJsonValue &r : templates[i].toObject().value(QStringLiteral("rows")).toArray()) {
            const QJsonObject row = r.toObject();
            const QString position = row.value(QStringLiteral("position")).toString();
            const QJsonObject complexes = row.value(QStringLiteral("complexes")).toObject();
            for (auto it = complexes.begin(); it != complexes.end(); ++it)
                QVERIFY(Tmk::entry(-it.key().toInt(), stages[i]).allowed);
            const QJsonObject exercises = row.value(QStringLiteral("exercises")).toObject();
            for (auto it = exercises.begin(); it != exercises.end(); ++it) {
                const int exercise = it.key().toInt();
                const Tmk::Entry tmk = Tmk::entry(exercise, stages[i]);
                QVERIFY2(tmk.allowed, qPrintable(it.key()));
                const int bw = it.value().toArray().at(1).toInt();
                if (tmk.bw > 0 && !Tmk::exemptInCompetition(exercise, position)) {
                    QVERIFY2(bw <= tmk.bw, qPrintable(QStringLiteral("%1 Woche %2: %3 > %4")
                                                          .arg(it.key()).arg(row.value(QStringLiteral("week")).toInt())
                                                          .arg(bw).arg(tmk.bw)));
                    ++checked;
                }
            }
        }
    }
    QVERIFY(checked > 500);
}

// The training stages and their sessions a week (IAT factsheet 2024)
void TestCore::etappen()
{
    QCOMPARE(Tmk::etappe(0).code, QString());
    QCOMPARE(Tmk::etappe(11).code, QStringLiteral("AGA"));
    QCOMPARE(Tmk::etappe(13).maxSessions, 3);
    QCOMPARE(Tmk::etappe(14).code, QStringLiteral("GLT"));
    QCOMPARE(Tmk::etappe(15).minSessions, 3);
    QCOMPARE(Tmk::etappe(16).code, QStringLiteral("ABT"));
    QCOMPARE(Tmk::etappe(17).maxSessions, 7);
    QCOMPARE(Tmk::etappe(18).code, QStringLiteral("AST"));
    QCOMPARE(Tmk::etappe(23).code, QStringLiteral("AST"));
    QCOMPARE(Tmk::etappe(24).code, QStringLiteral("HLT"));
    QCOMPARE(Tmk::etappe(30).minSessions, 7);
    QCOMPARE(Tmk::etappeText(16), QStringLiteral("ABT (Aufbautraining), 5–7 Trainingseinheiten je Woche"));
    QCOMPARE(Tmk::etappeText(0), QString());
}

// The TMK's WH a week per stage, and the RTK's framework plans around it
// on average: the norm is a mean over the cycle, not a cap
void TestCore::tmkVolumes()
{
    QList<int> k17;
    for (int s = Tmk::Kinder; s <= Tmk::Senioren; ++s)
        k17.append(Tmk::weeklyWh(0, Tmk::Stage(s)));
    QCOMPARE(k17, QList<int>({200, 280, 350, 300, 320, 300}));
    QCOMPARE(Tmk::weeklyWh(-1, Tmk::Kinder), 85);
    QCOMPARE(Tmk::weeklyWh(-3, Tmk::Kinder), 0);
    QCOMPARE(Tmk::weeklyWh(-4, Tmk::Junioren), 30);
    QCOMPARE(Tmk::weeklyWh(-6, Tmk::Senioren), 70);
    QCOMPARE(Tmk::weeklyWh(-7, Tmk::Jugend), 0);
    QCOMPARE(Tmk::weeklyWh(-8, Tmk::Jugend), 0);

    QFile f(QStringLiteral(":/rtk-ro.json"));
    QVERIFY(f.open(QIODevice::ReadOnly));
    const QJsonArray templates = QJsonDocument::fromJson(f.readAll()).object().value(QStringLiteral("templates")).toArray();
    const Tmk::Stage stages[] = {Tmk::Kinder, Tmk::Schueler, Tmk::Jugend, Tmk::Junioren};
    for (int i = 0; i < 4; ++i) {
        const QJsonArray rows = templates[i].toObject().value(QStringLiteral("rows")).toArray();
        int sum = 0, max = 0;
        for (const QJsonValue &r : rows) {
            int week = 0;
            const QJsonObject complexes = r.toObject().value(QStringLiteral("complexes")).toObject();
            for (auto it = complexes.begin(); it != complexes.end(); ++it)
                week += it.value().toInt();
            sum += week;
            max = qMax(max, week);
        }
        const double mean = double(sum) / rows.size();
        const int norm = Tmk::weeklyWh(0, stages[i]);
        // U13 201 for 200, U15 289 for 280, U17 358 for 350, U20 299 for 300
        QVERIFY2(qAbs(mean - norm) <= 10, qPrintable(QString::number(mean)));
        QVERIFY(max > norm);
    }
}

void TestCore::youthRules()
{
    QCOMPARE(Youth::ageClass(QDate(2010, 12, 31), QDate(2026, 1, 2)), 16);
    QVERIFY(Youth::limitedToOnePerWeek(17));
    QVERIFY(!Youth::limitedToOnePerWeek(18));
    QVERIFY(Youth::dmAge(14) && Youth::dmAge(17));
    QVERIFY(!Youth::dmAge(13) && !Youth::dmAge(18));
    QCOMPARE(Youth::weightClassFor(0, 84.4), QStringLiteral("-85"));
    QCOMPARE(Youth::weightClassFor(0, 85.0), QStringLiteral("-85"));
    QCOMPARE(Youth::weightClassFor(0, 110), QStringLiteral("+95"));
    QCOMPARE(Youth::weightClassFor(1, 63.4), QStringLiteral("-69"));
    QCOMPARE(Youth::weightClassFromLimit(1, 87), QStringLiteral("+77"));

    // AK 14-15: up to the next whole kg, within the table
    QCOMPARE(Youth::normRow(0, 15, 45.3), QStringLiteral("46"));
    QCOMPARE(Youth::normRow(0, 15, 46.0), QStringLiteral("46"));
    QCOMPARE(Youth::normRow(0, 14, 30.0), QStringLiteral("35"));
    QCOMPARE(Youth::normRow(0, 14, 102.0), QStringLiteral("102"));
    QCOMPARE(Youth::normRow(0, 14, 102.1), QStringLiteral("+102"));
    QCOMPARE(Youth::normRow(1, 15, 90.0), QStringLiteral("+81"));
    // AK 16-17: the weight class
    QCOMPARE(Youth::normRow(1, 17, 58.0), QStringLiteral("-61"));
    QCOMPARE(Youth::normRow(0, 16, 0), QString());

    // The DGJ's table of August 2026: 69 rows of body weight for boys,
    // 53 for girls, in AK 14 and 15, and 8 classes each
    const QList<Youth::Norm> norms = Youth::defaultDmNorms();
    QCOMPARE(norms.size(), 2 * 69 + 2 * 53 + 2 * 8);
    auto total = [&](int sex, int ak, const QString &row) {
        for (const Youth::Norm &n : norms)
            if (n.sex == sex && n.ageClass == ak && n.weightClass == row)
                return n.total;
        return 0;
    };
    QCOMPARE(total(0, 14, QStringLiteral("35")), 70);
    QCOMPARE(total(0, 15, QStringLiteral("46")), 99);
    QCOMPARE(total(0, 15, QStringLiteral("+102")), 177);
    QCOMPARE(total(1, 14, QStringLiteral("30")), 55);
    QCOMPARE(total(1, 15, QStringLiteral("+81")), 125);
    QCOMPARE(total(0, 16, QStringLiteral("-65")), 151);
    QCOMPARE(total(0, 16, QStringLiteral("+95")), 206);
    QCOMPARE(total(1, 16, QStringLiteral("-45")), 93);
    QCOMPARE(total(1, 16, QStringLiteral("+77")), 139);
}

// With 2.5 kg steps the weights are stored as 70, 72, 75, 77: rises of 2
// and 3 are one jump of 2.5, and the proposals stay on that grid
void TestCore::jumpOnHalfGrid()
{
    auto line = [](std::initializer_list<int> kgs) {
        QList<Step> l;
        for (int kg : kgs)
            l.append(Step{kg, 3, 1, 0});
        return l;
    };
    QCOMPARE(Steps::usualJump({line({70, 72, 75, 77, 80})}), 2.5);
    QCOMPARE(Steps::usualJump({line({40, 43, 46, 50})}), 3.0);
    QCOMPARE(Steps::usualJump({line({60, 65, 70}), line({70, 75})}), 5.0);
    QCOMPARE(Steps::usualJump({line({60, 67, 75, 82, 90})}), 7.5);
    QCOMPARE(Steps::usualJump({}), 0.0);
    QCOMPARE(Steps::proposedWeight(80, 2.5), 82);
    QCOMPARE(Steps::proposedWeight(82, 2.5), 85);
    QCOMPARE(Steps::proposedWeight(72, 5), 77);
    QCOMPARE(Steps::proposedWeight(100, 5), 105);
    QCOMPARE(Steps::proposedWeight(42, 3), 45);
    QCOMPARE(Steps::proposedWeight(998, 5), 999);
    QCOMPARE(Steps::proposedWeight(0, 5), 0);
}

void TestCore::loadLetters()
{
    QCOMPARE(Planning::loadText(0), QString());
    QCOMPARE(Planning::loadText(1), QStringLiteral("g"));
    QCOMPARE(Planning::loadText(2), QStringLiteral("m"));
    QCOMPARE(Planning::loadText(3), QStringLiteral("h"));
    QCOMPARE(Planning::loadText(7), QStringLiteral("7"));
    for (int n = 0; n <= 3; ++n)
        QCOMPARE(Planning::loadFromText(Planning::loadText(n)), n);
    QCOMPARE(Planning::loadFromText(QStringLiteral(" H ")), 3);
    QCOMPARE(Planning::loadFromText(QStringLiteral("7")), 7);
    QCOMPARE(Planning::loadFromText(QStringLiteral("x")), -1);
}

void TestCore::parseSteps()
{
    const QList<Step> s = Steps::parse(QStringLiteral("012003030;015003020"));
    QCOMPARE(s.size(), 2);
    QCOMPARE(s[0], (Step{12, 3, 3, 0}));
    QCOMPARE(s[1], (Step{15, 3, 2, 0}));
    QCOMPARE(Steps::parse(QStringLiteral("100003012")).value(0), (Step{100, 3, 1, 2}));
    QVERIFY(Steps::parse(QStringLiteral("4x12;")).isEmpty());
    QVERIFY(Steps::parse(QString()).isEmpty());
}

void TestCore::formatSteps()
{
    const QString text = QStringLiteral("060004010;065003010;080002020;083002020");
    QCOMPARE(Steps::format(Steps::parse(text)), text);
    QCOMPARE(Steps::format({{13, 4, 3, 0}, {}, {15, 3, 2, 0}}), QStringLiteral("013004030;015003020"));
}

void TestCore::statsMatchOldProgram()
{
    // Example checked against the old program: 12 kg 3x3, 15 kg 3x2 -> 15 Wh, MHG 13, BW 15, 3/2
    Stats a = Steps::compute({{12, 3, 3, 0}, {15, 3, 2, 0}});
    QCOMPARE(a.wh, 15);
    QCOMPARE(a.mhg, 13);
    QCOMPARE(a.bw, 15);
    QCOMPARE(a.bwRepsSets(), QStringLiteral("3/2"));
    QCOMPARE(a.summary(), QStringLiteral("15Wh / 13kg / 0,2t"));

    // After the edit: 13 kg 4x3, 15 kg 3x2 -> 18 Wh, MHG 14 (13.67 rounded)
    Stats b = Steps::compute({{13, 4, 3, 0}, {15, 3, 2, 0}});
    QCOMPARE(b.wh, 18);
    QCOMPARE(b.mhg, 14);
    QCOMPARE(b.summary(), QStringLiteral("18Wh / 14kg / 0,2t"));
}

void TestCore::entryEncoding()
{
    Entry t = Entry::decode(1, 37, QStringLiteral("4x12;48"), 0);
    QCOMPARE(t.kind, Entry::ExerciseText);
    QCOMPARE(t.text, QStringLiteral("4x12"));
    QCOMPARE(t.totalReps, 48);
    QCOMPARE(t.encode(), QStringLiteral("4x12;48"));

    Entry t2 = Entry::decode(1, 32, QStringLiteral("4x8;"), 0);
    QCOMPARE(t2.totalReps, 0);
    QCOMPARE(t2.encode(), QStringLiteral("4x8;"));

    Entry f = Entry::decode(2, 0, QStringLiteral("Planke 4x 2 Minuten"), 0);
    QCOMPARE(f.kind, Entry::FreeText);
    QCOMPARE(f.encode(), QStringLiteral("Planke 4x 2 Minuten"));
}

void TestCore::weekLabels()
{
    const QDate monday(2026, 11, 9);
    QCOMPARE(Weeks::label(monday), QStringLiteral("46/2026"));
    QCOMPARE(Weeks::fromLabel(QStringLiteral("46/2026")), monday);
    QCOMPARE(Weeks::mondayOf(QDate(2026, 11, 15)), monday);
    QCOMPARE(Weeks::fromLabel(QStringLiteral("1/2026")), QDate(2025, 12, 29));
    QVERIFY(!Weeks::fromLabel(QStringLiteral("54/2026")).isValid());
    QVERIFY(!Weeks::fromLabel(QStringLiteral("abc")).isValid());
}

void TestCore::bakParser()
{
    const QString text = QStringLiteral(
        "DELETE FROM sp WHERE spid=\"x\" AND korrektur<\"2020-01-01 00:00:00\"\r\n"
        "INSERT IGNORE INTO sp VALUES (\"x\",\"N\",\"2020-01-01 00:00:00\",NOW(),\"u\","
        "\"Mei\\\"er\",\"Ann, a\",\"1\",NULL,\"Zeile1\\r\\nZeile2\",NULL)\r\n"
        "SELECT 1\r\n");
    int ignored = 0;
    QStringList errors;
    const QList<BakImport::Row> rows = BakImport::parse(text, &ignored, &errors);
    QVERIFY2(errors.isEmpty(), qPrintable(errors.join(QLatin1Char('\n'))));
    QCOMPARE(ignored, 1);
    QCOMPARE(rows.size(), 1);
    QCOMPARE(rows[0].table, QStringLiteral("sp"));
    QCOMPARE(rows[0].values.size(), 11);
    QCOMPARE(rows[0].values[5].toString(), QStringLiteral("Mei\"er"));
    QCOMPARE(rows[0].values[6].toString(), QStringLiteral("Ann, a"));
    QVERIFY(!rows[0].values[8].isValid());
    QCOMPARE(rows[0].values[9].toString(), QStringLiteral("Zeile1\r\nZeile2"));

    QCOMPARE(BakImport::decode(QByteArray("Gr\xfc\xdf" "e \x80")), QStringLiteral("Grüße €"));
}

void TestCore::importAndMerge()
{
    const QString v1 = QStringLiteral(
        "INSERT IGNORE INTO sp VALUES (\"müßig_jörg\",\"N\",\"2024-03-01 10:00:00\",NOW(),"
        "\"trainer\",\"Müßig\",\"Jörg\",\"0\",\"2001-03-24\",NULL,NULL)\n"
        "INSERT IGNORE INTO te VALUES (\"müßig_jörg\",\"2024-03-04\",\"1\",\"2\",\"P\",\"N\","
        "\"2024-03-02 10:00:00\",NOW(),\"trainer\",\"0\",\"15:30:00\",\"17:30:00\",NULL)\n"
        "INSERT IGNORE INTO te_ueb VALUES (\"müßig_jörg\",\"2024-03-04\",\"1\",\"2\",\"1\","
        "\"P\",\"N\",\"2024-03-02 10:05:00\",NOW(),\"trainer\",\"6\",\"060004010;065003010\",\"0\",\"0\")\n"
        "INSERT IGNORE INTO te_ueb VALUES (\"müßig_jörg\",\"2024-03-04\",\"1\",\"2\",\"2\","
        "\"P\",\"N\",\"2024-03-02 10:05:00\",NOW(),\"trainer\",\"13\",\"070003020\",\"0\",\"0\")\n");
    BakImport::Result r = BakImport::importText(v1);
    QVERIFY2(r.ok && r.errors.isEmpty(), qPrintable(r.summary()));
    QCOMPARE(r.tables.value(QStringLiteral("session_entries")).added, 2);

    // Importing the same file again changes nothing.
    r = BakImport::importText(v1);
    QCOMPARE(r.tables.value(QStringLiteral("session_entries")).skipped, 2);

    // A newer export deletes position 2 and changes position 1.
    const QString v2 = QStringLiteral(
        "INSERT IGNORE INTO te_ueb VALUES (\"müßig_jörg\",\"2024-03-04\",\"1\",\"2\",\"1\","
        "\"P\",\"N\",\"2024-03-03 10:00:00\",NOW(),\"trainer\",\"6\",\"062004010\",\"0\",\"0\")\n"
        "INSERT IGNORE INTO te_ueb VALUES (\"müßig_jörg\",\"2024-03-04\",\"1\",\"2\",\"2\","
        "\"P\",\"Y\",\"2024-03-03 10:00:00\",NOW(),\"trainer\",\"13\",\"070003020\",NULL,NULL)\n");
    r = BakImport::importText(v2);
    QCOMPARE(r.tables.value(QStringLiteral("session_entries")).updated, 1);
    QCOMPARE(r.tables.value(QStringLiteral("session_entries")).removed, 1);

    const Week w = Database::loadWeek(QStringLiteral("müßig_jörg"), QDate(2024, 3, 4),
                                      Variant::Plan);
    QCOMPARE(w.sessions.size(), 1);
    QCOMPARE(w.sessions[0].from, QTime(15, 30));
    QCOMPARE(w.sessions[0].entries.size(), 1);
    QCOMPARE(w.sessions[0].entries[0].steps.value(0), (Step{62, 4, 1, 0}));
}

// Columns stored differently from the old program's files: they read in
// as the stored type and go out again as the old program wrote them
void TestCore::oldFormatColumns()
{
    const QString file = QStringLiteral(
        "INSERT IGNORE INTO sp VALUES (\"alt_otto\",\"N\",\"2024-05-01 10:00:00\",NOW(),"
        "\"trainer\",\"Alt\",\"Otto\",\"0\",NULL,NULL,NULL)\n"
        "INSERT IGNORE INTO te VALUES (\"alt_otto\",\"2024-05-06\",\"2\",\"1\",\"P\",\"N\","
        "\"2024-05-02 10:00:00\",NOW(),\"trainer\",\"0\",\"00:00:00\",\"00:00:00\",\"ohne Zeit\")\n"
        "INSERT IGNORE INTO maz VALUES (\"m_alt\",\"N\",\"2024-05-01 10:00:00\",NOW(),\"trainer\","
        "\"0\",\"Alt-MAZ\",\"AM\",\"2024-05-06\",\"2024-06-24\",NULL,NULL,NULL)\n"
        "INSERT IGNORE INTO maz_sp VALUES (\"m_alt\",\"alt_otto\",\"N\",\"2024-05-01 10:00:00\",NOW(),"
        "\"trainer\",\"73\",\"80\",\"100\",NULL,NULL,\"N\",NULL)\n");
    BakImport::Result r = BakImport::importText(file);
    QVERIFY2(r.ok && r.errors.isEmpty(), qPrintable(r.summary()));

    // Stored: no time as NULL, the choice as 0
    QSqlQuery q;
    QVERIFY(q.exec(QStringLiteral("SELECT start_time, end_time FROM sessions WHERE athlete_id = 'alt_otto'")) && q.next());
    QVERIFY(q.value(0).isNull() && q.value(1).isNull());
    QVERIFY(q.exec(QStringLiteral("SELECT selected FROM macrocycle_athletes WHERE athlete_id = 'alt_otto'")) && q.next());
    QCOMPARE(q.value(0).toInt(), 0);
    const Week w = Database::loadWeek(QStringLiteral("alt_otto"), QDate(2024, 5, 6), Variant::Plan);
    QVERIFY(!w.sessions.value(0).from.isValid());

    // Saving the athlete's MAZ data keeps the imported choice
    MazAthlete ma = Planning::mazAthletes(QStringLiteral("m_alt")).value(0);
    QVERIFY(!ma.selected);
    ma.targetSnatch = 82;
    QVERIFY(Planning::saveMazAthlete(ma));
    QVERIFY(!Planning::mazAthletes(QStringLiteral("m_alt")).value(0).selected);

    // Out again in the old program's form
    BakExport::Filter f;
    f.mode = BakExport::Filter::Maz;
    f.mazId = QStringLiteral("m_alt");
    const QString maz = BakExport::exportText(f);
    QVERIFY2(maz.contains(QStringLiteral("\"82\",\"100\",NULL,NULL,\"N\"")), qPrintable(maz));
    f = {};
    f.mode = BakExport::Filter::AthleteWeeks;
    f.athleteId = QStringLiteral("alt_otto");
    f.fromMonday = f.toMonday = QDate(2024, 5, 6);
    const QString week = BakExport::exportText(f);
    QVERIFY2(week.contains(QStringLiteral("\"00:00:00\",\"00:00:00\",\"ohne Zeit\"")), qPrintable(week));

    // Change stamps compare as times, not as text: "T" sorts after " ",
    // yet this row is older than the stored one and must not replace it
    r = BakImport::importText(QStringLiteral(
        "INSERT IGNORE INTO te VALUES (\"alt_otto\",\"2024-05-06\",\"2\",\"1\",\"P\",\"N\","
        "\"2024-05-02T09:00:00\",NOW(),\"trainer\",\"0\",\"16:00:00\",\"18:00:00\",\"älter\")\n"));
    QCOMPARE(r.tables.value(QStringLiteral("sessions")).skipped, 1);
    // A newer one does, and its stamp is stored in the usual form
    r = BakImport::importText(QStringLiteral(
        "INSERT IGNORE INTO te VALUES (\"alt_otto\",\"2024-05-06\",\"2\",\"1\",\"P\",\"N\","
        "\"2024-05-02T11:00:00\",NOW(),\"trainer\",\"0\",\"16:00:00\",\"18:00:00\",\"neuer\")\n"));
    QCOMPARE(r.tables.value(QStringLiteral("sessions")).updated, 1);
    QVERIFY(q.exec(QStringLiteral("SELECT changed_at, start_time FROM sessions WHERE athlete_id = 'alt_otto'")) && q.next());
    QCOMPARE(q.value(0).toString(), QStringLiteral("2024-05-02 11:00:00"));
    QCOMPARE(q.value(1).toString(), QStringLiteral("16:00:00"));

    QVERIFY(Planning::removeMaz(QStringLiteral("m_alt")));
    QVERIFY(Database::removeAthlete(QStringLiteral("alt_otto")));
}

// A file of another table layout, e.g. version 0.3.0's, is not opened
// and not changed
void TestCore::otherLayoutRefused()
{
    QCOMPARE(Database::schemaVersion(), Database::latestSchemaVersion());

    const QString old = m_dir.filePath(QStringLiteral("old.sqlite"));
    {
        QSqlDatabase d = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), QStringLiteral("old"));
        d.setDatabaseName(old);
        QVERIFY(d.open());
        QSqlQuery q(d);
        QVERIFY(q.exec(QStringLiteral("CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT)")));
        QVERIFY(q.exec(QStringLiteral("INSERT INTO meta VALUES ('schema', '1')")));
        QVERIFY(q.exec(QStringLiteral("CREATE TABLE sp (spid TEXT PRIMARY KEY, name TEXT)")));
        d.close();
    }
    QSqlDatabase::removeDatabase(QStringLiteral("old"));

    Database::close();
    QString error;
    QVERIFY(!Database::open(old, &error));
    QVERIFY(error.contains(QStringLiteral("anderen Version")));
    {
        QSqlDatabase d = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), QStringLiteral("old"));
        d.setDatabaseName(old);
        QVERIFY(d.open());
        QSqlQuery q(d);
        QVERIFY(q.exec(QStringLiteral("SELECT group_concat(name) FROM sqlite_master WHERE type = 'table'")) && q.next());
        QCOMPARE(q.value(0).toString(), QStringLiteral("meta,sp"));
        d.close();
    }
    QSqlDatabase::removeDatabase(QStringLiteral("old"));

    QVERIFY(Database::open(m_dir.filePath(QStringLiteral("test.sqlite"))));
}

// A project opened from the menu must already be one of this program's
// files: another SQLite file, any other file or a missing one stays as it
// is. A copy of the open project opens as one.
void TestCore::projectFilesOnly()
{
    const QString foreign = m_dir.filePath(QStringLiteral("foreign.sqlite"));
    {
        QSqlDatabase d = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), QStringLiteral("foreign"));
        d.setDatabaseName(foreign);
        QVERIFY(d.open());
        QSqlQuery q(d);
        QVERIFY(q.exec(QStringLiteral("CREATE TABLE x (a TEXT)")));
        d.close();
    }
    QSqlDatabase::removeDatabase(QStringLiteral("foreign"));
    const QString text = m_dir.filePath(QStringLiteral("notes.txt"));
    {
        QFile f(text);
        QVERIFY(f.open(QIODevice::WriteOnly));
        f.write("Kein Projekt\n");
    }
    const QString missing = m_dir.filePath(QStringLiteral("missing.trainingsplaner"));

    Database::close();
    QString error;
    QVERIFY(!Database::open(foreign, &error, true));
    QVERIFY(error.contains(QStringLiteral("kein Projekt")));
    QVERIFY(!Database::open(text, &error, true));
    QVERIFY(!Database::open(missing, &error, true));
    QVERIFY(!QFile::exists(missing));
    {
        QSqlDatabase d = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), QStringLiteral("foreign"));
        d.setDatabaseName(foreign);
        QVERIFY(d.open());
        QSqlQuery q(d);
        QVERIFY(q.exec(QStringLiteral("SELECT group_concat(name) FROM sqlite_master WHERE type = 'table'")) && q.next());
        QCOMPARE(q.value(0).toString(), QStringLiteral("x"));
        d.close();
    }
    QSqlDatabase::removeDatabase(QStringLiteral("foreign"));
    {
        QFile f(text);
        QVERIFY(f.open(QIODevice::ReadOnly));
        QCOMPARE(f.readAll(), QByteArray("Kein Projekt\n"));
    }

    QVERIFY(Database::open(m_dir.filePath(QStringLiteral("test.sqlite"))));
    const int athletes = Database::athletes().size();
    const QString copy = m_dir.filePath(QStringLiteral("copy.trainingsplaner"));
    QVERIFY(Database::copyTo(copy, &error));
    Database::close();
    QVERIFY2(Database::open(copy, &error, true), qPrintable(error));
    QCOMPARE(Database::athletes().size(), athletes);
    Database::close();
    QVERIFY(Database::open(m_dir.filePath(QStringLiteral("test.sqlite"))));
}

void TestCore::saveAndLoadSession()
{
    Athlete a;
    a.lastName = QStringLiteral("Muster");
    a.firstName = QStringLiteral("Erika");
    a.sex = Sex::Female;
    const QString id = Database::saveAthlete(a);
    QCOMPARE(id, QStringLiteral("muster_erika"));
    QCOMPARE(Database::saveAthlete(a), QStringLiteral("muster_erika_2"));
    QVERIFY(Database::removeAthlete(QStringLiteral("muster_erika_2")));

    const QDate monday(2026, 11, 9);
    Session s;
    s.day = 1;
    s.number = 2;
    s.from = QTime(15, 30);
    s.to = QTime(17, 30);
    Entry e1;
    e1.exercise = 8;
    e1.steps = {{13, 4, 3, 0}, {15, 3, 2, 0}};
    Entry e2;
    e2.kind = Entry::ExerciseText;
    e2.exercise = 32;
    e2.text = QStringLiteral("4x8");
    Entry e3;
    e3.kind = Entry::FreeText;
    e3.text = QStringLiteral("Dehnen");
    s.entries = {e1, e2, e3};
    QVERIFY(Database::saveSession(id, monday, Variant::Plan, s));

    Week w = Database::loadWeek(id, monday, Variant::Plan);
    QCOMPARE(w.sessions.size(), 1);
    const Session &l = w.sessions[0];
    QCOMPARE(l.entries.size(), 3);
    QCOMPARE(l.entries[0].steps, e1.steps);
    QCOMPARE(l.entries[1].text, QStringLiteral("4x8"));
    QCOMPARE(l.entries[2].kind, Entry::FreeText);
    QCOMPARE(l.to, QTime(17, 30));

    // Shorter list replaces the old one.
    s.entries = {e1};
    QVERIFY(Database::saveSession(id, monday, Variant::Plan, s));
    QCOMPARE(Database::loadWeek(id, monday, Variant::Plan).sessions[0].entries.size(), 1);

    QVERIFY(Database::saveWeekNote(id, monday, Variant::Plan, QStringLiteral("leicht"), true));
    w = Database::loadWeek(id, monday, Variant::Plan);
    QCOMPARE(w.note, QStringLiteral("leicht"));
    QVERIFY(w.injured);
    QVERIFY(Database::loadWeek(id, monday, Variant::Actual).note.isEmpty());
}

void TestCore::copyWeek()
{
    const QString id = QStringLiteral("muster_erika");
    const QDate from(2026, 11, 9), to(2026, 11, 16);
    QCOMPARE(Database::copyWeek(id, from, Variant::Plan, id, to, Variant::Plan), 1);
    const Week w = Database::loadWeek(id, to, Variant::Plan);
    QCOMPARE(w.sessions.size(), 1);
    QCOMPARE(w.sessions[0].entries[0].exercise, 8);

    QVERIFY(Database::removeSession(id, to, Variant::Plan, 1, 2));
    QVERIFY(Database::loadWeek(id, to, Variant::Plan).sessions.isEmpty());
}

void TestCore::weekSummary()
{
    Week w;
    Session s1;
    s1.day = 1;
    Entry a;
    a.exercise = 8; // group 2
    a.steps = {{13, 4, 3, 0}, {15, 3, 2, 0}};
    Entry b;
    b.exercise = 19; // group 5
    b.steps = {{20, 3, 2, 0}};
    Entry c;
    c.exercise = 31; // general, not part of K1-7
    c.steps = {{30, 10, 3, 0}};
    s1.entries = {a, b, c};
    Session s2;
    s2.day = 3;
    s2.entries = {a};
    w.sessions = {s1, s2};

    const WeekSummary sum = w.summary();
    QCOMPARE(sum.groups.size(), 7);
    QCOMPARE(sum.perExercise.value(8).wh, 36);
    QCOMPARE(sum.perExercise.value(8).bwRepsSets(), QStringLiteral("3/4"));
    QCOMPARE(sum.groups[1].stats.wh, 36);
    QCOMPARE(sum.groups[4].stats.wh, 6);
    QCOMPARE(sum.groups1to7.wh, 42);
    QCOMPARE(sum.groups1to5.wh, 42);
    QVERIFY(sum.perExercise.contains(31));
}

static Week exerciseTestWeek()
{
    Week w;
    Session mo;
    mo.day = 1;
    mo.number = 2;
    mo.from = QTime(15, 30);
    mo.to = QTime(17, 30);
    Entry a;
    a.exercise = 8;
    a.steps = {{13, 4, 3, 0}};
    Entry b;
    b.exercise = 19;
    b.steps = {{40, 3, 3, 0}};
    Entry t;
    t.kind = Entry::ExerciseText;
    t.exercise = 8; // a text line with the same number is not a weight row
    mo.entries = {a, b, t, a};
    Session mi;
    mi.day = 3;
    mi.number = 2;
    mi.entries = {b, a};
    w.sessions = {mi, mo}; // not sorted on purpose
    return w;
}

void TestCore::exerciseWeekRows()
{
    const QList<ExerciseRow> rows = ExerciseWeek::rows(exerciseTestWeek(), 8);
    QCOMPARE(rows.size(), 3);
    QCOMPARE(rows[0].day, 1);
    QCOMPARE(rows[0].origIndex, 0);
    QCOMPARE(rows[1].origIndex, 3);
    QCOMPARE(rows[2].day, 3);
    QCOMPARE(rows[2].origIndex, 1);
}

void TestCore::exerciseWeekApply()
{
    Week w = exerciseTestWeek();
    QList<ExerciseRow> rows = ExerciseWeek::rows(w, 8);
    rows[0].steps = {{15, 3, 2, 0}};  // changed in place
    rows.removeAt(1);                 // Monday's second line removed
    rows[1].day = 5;                  // Wednesday's line moved to Friday 1st session
    rows[1].number = 1;
    ExerciseRow added;
    added.day = 6;
    added.number = 2;
    added.steps = {{20, 2, 2, 0}};
    rows.append(added);               // new on Saturday 2nd session

    const QList<QPair<int, int>> touched = ExerciseWeek::apply(w, 8, rows);
    QCOMPARE(touched.size(), 4);

    const Session *mo = w.session(1, 2);
    QCOMPARE(mo->entries.size(), 3); // the text line with number 8 stays
    QCOMPARE(mo->entries[0].steps, (QList<Step>{{15, 3, 2, 0}}));
    QCOMPARE(mo->entries[1].exercise, 19);
    QCOMPARE(mo->entries[2].kind, Entry::ExerciseText);

    QCOMPARE(w.session(3, 2)->entries.size(), 1);
    QCOMPARE(w.session(3, 2)->entries[0].exercise, 19);

    const Session *fr = w.session(5, 1);
    QVERIFY(fr);
    QCOMPARE(fr->entries.size(), 1);
    QCOMPARE(fr->entries[0].steps, (QList<Step>{{13, 4, 3, 0}}));

    const Session *sa = w.session(6, 2);
    QVERIFY(sa);
    QCOMPARE(sa->from, QTime(15, 30)); // times of another 2nd session
    QCOMPARE(sa->entries[0].exercise, 8);

    // Nothing changed: nothing touched
    Week same = exerciseTestWeek();
    QVERIFY(ExerciseWeek::apply(same, 8, ExerciseWeek::rows(same, 8)).isEmpty());
}

void TestCore::nextWeight()
{
    QCOMPARE(Steps::nextWeight(100, 2.5, 1), 102);
    QCOMPARE(Steps::nextWeight(102, 2.5, 1), 105);
    QCOMPARE(Steps::nextWeight(105, 2.5, 1), 107);
    QCOMPARE(Steps::nextWeight(105, 2.5, -1), 102);
    QCOMPARE(Steps::nextWeight(102, 2.5, -1), 100);
    QCOMPARE(Steps::nextWeight(100, 1.0, 1), 101);
    QCOMPARE(Steps::nextWeight(0, 2.5, -1), 0);
}

void TestCore::printWithAllOptions()
{
    Week w;
    w.monday = QDate(2026, 11, 9);
    w.note = QStringLiteral("Bemerkung");
    Session s;
    s.day = 1;
    s.number = 2;
    s.note = QStringLiteral("TE-Bemerkung");
    Entry e;
    e.exercise = 8;
    e.steps = {{13, 4, 3, 1}, {15, 3, 2, 0}};
    s.entries = {e};
    w.sessions = {s};
    WeekReport::Options o;
    o.weekNote = o.weekNoteCentered = o.figures = o.sessionNoteCentered = o.landscape = true;
    o.notation = WeekReport::Options::Slash;
    o.blankHeader = 2;
    o.blankPerSession = 3;
    o.blankAfterNote = 4;
    o.fontNormal = 12;
    o.sessionColor = QColor(QStringLiteral("#ffeeaa"));
    o.paper = QPageSize::A5;
    QCOMPARE(o.pageLayout().pageSize().id(), QPageSize::A5);
    QCOMPARE(o.pageLayout().orientation(), QPageLayout::Landscape);
    QCOMPARE(WeekReport::Options().pageLayout().pageSize().id(), QPageSize::A4);
    const QString path = m_dir.filePath(QStringLiteral("all.pdf"));
    QVERIFY(WeekReport::writePdf(path, w, {QStringLiteral("T"), QStringLiteral("V"), QStringLiteral("A B")}, o));
    QVERIFY(QFileInfo(path).size() > 1000);
}

// WinWoTA's own printouts: the 75 sample week plans of the BVDG's
// Rahmentrainingskonzeption 2019, Anhang IV (tests/fixtures/
// bvdg-rtk-2019-weeks.json). WH, MHG and BW of every exercise line, each
// exercise's figures for the week, the complexes K1 to K7, and K1-7 and
// K1-5 with the tonnage must come out as WinWoTA printed them.
void TestCore::bvdgSampleWeeks()
{
    QFile file(QStringLiteral(TEST_FIXTURES_DIR "/bvdg-rtk-2019-weeks.json"));
    QVERIFY(file.open(QIODevice::ReadOnly));
    const QJsonArray weeks = QJsonDocument::fromJson(file.readAll()).object().value(QLatin1String("weeks")).toArray();
    QCOMPARE(weeks.size(), 75);

    // Where the printout contradicts itself, these figures are left out.
    // U20 14/2018: exercise 12 on Tuesday (in combination with 5) has a
    // last step of 98 kg that its line counts in WH and MHG but not in BW,
    // and the week's figures leave out entirely. U20 11/2018: the week's
    // figures for exercise 1 have one rep fewer than its two lines. U17
    // 05/2017: the only tonnage ending exactly on 50 kg, 27,85 t, is shown
    // as 27,8 (half to even?), where every MHG half is rounded up.
    const QString u20a = QStringLiteral("Junioren u20 Musterplan 14/2018");
    const QString u20b = QStringLiteral("Junioren u20 Musterplan 11/2018");
    const QSet<QString> printErrors{
        u20a + QStringLiteral(" line 2/1 ex 12 BW"), u20a + QStringLiteral(" week ex 12 WH"),
        u20a + QStringLiteral(" week ex 12 MHG"), u20a + QStringLiteral(" week ex 12 BW"),
        u20a + QStringLiteral(" K2"), u20a + QStringLiteral(" K1-7 WH"), u20a + QStringLiteral(" K1-7 t"),
        u20a + QStringLiteral(" K1-5 WH"), u20a + QStringLiteral(" K1-5 t"),
        u20b + QStringLiteral(" week ex 1 WH"), u20b + QStringLiteral(" week ex 1 MHG"), u20b + QStringLiteral(" K1"),
        u20b + QStringLiteral(" K1-7 WH"), u20b + QStringLiteral(" K1-7 t"), u20b + QStringLiteral(" K1-5 WH"),
        u20b + QStringLiteral(" K1-5 t"),
        QStringLiteral("Jugend Sportsch u17 Musterplan 05/2017 K1-7 t"),
    };
    QStringList differences;
    QSet<QString> printErrorsSeen;
    int checks = 0;
    auto check = [&](const QString &key, const QVariant &ours, const QVariant &printed) {
        ++checks;
        if (ours == printed)
            return;
        if (printErrors.contains(key))
            printErrorsSeen.insert(key);
        else
            differences.append(QStringLiteral("%1: ours %2, printed %3").arg(key, ours.toString(), printed.toString()));
    };
    const QLocale de(QLocale::German);
    auto tons = [&](double kg) { return de.toString(kg / 1000.0, 'f', 1); };

    for (const QJsonValue &wv : weeks) {
        const QJsonObject w = wv.toObject();
        const QString tag = w.value(QLatin1String("plan")).toString() + QLatin1Char(' ')
                            + w.value(QLatin1String("week")).toString();
        Week week;
        for (const QJsonValue &sv : w.value(QLatin1String("sessions")).toArray()) {
            const QJsonObject so = sv.toObject();
            Session s;
            s.day = so.value(QLatin1String("day")).toInt();
            s.number = so.value(QLatin1String("number")).toInt();
            for (const QJsonValue &ev : so.value(QLatin1String("entries")).toArray()) {
                // [exercise, [[kg, reps, sets] ...], WH, MHG, BW]
                const QJsonArray e = ev.toArray();
                Entry entry;
                entry.exercise = e.at(0).toInt();
                for (const QJsonValue &stv : e.at(1).toArray()) {
                    const QJsonArray st = stv.toArray();
                    entry.steps.append(Step{st.at(0).toInt(), st.at(1).toInt(), st.at(2).toInt()});
                }
                const Stats stats = entry.stats();
                const QString key = QStringLiteral("%1 line %2/%3 ex %4").arg(tag).arg(s.day).arg(s.number).arg(entry.exercise);
                check(key + QStringLiteral(" WH"), stats.wh, e.at(2).toInt());
                check(key + QStringLiteral(" MHG"), stats.mhg, e.at(3).toInt());
                check(key + QStringLiteral(" BW"), stats.bw, e.at(4).toInt());
                s.entries.append(entry);
            }
            week.sessions.append(s);
        }
        const WeekSummary sum = week.summary();
        for (const QJsonValue &v : w.value(QLatin1String("weekly")).toArray()) {
            // [exercise, WH, MHG, BW, reps at BW]
            const QJsonArray x = v.toArray();
            const Stats st = sum.perExercise.value(x.at(0).toInt());
            const QString key = QStringLiteral("%1 week ex %2").arg(tag).arg(x.at(0).toInt());
            check(key + QStringLiteral(" WH"), st.wh, x.at(1).toInt());
            check(key + QStringLiteral(" MHG"), st.mhg, x.at(2).toInt());
            check(key + QStringLiteral(" BW"), st.bw, x.at(3).toInt());
            check(key + QStringLiteral(" SG"), st.bwReps, x.at(4).toInt());
        }
        const QJsonArray groups = w.value(QLatin1String("groups")).toArray();
        for (int g = 1; g <= 7; ++g)
            check(QStringLiteral("%1 K%2").arg(tag).arg(g), sum.groups[g - 1].stats.wh, groups.at(g - 1).toInt());
        for (const auto &[name, stats] : {std::pair{QStringLiteral("K1-7"), sum.groups1to7},
                                          std::pair{QStringLiteral("K1-5"), sum.groups1to5}}) {
            // [WH, MHG, tonnage in t as printed]
            const QJsonArray x = w.value(name == QLatin1String("K1-7") ? QLatin1String("k17") : QLatin1String("k15")).toArray();
            const QString key = tag + QLatin1Char(' ') + name;
            check(key + QStringLiteral(" WH"), stats.wh, x.at(0).toInt());
            check(key + QStringLiteral(" MHG"), stats.mhg, x.at(1).toInt());
            check(key + QStringLiteral(" t"), tons(stats.tonnage), x.at(2).toString());
        }
    }
    QVERIFY2(differences.isEmpty(), qPrintable(differences.join(QLatin1Char('\n'))));
    // Every exception still differs: none hides a figure that agrees now
    QCOMPARE(printErrorsSeen, printErrors);
    QVERIFY2(checks > 7000, qPrintable(QString::number(checks)));
}

// A report survives the way to QML and back, and a long table goes on
// over the next page
void TestCore::reportRoundTripAndPdf()
{
    Report::Document d;
    d.title = QStringLiteral("Abschnittsanalyse");
    d.heading(QStringLiteral("Mira – Woche 1/2029 bis 2/2029"));
    d.note(QStringLiteral("erste Zeile\nzweite Zeile"));
    QList<Report::Cells> rows{Report::cells({QStringLiteral("TÜ"), QStringLiteral("1."), QStringLiteral("2.")})};
    rows[0][2].muted = true;
    for (int i = 0; i < 120; ++i)
        rows.append(Report::Cells{Report::Cell{QStringLiteral("Übung %1").arg(i), true},
                                  Report::Cell{QString::number(i)}, Report::Cell{}});
    d.table(rows);

    const Report::Document back = Report::fromVariant(Report::toVariant(d));
    QCOMPARE(back.title, d.title);
    QCOMPARE(back.blocks.size(), 3);
    QCOMPARE(back.blocks[0].kind, Report::Block::Heading);
    QCOMPARE(back.blocks[1].text, d.blocks[1].text);
    QCOMPARE(back.blocks[2].rows.size(), 121);
    QVERIFY(back.blocks[2].rows[0][2].muted);
    QVERIFY(back.blocks[2].rows[5][0].bold);
    QVERIFY(!back.blocks[2].rows[5][1].bold);

    // As text for a spreadsheet: a line per heading, note line and table
    // row, the cells separated by tabs, a tab in a cell made a space
    Report::Document small;
    small.title = QStringLiteral("Gruppenanalyse");
    small.heading(QStringLiteral("Gesamtübersicht"));
    small.table({Report::cells({QStringLiteral("Sportler"), QStringLiteral("Wh/Wo")}),
                 Report::cells({QStringLiteral("Test,\tTina"), QStringLiteral("5,5")})});
    small.note(QStringLiteral("eins\nzwei"));
    QCOMPARE(Report::toText(small),
             QStringLiteral("Gruppenanalyse\nGesamtübersicht\nSportler\tWh/Wo\nTest, Tina\t5,5\n\neins\nzwei\n"));

    // As CSV for a German spreadsheet: semicolons, a cell holding one in
    // quotes, CR LF, UTF-8 with a byte order mark
    Report::Document csv;
    csv.title = QStringLiteral("Wettkämpfe");
    csv.table({Report::cells({QStringLiteral("Sportler"), QStringLiteral("KG")}),
               Report::cells({QStringLiteral("Test; \"Tina\""), QStringLiteral("64,5")})});
    QCOMPARE(Report::toCsv(csv),
             QByteArray("\xEF\xBB\xBF") + QStringLiteral("Wettkämpfe\r\nSportler;KG\r\n\"Test; \"\"Tina\"\"\";64,5\r\n\r\n").toUtf8());

    const QString path = m_dir.filePath(QStringLiteral("report.pdf"));
    {
        QPdfWriter writer(path);
        writer.setPageLayout(QPageLayout(QPageSize(QPageSize::A4), QPageLayout::Landscape,
                                         QMarginsF(10, 10, 10, 10), QPageLayout::Millimeter));
        Report::paint(&writer, back);
    }
    QFile pdf(path);
    QVERIFY(pdf.open(QIODevice::ReadOnly));
    const QByteArray bytes = pdf.readAll();
    // 120 rows do not fit on one landscape page
    QVERIFY(bytes.count("/Type /Page\n") >= 2);
}

void TestCore::exportRoundTrip()
{
    // A week with two sessions for an athlete
    Athlete a;
    a.lastName = QStringLiteral("Export");
    a.firstName = QStringLiteral("Emil");
    const QString id = Database::saveAthlete(a);
    const QDate monday(2026, 3, 2);
    Session s;
    s.day = 1;
    s.number = 2;
    s.from = QTime(15, 30);
    s.note = QStringLiteral("mit \"Anführungszeichen\"\nund Zeilenumbruch");
    Entry e;
    e.exercise = 3;
    e.steps = {{50, 3, 2, 0}};
    Entry t;
    t.kind = Entry::FreeText;
    t.text = QStringLiteral("Dehnen €");
    s.entries = {e, t};
    QVERIFY(Database::saveSession(id, monday, Variant::Plan, s));
    s.day = 3;
    QVERIFY(Database::saveSession(id, monday, Variant::Plan, s));

    BakExport::Result all;
    const QString full = BakExport::exportText({BakExport::Filter::All, {}, {}, {}, {}}, &all);
    QVERIFY(all.ok);
    QVERIFY(all.rows.value(QStringLiteral("session_entries")) >= 4);

    BakExport::Filter weeks;
    weeks.mode = BakExport::Filter::AthleteWeeks;
    weeks.athleteId = id;
    weeks.fromMonday = monday;
    weeks.toMonday = monday;
    BakExport::Result one;
    BakExport::exportText(weeks, &one);
    QCOMPARE(one.rows.value(QStringLiteral("sessions")), 2);
    QCOMPARE(one.rows.value(QStringLiteral("athletes")), 1);

    // Remove Wednesday, then export the changes since just before
    QTest::qWait(1100); // timestamps have whole seconds; keep earlier changes out
    const QDateTime since = QDateTime::currentDateTime();
    QVERIFY(Database::removeSession(id, monday, Variant::Plan, 3, 2));
    BakExport::Result changed;
    const QString delta = BakExport::exportText({BakExport::Filter::ChangedSince, since, {}, {}, {}}, &changed);
    QCOMPARE(changed.deleted.value(QStringLiteral("sessions")), 1);
    QCOMPARE(changed.deleted.value(QStringLiteral("session_entries")), 2);

    // Into a second database: the full export, then the changes
    const QString first = Database::path();
    Database::close();
    QVERIFY(Database::open(m_dir.filePath(QStringLiteral("other.sqlite"))));
    BakImport::Result r = BakImport::importText(BakImport::decode(BakExport::encode(full)));
    QVERIFY2(r.ok && r.errors.isEmpty(), qPrintable(r.summary()));
    Week w = Database::loadWeek(id, monday, Variant::Plan);
    QCOMPARE(w.sessions.size(), 2);
    QCOMPARE(w.sessions[0].note, s.note);
    QCOMPARE(w.sessions[0].entries[1].text, QStringLiteral("Dehnen €"));

    r = BakImport::importText(BakImport::decode(BakExport::encode(delta)));
    QVERIFY2(r.ok && r.errors.isEmpty(), qPrintable(r.summary()));
    w = Database::loadWeek(id, monday, Variant::Plan);
    QCOMPARE(w.sessions.size(), 1);
    QCOMPARE(w.sessions[0].day, 1);

    Database::close();
    QVERIFY(Database::open(first));
}

void TestCore::attributesWithHistory()
{
    const QString id = QStringLiteral("muster_erika");
    const QDate jan(2026, 1, 1), jun(2026, 6, 1);
    QVERIFY(Database::setAttribute(id, QStringLiteral("Kader"), QStringLiteral("NK2"), jan));
    QVERIFY(Database::setAttribute(id, QStringLiteral("Kader"), QStringLiteral("NK1"), jun));
    QList<Database::InfoRecord> r = Database::infoRecords(id, QStringLiteral("Kader"));
    QCOMPARE(r.size(), 2);
    QCOMPARE(r[0].to, jun.addDays(-1));
    QVERIFY(!r[1].to.isValid());
    QCOMPARE(Database::infoAt(r, QDate(2026, 3, 1))->text, QStringLiteral("NK2"));
    QCOMPARE(Database::infoAt(r, QDate(2026, 7, 1))->text, QStringLiteral("NK1"));

    // Same value again: nothing changes; a change on the start day replaces it
    QVERIFY(Database::setAttribute(id, QStringLiteral("Kader"), QStringLiteral("NK1"), jun));
    QVERIFY(Database::setAttribute(id, QStringLiteral("Kader"), QStringLiteral("OK"), jun));
    r = Database::infoRecords(id, QStringLiteral("Kader"));
    QCOMPARE(r.size(), 2);
    QCOMPARE(r[1].text, QStringLiteral("OK"));

    // Empty ends the current record
    QVERIFY(Database::setAttribute(id, QStringLiteral("Kader"), QString(), QDate(2026, 9, 1)));
    r = Database::infoRecords(id, QStringLiteral("Kader"));
    QCOMPARE(r[1].to, QDate(2026, 8, 31));
    QVERIFY(!Database::infoAt(r, QDate(2026, 10, 1)));
    QCOMPARE(Database::infoValues(QStringLiteral("Kader")),
             (QStringList{QStringLiteral("NK2"), QStringLiteral("OK")}));

    // The whole history at once (Erfassung): a kept record keeps its time
    // of day, as imported records have one; a left-out one goes
    Database::InfoRecord imported;
    imported.athleteId = id;
    imported.art = QStringLiteral("Verein");
    imported.from = jan;
    imported.time = QTime(8, 30);
    imported.text = QStringLiteral("SV Alt");
    QVERIFY(Database::saveInfoRecord(imported));
    Database::InfoRecord changed;
    changed.from = jan;
    changed.text = QStringLiteral("SV Neu");
    Database::InfoRecord added;
    added.from = jun;
    added.text = QStringLiteral("TSV");
    QVERIFY(Database::replaceInfoRecords(id, QStringLiteral("Verein"), {changed, added}));
    r = Database::infoRecords(id, QStringLiteral("Verein"));
    QCOMPARE(r.size(), 2);
    QCOMPARE(r[0].time, QTime(8, 30));
    QCOMPARE(r[0].text, QStringLiteral("SV Neu"));
    QVERIFY(Database::replaceInfoRecords(id, QStringLiteral("Verein"), {added}));
    r = Database::infoRecords(id, QStringLiteral("Verein"));
    QCOMPARE(r.size(), 1);
    QCOMPARE(r[0].text, QStringLiteral("TSV"));
}

void TestCore::competitions()
{
    Competition c;
    c.athleteId = QStringLiteral("muster_erika");
    c.date = QDate(2026, 5, 9);
    c.type = 1;
    c.bodyWeight = 58.4;
    c.snatch[0] = 70; c.snatch[1] = -73; c.snatch[2] = 73;
    c.cleanJerk[0] = 88; c.cleanJerk[1] = -92; c.cleanJerk[2] = -92;
    QCOMPARE(c.bestSnatch(), 73);
    QCOMPARE(c.bestCleanJerk(), 88);
    QCOMPARE(c.total(), 161);
    Competition bombOut = c;
    bombOut.cleanJerk[0] = -88;
    QCOMPARE(bombOut.total(), 0);

    QVERIFY(Competitions::save(c));
    Competition d = c;
    d.date = QDate(2026, 3, 1);
    d.snatch[2] = 75;
    QVERIFY(Competitions::save(d));
    Competition e = c;
    e.date = QDate(2026, 10, 3);
    e.cleanJerk[1] = 95;
    QVERIFY(Competitions::save(e));

    const QList<Competition> all = Competitions::forAthlete(c.athleteId);
    QCOMPARE(all.size(), 3);
    QCOMPARE(all.first().date, e.date); // newest first
    QVERIFY(Competitions::inWeek(c.athleteId, QDate(2026, 5, 4)));
    QVERIFY(!Competitions::inWeek(c.athleteId, QDate(2026, 5, 11)));

    // Per half year: March and May together (best 75 + 88), October alone
    const QList<Competitions::Point> half = Competitions::bestResults(all, 1);
    QCOMPARE(half.size(), 2);
    QCOMPARE(half[0].label, QStringLiteral("1/2026"));
    QCOMPARE(half[0].total, 163);
    QCOMPARE(half[1].total, 168);
    QCOMPARE(Competitions::bestResults(all, 0).size(), 3);
    QCOMPARE(Competitions::bestResults(all, 2).size(), 1);

    // Reference totals by age and weight class
    QSqlQuery q;
    QVERIFY(q.exec(QStringLiteral("INSERT INTO reference_totals (sex, age_class, weight_class, weight_class_name, total) VALUES"
                                  " (1, 16, 55, '-55', 120), (1, 16, 59, '-59', 130), (1, 16, 60, '+59', 140),"
                                  " (1, 18, 59, '-59', 150)")));
    QCOMPARE(Competitions::norm(Sex::Female, 16, 58.4), 130);
    QCOMPARE(Competitions::norm(Sex::Female, 17, 54.0), 120);   // age class 16 up to 17
    QCOMPARE(Competitions::norm(Sex::Female, 16, 70.0), 140);   // above the last limit: "+" class
    QCOMPARE(Competitions::norm(Sex::Female, 25, 58.0), 150);   // oldest class
    QCOMPARE(Competitions::norm(Sex::Male, 16, 58.0), 0);     // no table for men here

    QVERIFY(Competitions::remove(c.athleteId, c.date, c.time));
    QCOMPARE(Competitions::forAthlete(c.athleteId).size(), 2);
}

void TestCore::planningBasics()
{
    QCOMPARE(Planning::roundToStep(101.2, 2.5), 100);
    QCOMPARE(Planning::roundToStep(101.3, 2.5), 102); // 102.5 as whole kg
    QCOMPARE(Planning::roundToStep(101.4, 1.0), 101);

    bool ok = false;
    QList<Step> s = Planning::parseStepsText(QStringLiteral("80/3/2  85/3 90"), &ok);
    QVERIFY(ok);
    QCOMPARE(s, (QList<Step>{{80, 3, 2, 0}, {85, 3, 1, 0}, {90, 1, 1, 0}}));
    QCOMPARE(Planning::stepsText(s), QStringLiteral("80/3/2 85/3/1 90/1/1"));
    Planning::parseStepsText(QStringLiteral("80/x"), &ok);
    QVERIFY(!ok);

    Maz m;
    m.name = QStringLiteral("Vorbereitung DM");
    m.shortName = QStringLiteral("DM27");
    m.sex = Sex::Female;
    m.from = QDate(2027, 3, 1);
    m.to = QDate(2027, 4, 26);
    m.buildUp = m.from;
    m.peakPhase = QDate(2027, 4, 5);
    const QString id = Planning::saveMaz(m);
    QVERIFY(!id.isEmpty());
    QCOMPARE(Planning::maz(id).weeks(), 9);
    QVERIFY(Planning::saveMazAthlete({id, QStringLiteral("muster_erika"), 59, 80, 100, 78, 98, {}}));
    QCOMPARE(Planning::mazAthletes(id).size(), 1);
    QCOMPARE(Planning::mazForAthlete(QStringLiteral("muster_erika")).size(), 1);

    // Targets and meta, copied to other weeks
    const QString owner = QStringLiteral("muster_erika");
    QVERIFY(Planning::setTarget(owner, {QDate(2027, 3, 1), 1, 40, 60, 70, 2, 2}));
    QVERIFY(Planning::setTarget(owner, {QDate(2027, 3, 8), -2, 80, 0, 0, 0, 0}));
    QVERIFY(Planning::setMeta(owner, {QDate(2027, 3, 1), 3, QStringLiteral("WK"), QStringLiteral("leicht")}));
    QVERIFY(Planning::setPlannedSteps(owner, 1, QDate(2027, 3, 1), {{60, 3, 2, 0}}));
    QVERIFY(Planning::copyPlan(owner, QDate(2027, 3, 1), owner, QDate(2027, 6, 7), 2));
    const QList<WeekTarget> copied = Planning::targets(owner, QDate(2027, 6, 7), QDate(2027, 6, 14));
    QCOMPARE(copied.size(), 2);
    QCOMPARE(copied[0].monday, QDate(2027, 6, 7));
    QCOMPARE(copied[0].bw, 70);
    QCOMPARE(copied[1].exercise, -2);
    QCOMPARE(Planning::meta(owner, QDate(2027, 6, 7), QDate(2027, 6, 7)).value(0).position, QStringLiteral("WK"));
    QCOMPARE(Planning::plannedSteps(owner, 1, QDate(2027, 6, 7), QDate(2027, 6, 7)).value(QDate(2027, 6, 7)),
             (QList<Step>{{60, 3, 2, 0}}));
    // An empty target removes it
    QVERIFY(Planning::setTarget(owner, {QDate(2027, 6, 14), -2, 0, 0, 0, 0, 0}));
    QCOMPARE(Planning::targets(owner, QDate(2027, 6, 7), QDate(2027, 6, 14)).size(), 1);
}

void TestCore::itpFromRo()
{
    const QString id = Planning::mazList().first().id; // from planningBasics
    const QString ro = Planning::roOwner(id);
    // RO: snatch WKÜ at 75/85 %, Kniebeuge vorn (clean & jerk side) at 90 %
    QVERIFY(Planning::setTarget(ro, {QDate(2027, 3, 1), 1, 30, 75, 85, 2, 2}));
    QVERIFY(Planning::setTarget(ro, {QDate(2027, 3, 1), 19, 20, 90, 0, 0, 0}));
    QVERIFY(Planning::setPlannedSteps(ro, 1, QDate(2027, 3, 1), {{70, 3, 2, 0}, {80, 2, 2, 0}}));
    QVERIFY(Planning::setMeta(ro, {QDate(2027, 3, 8), 4, QStringLiteral("WK"), {}}));

    QVERIFY(Planning::itpFromRo(id, QStringLiteral("muster_erika"), 2.5));
    const QList<WeekTarget> t = Planning::targets(QStringLiteral("muster_erika"), QDate(2027, 3, 1), QDate(2027, 3, 1));
    QCOMPARE(t.size(), 2);
    // Targets: snatch 80, clean & jerk 100
    QCOMPARE(t[0].exercise, 1);
    QCOMPARE(t[0].wh, 30);
    QCOMPARE(t[0].mhg, 60);   // 75 % of 80
    QCOMPARE(t[0].bw, 67);    // 85 % of 80 = 68 -> 67.5 -> 67
    QCOMPARE(t[1].mhg, 90);   // 90 % of 100
    const QList<Step> steps = Planning::plannedSteps(QStringLiteral("muster_erika"), 1, QDate(2027, 3, 1),
                                                     QDate(2027, 3, 1)).value(QDate(2027, 3, 1));
    QCOMPARE(steps, (QList<Step>{{55, 3, 2, 0}, {65, 2, 2, 0}})); // 56 -> 55, 64 -> 65
    QCOMPARE(Planning::meta(QStringLiteral("muster_erika"), QDate(2027, 3, 8), QDate(2027, 3, 8)).value(0).load, 4);

    // Actual figures of a group from the week plan
    Session s;
    s.day = 2;
    Entry a;
    a.exercise = 1; // K1
    a.steps = {{50, 3, 2, 0}};
    Entry b;
    b.exercise = 3; // K1 as well
    b.steps = {{60, 2, 2, 0}};
    s.entries = {a, b};
    QVERIFY(Database::saveSession(QStringLiteral("muster_erika"), QDate(2027, 3, 1), Variant::Plan, s));
    const QMap<QDate, Stats> k1 = Planning::actualWeekly(QStringLiteral("muster_erika"), Variant::Plan, -1,
                                                         QDate(2027, 3, 1), QDate(2027, 3, 8));
    QCOMPARE(k1.value(QDate(2027, 3, 1)).wh, 10);
    QVERIFY(!k1.contains(QDate(2027, 3, 8)));

    QVERIFY(Planning::removeMaz(id));
    QVERIFY(Planning::targets(ro, QDate(2027, 1, 1), QDate(2027, 12, 31)).isEmpty());
}

// A plan scaled by a factor: the chosen weeks, values and exercises;
// WH whole (one at least), weights to the step, a complex's WH only
void TestCore::scalePlan()
{
    const QString owner = QStringLiteral("scale_owner");
    const QDate w1(2028, 1, 3), w2(2028, 1, 10), w3(2028, 1, 17);
    QVERIFY(Planning::setTarget(owner, {w1, 1, 20, 70, 80, 2, 3}));
    QVERIFY(Planning::setTarget(owner, {w1, 19, 1, 90, 100, 0, 0}));
    QVERIFY(Planning::setTarget(owner, {w1, -1, 70, 0, 0, 0, 0}));
    QVERIFY(Planning::setTarget(owner, {w2, 1, 16, 72, 84, 0, 0}));
    QVERIFY(Planning::setTarget(owner, {w3, 1, 10, 75, 90, 0, 0}));

    // Weeks 1 and 2, snatch and K1, all values by 90 % on 2.5 kg
    QCOMPARE(Planning::scaleTargets(owner, w1, w2, {1, -1},
                                    Planning::ScaleWh | Planning::ScaleMhg | Planning::ScaleBw, 0.9, 2.5),
             3);
    auto get = [&](const QDate &m, int e) {
        for (const WeekTarget &t : Planning::targets(owner, m, m))
            if (t.exercise == e)
                return t;
        return WeekTarget();
    };
    WeekTarget t = get(w1, 1);
    QCOMPARE(t.wh, 18);
    QCOMPARE(t.mhg, 62);  // 63 -> 62.5 -> 62
    QCOMPARE(t.bw, 72);   // 72
    QCOMPARE(t.bwReps, 2);
    QCOMPARE(t.bwSets, 3);
    QCOMPARE(get(w1, -1).wh, 63);
    QCOMPARE(get(w2, 1).bw, 75);  // 75.6 -> 75
    // Not chosen: Kniebeuge vorn, week 3
    QCOMPARE(get(w1, 19).bw, 100);
    QCOMPARE(get(w3, 1).bw, 90);

    // BW only, in whole percent; one WH stays one
    QCOMPARE(Planning::scaleTargets(owner, w1, w1, {19}, Planning::ScaleWh | Planning::ScaleBw, 0.55, 1), 1);
    t = get(w1, 19);
    QCOMPARE(t.wh, 1);
    QCOMPARE(t.mhg, 90);
    QCOMPARE(t.bw, 55);
    // Nothing to change, and what makes no sense
    QCOMPARE(Planning::scaleTargets(owner, w1, w3, {19}, Planning::ScaleMhg, 1.0, 1), 0);
    QCOMPARE(Planning::scaleTargets(owner, w2, w1, {1}, Planning::ScaleBw, 0.9, 1), -1);
    QCOMPARE(Planning::scaleTargets(owner, w1, w2, {1}, 0, 0.9, 1), -1);
    QCOMPARE(Planning::scaleTargets(QString(), w1, w2, {1}, Planning::ScaleBw, 0.9, 1), -1);
}

// The RTK's Tr.-Wo.: weeks to the main competition, the last HWK of the
// plan, else of the RO, else the MAZ's last week
void TestCore::countdown()
{
    Maz z;
    z.name = QStringLiteral("Countdown");
    z.from = QDate(2029, 1, 1);
    z.to = QDate(2029, 3, 26); // 13 weeks
    z.id = Planning::saveMaz(z);
    QVERIFY(!z.id.isEmpty());
    const QString athlete = QStringLiteral("countdown_athlete");

    // No HWK: the MAZ's last week is the main competition
    QDate main = Planning::mainCompetitionWeek(z, athlete);
    QCOMPARE(main, z.to);
    QCOMPARE(Planning::trainingWeek(z, main, z.from), 13);
    QCOMPARE(Planning::trainingWeek(z, main, z.to), 1);
    QCOMPARE(Planning::trainingWeek(z, main, z.from.addDays(-7)), 0);
    QCOMPARE(Planning::trainingWeek(z, main, z.to.addDays(7)), 0);

    // An HWK in the RO, week 11: the weeks after it count 0
    QVERIFY(Planning::setMeta(Planning::roOwner(z.id), {QDate(2029, 3, 12), 0, QStringLiteral("HWK"), {}}));
    main = Planning::mainCompetitionWeek(z, athlete);
    QCOMPARE(main, QDate(2029, 3, 12));
    QCOMPARE(Planning::trainingWeek(z, main, z.from), 11);
    QCOMPARE(Planning::trainingWeek(z, main, z.to), 0);
    // The athlete's own HWK (any case) goes first, the last of two
    QVERIFY(Planning::setMeta(athlete, {QDate(2029, 2, 5), 0, QStringLiteral("hwk"), {}}));
    QVERIFY(Planning::setMeta(athlete, {QDate(2029, 2, 19), 0, QStringLiteral(" HWK"), {}}));
    QVERIFY(Planning::setMeta(athlete, {QDate(2029, 2, 26), 0, QStringLiteral("WK"), {}}));
    QCOMPARE(Planning::mainCompetitionWeek(z, athlete), QDate(2029, 2, 19));
    // Without a MAZ, nothing
    QCOMPARE(Planning::mainCompetitionWeek(Maz(), athlete), QDate());
    QCOMPARE(Planning::trainingWeek(Maz(), QDate(), z.from), 0);
    QVERIFY(Planning::removeMaz(z.id));
}

void TestCore::sectionAnalysis()
{
    QCOMPARE(Analysis::slope({1, 2, 3}), 1.0);
    QCOMPARE(Analysis::slope({10, Analysis::none, 30}), 10.0);
    QVERIFY(std::isnan(Analysis::slope({5})));

    Athlete a;
    a.lastName = QStringLiteral("Analyse");
    a.firstName = QStringLiteral("Mira");
    const QString id = Database::saveAthlete(a);
    const QDate w1(2028, 1, 3), w2 = w1.addDays(7), w3 = w1.addDays(14);
    auto session = [&](const QDate &monday, int day, QList<Entry> entries) {
        Session s;
        s.day = day;
        s.entries = entries;
        QVERIFY(Database::saveSession(id, monday, Variant::Actual, s));
    };
    Entry snatch;
    snatch.exercise = 1;
    snatch.steps = {{60, 3, 2, 0}, {70, 2, 2, 1}};   // 10 Wh, 640 kg, 4 sets
    Entry squat;
    squat.exercise = 19;
    squat.steps = {{100, 5, 1, 0}};                    // group K5
    session(w1, 1, {snatch, squat});
    session(w1, 3, {snatch});
    Entry heavier = snatch;
    heavier.steps = {{80, 1, 2, 0}};                   // 2 Wh
    session(w2, 2, {heavier});
    session(w3, 2, {snatch});

    Analysis::Params p;
    p.athleteId = id;
    p.from = w1;
    p.weeks = 3;
    p.includeCompetitionWeeks = true;
    Analysis::Section s = Analysis::section(p);
    QCOMPARE(s.countedWeeks, 3);
    QCOMPARE(s.sessions, 4.0);
    QCOMPARE(s.rows.size(), 2);
    const Analysis::Row &r = s.rows[0];
    QCOMPARE(r.key, 1);
    QCOMPARE(r.wh, (QList<double>{20, 2, 10}));
    QCOMPARE(r.whTotal, 32.0);
    QCOMPARE(r.whPerWeek, 32.0 / 3);
    QCOMPARE(r.bw, (QList<double>{70, 80, 70}));
    QCOMPARE(r.bwMax, 80.0);
    QCOMPARE(r.mhgPeriod, (1280 + 160 + 640) / 32.0);
    QCOMPARE(r.failed, 3.0);                            // UG counts per weight step, three steps
    // The 30 heaviest of 32 reps leave out two 60 kg reps
    QCOMPARE(r.mhgTop30, (2 * 80 + 12 * 70 + 16 * 60) / 30.0);
    QCOMPARE(r.sgMean, 32.0 / 14);                      // 8 + 2 + 4 sets

    // A competition in week 2 leaves that week out
    Competition c;
    c.athleteId = id;
    c.date = w2.addDays(5);
    c.snatch[0] = 70;
    QVERIFY(Competitions::save(c));
    p.includeCompetitionWeeks = false;
    s = Analysis::section(p);
    QCOMPARE(s.countedWeeks, 2);
    QVERIFY(s.excluded[1]);
    QCOMPARE(s.rows[0].whTotal, 30.0);
    QCOMPARE(s.rows[0].bwMax, 70.0);

    // Groups and percent of the MAZ targets
    Maz m;
    m.name = QStringLiteral("Analyse");
    m.from = w1;
    m.to = w3;
    const QString mazId = Planning::saveMaz(m);
    QVERIFY(Planning::saveMazAthlete({mazId, id, 0, 100, 140, 0, 0, {}}));
    p.groups = true;
    p.reference = Analysis::Reference::MazTarget;
    p.mazId = mazId;
    s = Analysis::section(p);
    QCOMPARE(s.rows.size(), 2);
    QCOMPARE(s.rows[0].key, -1);
    QCOMPARE(s.rows[1].key, -5);
    QVERIFY(s.rows[0].percent);
    QCOMPARE(s.rows[0].bwMax, 70.0 * 100 / 120);       // groups: mean of both targets

    // Reps per weight
    const Analysis::LoadTable t = Analysis::loadTable(id, Variant::Actual, 1, w1, 3);
    QCOMPARE(t.kg, (QList<int>{80, 70, 60}));
    QCOMPARE(t.reps[1], (QList<int>{8, 0, 4}));
    QCOMPARE(t.totals[2], 18);
    QCOMPARE(Analysis::sessionCounts(id, w1, 3, Variant::Actual), (QList<int>{2, 1, 1}));
}

QTEST_MAIN(TestCore)
void TestCore::compareVersions()
{
    using Update::compareVersions;
    QCOMPARE(compareVersions(QStringLiteral("0.2.0"), QStringLiteral("0.2.0")), 0);
    QCOMPARE(compareVersions(QStringLiteral("v0.2.0"), QStringLiteral("0.2.0")), 0);
    QCOMPARE(compareVersions(QStringLiteral("0.10.0"), QStringLiteral("0.9.3")), 1);
    QCOMPARE(compareVersions(QStringLiteral("0.2"), QStringLiteral("0.2.1")), -1);
    QCOMPARE(compareVersions(QStringLiteral("0.2"), QStringLiteral("0.2.0")), 0);
    QCOMPARE(compareVersions(QStringLiteral("1.0.0-rc.1"), QStringLiteral("1.0.0")), -1);
    QCOMPARE(compareVersions(QStringLiteral("1.0.0"), QStringLiteral("1.0.0-rc.2")), 1);
    QCOMPARE(compareVersions(QStringLiteral("1.0.0-rc.1"), QStringLiteral("1.0.0-rc.2")), -1);
    QCOMPARE(compareVersions(QStringLiteral("1.0.0-rc.1"), QStringLiteral("0.9.0")), 1);
}

void TestCore::times()
{
    QCOMPARE(Times::parse(QStringLiteral("15:30")), QTime(15, 30));
    QCOMPARE(Times::parse(QStringLiteral(" 9:05 ")), QTime(9, 5));
    QCOMPARE(Times::parse(QStringLiteral("15:30:00")), QTime(15, 30));
    QVERIFY(!Times::parse(QString()).isValid());
    QVERIFY(!Times::parse(QStringLiteral("25:00")).isValid());
    QCOMPARE(Times::text(QTime(9, 5)), QStringLiteral("09:05"));
    QCOMPARE(Times::text(QTime()), QString());
    QCOMPARE(Times::stored(QTime(8, 30)), QStringLiteral("08:30:00"));
    QCOMPARE(Times::optional(QTime(0, 0)), QString());
    QCOMPARE(Times::optional(QTime(8, 30)), QStringLiteral("08:30"));
}

// Change stamps are local time in whole seconds; a stamp with a time zone
// is the same moment in local time
void TestCore::stamps()
{
    const QDateTime t(QDate(2024, 5, 2), QTime(9, 0));
    QCOMPARE(Database::stampTime(QStringLiteral("2024-05-02 09:00:00")), t);
    QCOMPARE(Database::stampTime(QStringLiteral("2024-05-02T09:00:00")), t);
    QCOMPARE(Database::stampText(t), QStringLiteral("2024-05-02 09:00:00"));
    const QDateTime utc(QDate(2024, 5, 2), QTime(9, 0), QTimeZone::UTC);
    QCOMPARE(Database::stampText(Database::stampTime(QStringLiteral("2024-05-02T09:00:00Z"))),
             Database::stampText(utc.toLocalTime()));
    const QDateTime plus2(QDate(2024, 5, 2), QTime(9, 0), QTimeZone::fromSecondsAheadOfUtc(7200));
    QCOMPARE(Database::stampText(Database::stampTime(QStringLiteral("2024-05-02T09:00:00+02:00"))),
             Database::stampText(plus2.toLocalTime()));
    QVERIFY(!Database::stampTime(QStringLiteral("gestern")).isValid());
    QCOMPARE(Database::now().time().msec(), 0);
}

void TestCore::parseRelease()
{
    const QByteArray json = R"({
        "tag_name": "v0.3.0", "draft": false, "prerelease": false,
        "html_url": "https://github.com/x/y/releases/tag/v0.3.0", "body": "## Neu",
        "assets": [
            {"name": "trainingsplaner-windows-x64.zip", "size": 1,
             "browser_download_url": "https://example.org/zip"},
            {"name": "trainingsplaner-windows-x64-setup.exe", "size": 1234,
             "digest": "sha256:00ff10",
             "browser_download_url": "https://example.org/setup.exe"},
            {"name": "trainingsplaner-macos.dmg", "size": 5,
             "browser_download_url": "https://example.org/dmg"}
        ]})";
    const Update::Release w = Update::parseRelease(json, Update::Platform::Windows);
    QVERIFY(w.isValid());
    QCOMPARE(w.version, QStringLiteral("0.3.0"));
    QCOMPARE(w.notes, QStringLiteral("## Neu"));
    QCOMPARE(w.asset, QUrl(QStringLiteral("https://example.org/setup.exe")));
    QCOMPARE(w.size, 1234);
    QCOMPARE(w.sha256, QByteArray::fromHex("00ff10"));

    const Update::Release m = Update::parseRelease(json, Update::Platform::MacOS);
    QCOMPARE(m.asset, QUrl(QStringLiteral("https://example.org/dmg")));
    QVERIFY(m.sha256.isEmpty());
    // No AppImage in this release: the release page is the way
    const Update::Release l = Update::parseRelease(json, Update::Platform::Linux);
    QVERIFY(l.isValid());
    QVERIFY(l.asset.isEmpty());

    QVERIFY(!Update::parseRelease(R"({"tag_name": "nightly", "prerelease": true})", Update::Platform::Windows).isValid());
    QVERIFY(!Update::parseRelease(R"({"tag_name": "nightly"})", Update::Platform::Windows).isValid());
    QVERIFY(!Update::parseRelease("not json", Update::Platform::Windows).isValid());
}

#include "tst_core.moc"
