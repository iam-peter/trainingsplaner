#include "bakimport.h"
#include "database.h"
#include "updater.h"

#include <QApplication>
#include <QCommandLineParser>
#include <QDir>
#include <QFontDatabase>
#include <QIcon>
#include <QPainter>
#include <QMessageBox>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QStandardPaths>
#include <QPalette>
#include <QStyleHints>
#include <QTextStream>
#include <QSvgRenderer>
#include <QTimer>
#include <QtQml/qqmlextensionplugin.h>

Q_IMPORT_QML_PLUGIN(TrainingsplanerPlugin)

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
    QQuickStyle::setStyle(QStringLiteral("Fusion"));
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
                                          QStringLiteral("Farbschema unabhängig vom System: hell oder dunkel."),
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
    if (parser.isSet(schemeOption)) {
        const QString scheme = parser.value(schemeOption);
        const bool dark = scheme == QLatin1String("dunkel");
        QGuiApplication::styleHints()->setColorScheme(dark ? Qt::ColorScheme::Dark : Qt::ColorScheme::Light);
        if (dark) {
            // Also a dark palette, for platforms without colour schemes
            QPalette p;
            p.setColor(QPalette::Window, QColor(0x2b, 0x2a, 0x29));
            p.setColor(QPalette::WindowText, QColor(0xee, 0xec, 0xea));
            p.setColor(QPalette::Base, QColor(0x1f, 0x1e, 0x1d));
            p.setColor(QPalette::AlternateBase, QColor(0x2f, 0x2d, 0x2b));
            p.setColor(QPalette::Text, QColor(0xee, 0xec, 0xea));
            p.setColor(QPalette::Button, QColor(0x35, 0x33, 0x31));
            p.setColor(QPalette::ButtonText, QColor(0xee, 0xec, 0xea));
            p.setColor(QPalette::Highlight, QColor(0xc2, 0x41, 0x0c));
            p.setColor(QPalette::HighlightedText, Qt::white);
            p.setColor(QPalette::PlaceholderText, QColor(0x9a, 0x95, 0x90));
            p.setColor(QPalette::ToolTipBase, QColor(0x35, 0x33, 0x31));
            p.setColor(QPalette::ToolTipText, QColor(0xee, 0xec, 0xea));
            p.setColor(QPalette::Mid, QColor(0x55, 0x52, 0x4f));
            p.setColor(QPalette::Dark, QColor(0x1a, 0x19, 0x18));
            p.setColor(QPalette::Light, QColor(0x4a, 0x47, 0x44));
            p.setColor(QPalette::Disabled, QPalette::Text, QColor(0x77, 0x73, 0x70));
            p.setColor(QPalette::Disabled, QPalette::ButtonText, QColor(0x77, 0x73, 0x70));
            p.setColor(QPalette::Disabled, QPalette::WindowText, QColor(0x77, 0x73, 0x70));
            QApplication::setPalette(p);
        }
    }

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
