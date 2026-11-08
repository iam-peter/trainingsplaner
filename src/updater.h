#pragma once

#include "update.h"

#include <QCryptographicHash>
#include <QFile>
#include <QObject>
#include <QPointer>
#include <QUrl>
#include <QtQml/qqmlregistration.h>

class QNetworkAccessManager;
class QNetworkReply;
class QTextStream;

// Asks GitHub for the newest stable release. On Windows, when the program
// was installed with the installer, it downloads that installer, checks
// it and runs it silently; the installer closes the program, replaces it
// and starts it again. Elsewhere (macOS, Linux, the zip) it opens the
// download in the browser.
class Updater : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    // idle, checking, upToDate, available, downloading, installing, error
    Q_PROPERTY(QString state READ state NOTIFY changed)
    Q_PROPERTY(QString currentVersion READ currentVersion CONSTANT)
    Q_PROPERTY(QString latestVersion READ latestVersion NOTIFY changed)
    Q_PROPERTY(QString notes READ notes NOTIFY changed)
    Q_PROPERTY(QUrl releasePage READ releasePage NOTIFY changed)
    Q_PROPERTY(QString error READ error NOTIFY changed)
    Q_PROPERTY(double progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(bool autoCheck READ autoCheck WRITE setAutoCheck NOTIFY autoCheckChanged)
    // true: install() updates the program by itself, false: it opens the
    // download. Tests may set it.
    Q_PROPERTY(bool installsItself READ installsItself WRITE setInstallsItself NOTIFY changed)
    // Tests: where to ask, and whether to start the downloaded installer
    Q_PROPERTY(QUrl apiUrl READ apiUrl WRITE setApiUrl NOTIFY changed)
    Q_PROPERTY(bool launchInstaller MEMBER m_launchInstaller)
    Q_PROPERTY(QString downloadedFile READ downloadedFile NOTIFY changed)

public:
    explicit Updater(QObject *parent = nullptr);

    QString state() const { return m_state; }
    QString currentVersion() const;
    QString latestVersion() const { return m_release.version; }
    QString notes() const { return m_release.notes; }
    QUrl releasePage() const { return m_release.page; }
    QString error() const { return m_error; }
    double progress() const { return m_progress; }
    bool autoCheck() const;
    void setAutoCheck(bool on);
    bool installsItself() const { return m_installsItself; }
    void setInstallsItself(bool on);
    QUrl apiUrl() const { return m_apiUrl; }
    void setApiUrl(const QUrl &url);
    QString downloadedFile() const { return m_downloadedFile; }

    // Asks now (Einstellungen › Nach Updates suchen)
    Q_INVOKABLE void check();
    // At start: at most once a day, and only when the user allows it
    Q_INVOKABLE void checkOnStart();
    Q_INVOKABLE void install();
    Q_INVOKABLE void cancel();

    // --check-update: prints the newest version. Returns 0 when GitHub
    // named a release, 2 when it answered without one (no release yet, rate
    // limit) and 1 when it could not be reached at all (network, TLS).
    static int checkFromCommandLine(QTextStream &out);

signals:
    void changed();
    void progressChanged();
    void autoCheckChanged();

private:
    void setState(const QString &state, const QString &error = QString());
    void finishCheck();
    void finishDownload();
    void launch();

    QNetworkAccessManager *m_net;
    QPointer<QNetworkReply> m_reply;
    QString m_state = QStringLiteral("idle");
    QString m_error;
    double m_progress = 0;
    bool m_installsItself;
    bool m_launchInstaller = true;
    QUrl m_apiUrl;
    Update::Release m_release;
    QFile m_file;
    QCryptographicHash m_hash{QCryptographicHash::Sha256};
    QString m_downloadedFile;
};
