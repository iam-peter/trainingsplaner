#include "updater.h"

#include <QCoreApplication>
#include <QDateTime>
#include <QDesktopServices>
#include <QDir>
#include <QEventLoop>
#include <QFileInfo>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QProcess>
#include <QSettings>
#include <QStandardPaths>
#include <QTextStream>
#include <QTimer>

namespace {

const QUrl kLatestRelease(QStringLiteral("https://api.github.com/repos/iam-peter/trainingsplaner/releases/latest"));

QNetworkRequest request(const QUrl &url)
{
    QNetworkRequest r(url);
    // GitHub's API wants a user agent; nothing else about the computer is sent
    r.setHeader(QNetworkRequest::UserAgentHeader,
                QStringLiteral("Trainingsplaner/%1").arg(QCoreApplication::applicationVersion()));
    r.setRawHeader("Accept", "application/vnd.github+json");
    r.setTransferTimeout(20000);
    return r;
}

int httpStatus(QNetworkReply *reply)
{
    return reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
}

QString errorText(QNetworkReply *reply)
{
    const int status = httpStatus(reply);
    if (status == 403 || status == 429)
        return QStringLiteral("GitHub nimmt gerade keine Anfragen an. Bitte später erneut versuchen.");
    if (status > 0)
        return QStringLiteral("GitHub antwortet mit Fehler %1.").arg(status);
    return QStringLiteral("Keine Verbindung zu GitHub: %1").arg(reply->errorString());
}

} // namespace

Updater::Updater(QObject *parent)
    : QObject(parent)
    , m_net(new QNetworkAccessManager(this))
    , m_apiUrl(kLatestRelease)
{
    // Only an installation made with the installer can update itself; a
    // program unpacked from the zip gets the download page instead
    m_installsItself = Update::currentPlatform() == Update::Platform::Windows
                       && QFileInfo::exists(QCoreApplication::applicationDirPath() + QStringLiteral("/unins000.exe"));
}

QString Updater::currentVersion() const
{
    return QCoreApplication::applicationVersion();
}

bool Updater::autoCheck() const
{
    return QSettings().value(QStringLiteral("update/autoCheck"), true).toBool();
}

void Updater::setAutoCheck(bool on)
{
    if (on == autoCheck())
        return;
    QSettings().setValue(QStringLiteral("update/autoCheck"), on);
    emit autoCheckChanged();
}

void Updater::setInstallsItself(bool on)
{
    if (on == m_installsItself)
        return;
    m_installsItself = on;
    emit changed();
}

void Updater::setApiUrl(const QUrl &url)
{
    if (url == m_apiUrl)
        return;
    m_apiUrl = url;
    emit changed();
}

void Updater::setState(const QString &state, const QString &error)
{
    m_state = state;
    m_error = error;
    emit changed();
}

void Updater::checkOnStart()
{
    if (!autoCheck())
        return;
    const QDateTime last = QSettings().value(QStringLiteral("update/lastCheck")).toDateTime();
    if (last.isValid() && last.secsTo(QDateTime::currentDateTimeUtc()) < 24 * 3600)
        return;
    check();
}

void Updater::check()
{
    if (m_state == QStringLiteral("checking") || m_state == QStringLiteral("downloading"))
        return;
    setState(QStringLiteral("checking"));
    m_reply = m_net->get(request(m_apiUrl));
    connect(m_reply, &QNetworkReply::finished, this, &Updater::finishCheck);
}

void Updater::finishCheck()
{
    QNetworkReply *reply = m_reply;
    reply->deleteLater();
    // No stable release yet
    if (httpStatus(reply) == 404) {
        QSettings().setValue(QStringLiteral("update/lastCheck"), QDateTime::currentDateTimeUtc());
        m_release = {};
        setState(QStringLiteral("upToDate"));
        return;
    }
    if (reply->error() != QNetworkReply::NoError) {
        setState(QStringLiteral("error"), errorText(reply));
        return;
    }
    const Update::Release r = Update::parseRelease(reply->readAll(), Update::currentPlatform());
    if (!r.isValid()) {
        setState(QStringLiteral("error"), QStringLiteral("Die Antwort von GitHub ist unverständlich."));
        return;
    }
    QSettings().setValue(QStringLiteral("update/lastCheck"), QDateTime::currentDateTimeUtc());
    m_release = r;
    setState(Update::compareVersions(r.version, currentVersion()) > 0 ? QStringLiteral("available")
                                                                       : QStringLiteral("upToDate"));
}

