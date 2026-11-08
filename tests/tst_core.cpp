#include "bakimport.h"
#include "database.h"
#include "exerciseweek.h"
#include "model.h"
#include "steps.h"
#include "weekreport.h"

#include <QFileInfo>

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
    void statsMatchOldProgram();
    void entryEncoding();
    void weekLabels();
    void bakParser();
    void importAndMerge();
    void saveAndLoadSession();
    void copyWeek();
    void weekSummary();
    void exerciseWeekRows();
    void nextWeight();
    void printWithAllOptions();
    void exerciseWeekApply();

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
    QCOMPARE(r.tables.value(QStringLiteral("te_ueb")).added, 2);

    // Importing the same file again changes nothing.
    r = BakImport::importText(v1);
    QCOMPARE(r.tables.value(QStringLiteral("te_ueb")).skipped, 2);

    // A newer export deletes position 2 and changes position 1.
    const QString v2 = QStringLiteral(
        "INSERT IGNORE INTO te_ueb VALUES (\"müßig_jörg\",\"2024-03-04\",\"1\",\"2\",\"1\","
        "\"P\",\"N\",\"2024-03-03 10:00:00\",NOW(),\"trainer\",\"6\",\"062004010\",\"0\",\"0\")\n"
        "INSERT IGNORE INTO te_ueb VALUES (\"müßig_jörg\",\"2024-03-04\",\"1\",\"2\",\"2\","
        "\"P\",\"Y\",\"2024-03-03 10:00:00\",NOW(),\"trainer\",\"13\",\"070003020\",NULL,NULL)\n");
    r = BakImport::importText(v2);
    QCOMPARE(r.tables.value(QStringLiteral("te_ueb")).updated, 1);
    QCOMPARE(r.tables.value(QStringLiteral("te_ueb")).removed, 1);

    const Week w = Database::loadWeek(QStringLiteral("müßig_jörg"), QDate(2024, 3, 4),
                                      Variant::Plan);
    QCOMPARE(w.sessions.size(), 1);
    QCOMPARE(w.sessions[0].from, QStringLiteral("15:30"));
    QCOMPARE(w.sessions[0].entries.size(), 1);
    QCOMPARE(w.sessions[0].entries[0].steps.value(0), (Step{62, 4, 1, 0}));
}

void TestCore::saveAndLoadSession()
{
    Athlete a;
    a.lastName = QStringLiteral("Muster");
    a.firstName = QStringLiteral("Erika");
    a.sex = 1;
    const QString id = Database::saveAthlete(a);
    QCOMPARE(id, QStringLiteral("muster_erika"));
    QCOMPARE(Database::saveAthlete(a), QStringLiteral("muster_erika_2"));
    QVERIFY(Database::removeAthlete(QStringLiteral("muster_erika_2")));

    const QDate monday(2026, 11, 9);
    Session s;
    s.day = 1;
    s.number = 2;
    s.from = QStringLiteral("15:30");
    s.to = QStringLiteral("17:30");
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
    QCOMPARE(l.to, QStringLiteral("17:30"));

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
    mo.from = QStringLiteral("15:30");
    mo.to = QStringLiteral("17:30");
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
    QCOMPARE(sa->from, QStringLiteral("15:30")); // times of another 2nd session
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
    const QString path = m_dir.filePath(QStringLiteral("all.pdf"));
    QVERIFY(WeekReport::writePdf(path, w, {QStringLiteral("T"), QStringLiteral("V"), QStringLiteral("A B")}, o));
    QVERIFY(QFileInfo(path).size() > 1000);
}

QTEST_MAIN(TestCore)
#include "tst_core.moc"
