#pragma once

#include "model.h"

#include <QObject>
#include <QUrl>
#include <QVariant>
#include <QtQml/qqmlregistration.h>

#include <optional>

// The QML-facing API. Dates cross the boundary as ISO strings
// ("2026-11-09"), the week variant as "P" (plan) or "I" (actual).
class Store : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QVariantList athletes READ athletes NOTIFY athletesChanged)
    Q_PROPERTY(QVariantList catalog READ catalog CONSTANT)
    Q_PROPERTY(QString trainer READ trainer WRITE setTrainer NOTIFY settingsChanged)
    Q_PROPERTY(QString organisation READ organisation WRITE setOrganisation NOTIFY settingsChanged)
    Q_PROPERTY(QString databasePath READ databasePath CONSTANT)
    // Print options as in WeekReport::Options, margins in mm
    Q_PROPERTY(QVariantMap printOptions READ printOptions WRITE setPrintOptions NOTIFY settingsChanged)
    // Default times of the 1st-3rd session: [{from, to}, ...]
    Q_PROPERTY(QVariantList sessionTimes READ sessionTimes WRITE setSessionTimes NOTIFY settingsChanged)
    // Steps for the arrow keys in weight fields and for computed weights: 2.5 or 1
    Q_PROPERTY(double weightStep READ weightStep WRITE setWeightStep NOTIFY settingsChanged)
    Q_PROPERTY(QString clipboardLabel READ clipboardLabel NOTIFY clipboardChanged)
    Q_PROPERTY(int dataVersion READ dataVersion NOTIFY dataChanged)

public:
    explicit Store(QObject *parent = nullptr);

    QVariantList athletes() const;
    QVariantList catalog() const;
    QString trainer() const;
    void setTrainer(const QString &v);
    QString organisation() const;
    void setOrganisation(const QString &v);
    QString databasePath() const;
    QVariantMap printOptions() const;
    void setPrintOptions(const QVariantMap &v);
    QVariantList sessionTimes() const;
    void setSessionTimes(const QVariantList &v);
    double weightStep() const;
    void setWeightStep(double v);
    // Next weight up or down by weightStep, rounded to whole kg (100, 102, 105, 107 ...)
    Q_INVOKABLE int stepWeight(int kg, int direction) const;
    QString clipboardLabel() const;
    int dataVersion() const { return m_dataVersion; }

    // Weeks and sessions
    Q_INVOKABLE QVariantMap week(const QString &athleteId, const QString &monday,
                                 const QString &variant) const;
    Q_INVOKABLE QVariantMap session(const QString &athleteId, const QString &monday,
                                    const QString &variant, int day, int number) const;
    Q_INVOKABLE bool saveSession(const QString &athleteId, const QString &monday,
                                 const QString &variant, const QVariantMap &session);
    Q_INVOKABLE bool removeSession(const QString &athleteId, const QString &monday,
                                   const QString &variant, int day, int number);
    Q_INVOKABLE bool saveWeekNote(const QString &athleteId, const QString &monday,
                                  const QString &variant, const QString &note, bool injured);
    Q_INVOKABLE void copyWeek(const QString &athleteId, const QString &monday,
                              const QString &variant);
    // Returns the number of sessions pasted, -1 on error.
    Q_INVOKABLE int pasteWeek(const QString &athleteId, const QString &monday,
                              const QString &variant);

    // One exercise across the week ("Erfassung TÜ")
    Q_INVOKABLE QVariantMap exerciseWeek(const QString &athleteId, const QString &monday,
                                         const QString &variant, int exercise) const;
    Q_INVOKABLE bool saveExerciseWeek(const QString &athleteId, const QString &monday,
                                      const QString &variant, int exercise,
                                      const QVariantList &rows);

    // Live figures for the session editor
    Q_INVOKABLE QVariantMap stats(const QVariantList &steps) const;
    // Per exercise figures of the week, with the given session replaced by `entries`.
    Q_INVOKABLE QVariantMap weekStats(const QString &athleteId, const QString &monday,
                                      const QString &variant, int day, int number,
                                      const QVariantList &entries) const;

    // Athletes
    Q_INVOKABLE QString saveAthlete(const QVariantMap &athlete);
    Q_INVOKABLE bool removeAthlete(const QString &athleteId);
    Q_INVOKABLE int sessionCount(const QString &athleteId) const;

    // Dates
    Q_INVOKABLE QString today() const;
    Q_INVOKABLE QString mondayOf(const QString &date) const;
    Q_INVOKABLE QString addWeeks(const QString &monday, int weeks) const;
    Q_INVOKABLE QString weekLabel(const QString &monday) const;
    Q_INVOKABLE QString weekFromLabel(const QString &label) const;
    Q_INVOKABLE QString weekRange(const QString &monday) const;
    Q_INVOKABLE QString dayName(int day) const;
    Q_INVOKABLE QString dayDate(const QString &monday, int day) const;
    Q_INVOKABLE QString formatDate(const QString &isoDate) const;
    // "24.03.2001" -> "2001-03-24"; "" when invalid
    Q_INVOKABLE QString parseDate(const QString &text) const;
    Q_INVOKABLE QString exerciseName(int id) const;

    // Import, print, export
    Q_INVOKABLE QString importBak(const QUrl &file);
    Q_INVOKABLE bool printWeek(const QString &athleteId, const QString &monday,
                               const QString &variant);
    Q_INVOKABLE QUrl suggestedPdfUrl(const QString &athleteId, const QString &monday) const;
    // Returns an empty string on success, otherwise an error message.
    Q_INVOKABLE QString exportPdf(const QString &athleteId, const QString &monday,
                                  const QString &variant, const QUrl &file, bool open);

signals:
    void athletesChanged();
    void settingsChanged();
    void clipboardChanged();
    void dataChanged();

private:
    void bump();
    Week loadWeek(const QString &athleteId, const QString &monday, const QString &variant) const;

    int m_dataVersion = 0;
    struct Clip
    {
        QString athleteId;
        QDate monday;
        Variant variant = Variant::Plan;
    };
    std::optional<Clip> m_clip;
};
