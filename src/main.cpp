#include "bakimport.h"
#include "database.h"

#include <QApplication>
#include <QCommandLineParser>
#include <QDir>
#include <QMessageBox>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QStandardPaths>
#include <QTimer>
#include <QtQml/qqmlextensionplugin.h>

Q_IMPORT_QML_PLUGIN(TrainingsplanerPlugin)

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QApplication::setOrganizationName(QStringLiteral("Trainingsplaner"));
    QApplication::setApplicationName(QStringLiteral("Trainingsplaner"));
    QApplication::setApplicationDisplayName(QStringLiteral("Trainingsplaner Gewichtheben"));
    QApplication::setApplicationVersion(QStringLiteral(PROJECT_VERSION_STRING));
    QLocale::setDefault(QLocale(QLocale::German, QLocale::Germany));
    QQuickStyle::setStyle(QStringLiteral("Fusion"));

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
                                           QStringLiteral("Trainingseinheit öffnen, z.B. 1:2 (Tag:TE)."),
                                           QStringLiteral("tag:te"));
    parser.addOptions({dbOption, importOption, grabOption, athleteOption, weekOption, pageOption, sessionOption});
    parser.process(app);

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
