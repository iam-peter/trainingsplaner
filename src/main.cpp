#include "bakimport.h"
#include "database.h"
#include "colorscheme.h"
#include "updater.h"

#include <QApplication>
#include <QCommandLineParser>
#include <QDir>
#include <QFontDatabase>
#include <QIcon>
#include <QPainter>
#include <QMessageBox>
#include <QQmlApplicationEngine>
#include <QQmlEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QStandardPaths>
#include <QTextStream>
#include <QSvgRenderer>
#include <QTimer>
#include <QtQml/qqmlextensionplugin.h>

Q_IMPORT_QML_PLUGIN(TrainingsplanerPlugin)
Q_IMPORT_QML_PLUGIN(TrainingsplanerStylePlugin)

namespace {

// Inter for the interface and the printout, JetBrains Mono for figures in
// columns. Both come with the program, so it looks the same everywhere.
void loadFonts()
{
    const QString dir = QStringLiteral(":/qt/qml/Trainingsplaner/fonts/");
    for (const QString &file : QDir(dir).entryList({QStringLiteral("*.ttf")}))
        QFontDatabase::addApplicationFont(dir + file);
    QFont font = QApplication::font();
    font.setFamilies({QStringLiteral("Inter")});
    font.setHintingPreference(QFont::PreferNoHinting);
    QApplication::setFont(font);
}

QIcon appIcon()
{
    QSvgRenderer svg(QStringLiteral(":/qt/qml/Trainingsplaner/logo/trainingsplaner.svg"));
    QIcon icon;
    for (int size : {16, 24, 32, 48, 64, 128, 256}) {
        QPixmap pixmap(size, size);
        pixmap.fill(Qt::transparent);
        QPainter painter(&pixmap);
        svg.render(&painter);
        painter.end();
        icon.addPixmap(pixmap);
    }
    return icon;
}

} // namespace

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QApplication::setOrganizationName(QStringLiteral("Trainingsplaner"));
    QApplication::setApplicationName(QStringLiteral("Trainingsplaner"));
    QApplication::setApplicationDisplayName(QStringLiteral("Trainingsplaner Gewichtheben"));
    QApplication::setApplicationVersion(QStringLiteral(PROJECT_VERSION_STRING));
    QLocale::setDefault(QLocale(QLocale::German, QLocale::Germany));
    loadFonts();
    QApplication::setWindowIcon(appIcon());
    QGuiApplication::setDesktopFileName(QStringLiteral("trainingsplaner"));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Trainingsplanung Gewichtheben"));
    parser.addHelpOption();
    parser.addVersionOption();
    const QCommandLineOption dbOption(QStringLiteral("db"),
                                      QStringLiteral("Datenbankdatei (Standard: im Benutzerprofil)."),
                                      QStringLiteral("datei"));
    const QCommandLineOption importOption(QStringLiteral("import"),
                                          QStringLiteral("Datensicherung des alten Programms (.bak) importieren und beenden."),
                                          QStringLiteral("datei"));
    // Options for automated screenshots during development.
    const QCommandLineOption grabOption(QStringLiteral("grab"), QStringLiteral("Screenshot speichern und beenden."),
                                        QStringLiteral("png"));
    const QCommandLineOption athleteOption(QStringLiteral("athlete"), QStringLiteral("Sportler beim Start."),
                                           QStringLiteral("id"));
    const QCommandLineOption weekOption(QStringLiteral("week"), QStringLiteral("Woche beim Start, z.B. 46/2026."),
                                        QStringLiteral("woche"));
    const QCommandLineOption pageOption(QStringLiteral("page"), QStringLiteral("Startseite: plan oder sportler."),
                                        QStringLiteral("seite"));
    const QCommandLineOption sessionOption(QStringLiteral("open"),
                                           QStringLiteral("Trainingseinheit (1:2 = Tag:TE) oder Übung (ex:8) öffnen."),
                                           QStringLiteral("tag:te"));
    const QCommandLineOption schemeOption(QStringLiteral("farbschema"),
                                          QStringLiteral("Farbschema für diesen Start, unabhängig von der Einstellung: hell, dunkel oder klassisch."),
                                          QStringLiteral("schema"));
    const QCommandLineOption checkUpdateOption(QStringLiteral("check-update"),
                                               QStringLiteral("Neueste Version bei GitHub erfragen und beenden."));
    parser.addOptions({dbOption, importOption, grabOption, athleteOption, weekOption, pageOption, sessionOption,
                       schemeOption, checkUpdateOption});
    parser.process(app);
    if (parser.isSet(checkUpdateOption)) {
        QTextStream out(stdout);
        return Updater::checkFromCommandLine(out);
    }

    // The scheme chosen in the settings; --farbschema only for this start
    QString scheme = ColorScheme::saved();
    if (parser.isSet(schemeOption))
        scheme = parser.value(schemeOption) == QLatin1String("dunkel")       ? QStringLiteral("dark")
                 : parser.value(schemeOption) == QLatin1String("klassisch") ? QStringLiteral("classic")
                                                                           : QStringLiteral("light");
    ColorScheme::apply(scheme);

    // The program's own style; what it leaves out comes from Basic
    QQuickStyle::setStyle(QStringLiteral("TrainingsplanerStyle"));
    QQuickStyle::setFallbackStyle(QStringLiteral("Basic"));

    QString dbPath = parser.value(dbOption);
    if (dbPath.isEmpty()) {
        const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        dbPath = QDir(dir).filePath(QStringLiteral("trainingsplaner.sqlite"));
    }
    QString error;
    if (!Database::open(dbPath, &error)) {
        QMessageBox::critical(nullptr, QApplication::applicationDisplayName(),
                              QStringLiteral("Die Datenbank kann nicht geöffnet werden:\n%1\n\n%2")
                                  .arg(QDir::toNativeSeparators(dbPath), error));
        return 1;
    }

    if (parser.isSet(importOption)) {
        const BakImport::Result r = BakImport::importFile(parser.value(importOption));
        fprintf(stdout, "%s\n", qPrintable(r.summary()));
        return r.ok && r.errors.isEmpty() ? 0 : 2;
    }

    QQmlApplicationEngine engine;
    QVariantMap initial;
    if (parser.isSet(athleteOption))
        initial.insert(QStringLiteral("startAthlete"), parser.value(athleteOption));
    if (parser.isSet(weekOption))
        initial.insert(QStringLiteral("startWeek"), parser.value(weekOption));
    if (parser.isSet(pageOption))
        initial.insert(QStringLiteral("startPage"), parser.value(pageOption));
    if (parser.isSet(sessionOption))
        initial.insert(QStringLiteral("startSession"), parser.value(sessionOption));
    engine.setInitialProperties(initial);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
                     [] { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
    engine.loadFromModule("Trainingsplaner", "Main");

    if (parser.isSet(grabOption)) {
        const QString out = parser.value(grabOption);
        QTimer::singleShot(1500, &app, [&engine, out] {
            const auto roots = engine.rootObjects();
            if (auto *win = roots.isEmpty() ? nullptr : qobject_cast<QQuickWindow *>(roots.first()))
                win->grabWindow().save(out);
            QCoreApplication::quit();
        });
    }
    return app.exec();
}
