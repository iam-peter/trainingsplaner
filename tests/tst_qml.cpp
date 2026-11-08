#include "bakimport.h"
#include "database.h"

#include <QQmlEngine>
#include <QTemporaryDir>
#include <QtQml/qqmlextensionplugin.h>
#include <QtQuickTest>

Q_IMPORT_QML_PLUGIN(TrainingsplanerPlugin)

// Runs the QML tests against a fresh database in a temporary directory.
class Setup : public QObject
{
    Q_OBJECT

public slots:
    void applicationAvailable()
    {
        QCoreApplication::setOrganizationName(QStringLiteral("TrainingsplanerTest"));
        QVERIFY(m_dir.isValid());
        QVERIFY(Database::open(m_dir.filePath(QStringLiteral("qml.sqlite"))));
        Athlete a;
        a.lastName = QStringLiteral("Test");
        a.firstName = QStringLiteral("Tina");
        a.sex = 1;
        Database::saveAthlete(a); // id "test_tina"
    }

    void cleanupTestCase() { Database::close(); }

private:
    QTemporaryDir m_dir;
};

QUICK_TEST_MAIN_WITH_SETUP(trainingsplaner_qml, Setup)

#include "tst_qml.moc"
