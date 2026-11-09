#include "bakimport.h"
#include "database.h"
#include "update.h"

#include <QCryptographicHash>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickStyle>
#include <QTemporaryDir>
#include <QtQml/qqmlextensionplugin.h>
#include <QtQuickTest>

Q_IMPORT_QML_PLUGIN(TrainingsplanerPlugin)
Q_IMPORT_QML_PLUGIN(TrainingsplanerStylePlugin)

// Runs the QML tests against a fresh database in a temporary directory.
class Setup : public QObject
{
    Q_OBJECT

public slots:
    void applicationAvailable()
    {
        QCoreApplication::setOrganizationName(QStringLiteral("TrainingsplanerTest"));
        // As the program does at start
        QQuickStyle::setStyle(QStringLiteral("TrainingsplanerStyle"));
        QQuickStyle::setFallbackStyle(QStringLiteral("Basic"));
        // The update tests compare against it
        QCoreApplication::setApplicationVersion(QStringLiteral("1.0.0"));
        QVERIFY(m_dir.isValid());
        QVERIFY(Database::open(m_dir.filePath(QStringLiteral("qml.sqlite"))));
        Athlete a;
        a.lastName = QStringLiteral("Test");
        a.firstName = QStringLiteral("Tina");
        a.sex = Sex::Female;
        Database::saveAthlete(a); // id "test_tina"
        writeUpdateFixtures();
    }

    // Answers like GitHub's for the update tests, as local files
    void qmlEngineAvailable(QQmlEngine *engine)
    {
        engine->rootContext()->setContextProperty(QStringLiteral("updateFixtures"), m_fixtures);
    }

    void cleanupTestCase() { Database::close(); }

private:
    void writeUpdateFixtures()
    {
        const QByteArray installer(100000, 'x');
        const QString assetPath = m_dir.filePath(Update::assetName(Update::currentPlatform()));
        QFile asset(assetPath);
        QVERIFY(asset.open(QIODevice::WriteOnly));
        asset.write(installer);
        asset.close();
        const QByteArray sha = QCryptographicHash::hash(installer, QCryptographicHash::Sha256).toHex();

        const auto release = [&](const QString &name, const QString &version, const QByteArray &digest) {
            const QJsonObject a{
                {QStringLiteral("name"), Update::assetName(Update::currentPlatform())},
                {QStringLiteral("size"), installer.size()},
                {QStringLiteral("digest"), QString::fromLatin1("sha256:" + digest)},
                {QStringLiteral("browser_download_url"), QUrl::fromLocalFile(assetPath).toString()},
            };
            const QJsonObject r{
                {QStringLiteral("tag_name"), QStringLiteral("v") + version},
                {QStringLiteral("html_url"), QStringLiteral("https://example.org/release")},
                {QStringLiteral("body"), QStringLiteral("## Neu\n- Beispiel")},
                {QStringLiteral("assets"), QJsonArray{a}},
            };
            QFile f(m_dir.filePath(name));
            QVERIFY(f.open(QIODevice::WriteOnly));
            f.write(QJsonDocument(r).toJson());
            m_fixtures.insert(name.section(QLatin1Char('.'), 0, 0), QUrl::fromLocalFile(f.fileName()));
        };
        release(QStringLiteral("newer.json"), QStringLiteral("99.0.0"), sha);
        release(QStringLiteral("same.json"), QStringLiteral("0.0.1"), sha);
        release(QStringLiteral("broken.json"), QStringLiteral("99.0.0"), QByteArray(64, '0'));
        m_fixtures.insert(QStringLiteral("missing"), QUrl::fromLocalFile(m_dir.filePath(QStringLiteral("none.json"))));
    }

    QTemporaryDir m_dir;
    QVariantMap m_fixtures;
};

QUICK_TEST_MAIN_WITH_SETUP(trainingsplaner_qml, Setup)

#include "tst_qml.moc"