void Updater::install()
{
    if (m_state != QStringLiteral("available") && m_state != QStringLiteral("error"))
        return;
    if (!m_release.isValid())
        return;
    if (!m_installsItself || m_release.asset.isEmpty()) {
        // The disk image on macOS; the release page with every download
        // on Linux and for the zip
        const bool direct = Update::currentPlatform() == Update::Platform::MacOS && !m_release.asset.isEmpty();
        QDesktopServices::openUrl(direct ? m_release.asset : m_release.page);
        return;
    }

    const QString dir = QStandardPaths::writableLocation(QStandardPaths::TempLocation)
                        + QStringLiteral("/trainingsplaner-update");
    QDir().mkpath(dir);
    m_file.setFileName(dir + QLatin1Char('/') + Update::assetName(Update::currentPlatform()));
    m_file.remove();
    if (!m_file.open(QIODevice::WriteOnly)) {
        setState(QStringLiteral("error"), QStringLiteral("Die Datei %1 kann nicht angelegt werden.")
                                              .arg(QDir::toNativeSeparators(m_file.fileName())));
        return;
    }
    m_hash.reset();
    m_progress = 0;
    emit progressChanged();
    m_downloadedFile.clear();
    setState(QStringLiteral("downloading"));

    QNetworkRequest r = request(m_release.asset);
    r.setRawHeader("Accept", "application/octet-stream");
    r.setTransferTimeout(60000);
    m_reply = m_net->get(r);
    connect(m_reply, &QNetworkReply::readyRead, this, [this] {
        const QByteArray data = m_reply->readAll();
        m_file.write(data);
        m_hash.addData(data);
    });
    connect(m_reply, &QNetworkReply::downloadProgress, this, [this](qint64 received, qint64 total) {
        if (total <= 0)
            total = m_release.size;
        m_progress = total > 0 ? double(received) / double(total) : 0;
        emit progressChanged();
    });
    connect(m_reply, &QNetworkReply::finished, this, &Updater::finishDownload);
}

void Updater::finishDownload()
{
    QNetworkReply *reply = m_reply;
    reply->deleteLater();
    const QByteArray rest = reply->readAll();
    m_file.write(rest);
    m_hash.addData(rest);
    m_file.close();

    QString problem;
    if (reply->error() == QNetworkReply::OperationCanceledError)
        problem = QStringLiteral("Der Download wurde abgebrochen.");
    else if (reply->error() != QNetworkReply::NoError)
        problem = errorText(reply);
    else if (m_release.size > 0 && m_file.size() != m_release.size)
        problem = QStringLiteral("Der Download ist unvollständig.");
    else if (!m_release.sha256.isEmpty() && m_hash.result() != m_release.sha256)
        problem = QStringLiteral("Die heruntergeladene Datei ist beschädigt (Prüfsumme stimmt nicht).");
    if (!problem.isEmpty()) {
        m_file.remove();
        setState(QStringLiteral("error"), problem);
        return;
    }
    m_downloadedFile = m_file.fileName();
    m_progress = 1;
    emit progressChanged();
    launch();
}

void Updater::launch()
{
    setState(QStringLiteral("installing"));
    if (!m_launchInstaller)
        return;
    // The installer closes nothing the user still needs: the program ends
    // right after starting it and the installer starts the new version
    const QStringList args = {QStringLiteral("/SILENT"), QStringLiteral("/SUPPRESSMSGBOXES"),
                              QStringLiteral("/NORESTART"), QStringLiteral("/CLOSEAPPLICATIONS")};
    if (!QProcess::startDetached(m_downloadedFile, args)) {
        setState(QStringLiteral("error"), QStringLiteral("Das Installationsprogramm kann nicht gestartet werden."));
        return;
    }
    QTimer::singleShot(0, qApp, &QCoreApplication::quit);
}

void Updater::cancel()
{
    if (m_reply && m_state == QStringLiteral("downloading"))
        m_reply->abort();
}

int Updater::checkFromCommandLine(QTextStream &out)
{
    QNetworkAccessManager net;
    QNetworkReply *reply = net.get(request(kLatestRelease));
    QEventLoop loop;
    QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    loop.exec();
    reply->deleteLater();

    out << "Installiert: " << QCoreApplication::applicationVersion() << '\n';
    if (httpStatus(reply) == 0) {
        out << errorText(reply) << '\n';
        return 1;
    }
    const Update::Release r = reply->error() == QNetworkReply::NoError
                                  ? Update::parseRelease(reply->readAll(), Update::currentPlatform())
                                  : Update::Release();
    if (!r.isValid()) {
        out << (httpStatus(reply) == 404 ? QStringLiteral("Noch keine stabile Version veröffentlicht.")
                                         : errorText(reply))
            << '\n';
        return 2;
    }
    out << "Neueste Version: " << r.version << '\n'
        << "Download: " << (r.asset.isEmpty() ? r.page.toString() : r.asset.toString()) << '\n';
    return 0;
}
