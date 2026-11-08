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
    // Athletes after the filter from the settings (Kader, sex)
    Q_PROPERTY(QVariantList selectableAthletes READ selectableAthletes NOTIFY athletesChanged)
    // Kader, Verein, ...: attributes with a history
    Q_PROPERTY(QStringList attributeNames READ attributeNames CONSTANT)
    Q_PROPERTY(QString filterKader READ filterKader WRITE setFilterKader NOTIFY athletesChanged)
    Q_PROPERTY(int filterSex READ filterSex WRITE setFilterSex NOTIFY athletesChanged)
    // Categories of extra info: [{name, code, unit, decimals, aggregate (MAX/MIN/SUM)}]
    Q_PROPERTY(QVariantList infoCategories READ infoCategories WRITE setInfoCategories NOTIFY settingsChanged)
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
    QVariantList selectableAthletes() const;
    QStringList attributeNames() const;
    QString filterKader() const;
    void setFilterKader(const QString &v);
    int filterSex() const; // -1 all, 0 men, 1 women
    void setFilterSex(int v);
    QVariantList infoCategories() const;
    void setInfoCategories(const QVariantList &v);
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
    Q_INVOKABLE QStringList attributeValues(const QString &art) const;

    // Extra info per day (Zusatzinfo)
    // [{date ("yyyy-MM-dd"), dateText, time ("HH:mm"), code, name, unit, value (number), valueText}]
    Q_INVOKABLE QVariantList dayInfo(const QString &athleteId, const QString &monday) const;
    // Returns an error message, empty on success. old* identify an edited entry.
    Q_INVOKABLE QString saveDayInfo(const QString &athleteId, const QString &date, const QString &time,
                                    const QString &code, const QString &value, const QString &oldDate,
                                    const QString &oldTime, const QString &oldCode);
    Q_INVOKABLE bool removeDayInfo(const QString &athleteId, const QString &code, const QString &date,
                                   const QString &time);
    // "Körpergewicht 74,5 kg · Creatin 15 g" for the week (aggregated per category)
    Q_INVOKABLE QString weekInfoSummary(const QString &athleteId, const QString &monday) const;
    // Sets the given attributes from today on, keeping the history
    Q_INVOKABLE bool setAthleteAttributes(const QString &athleteId, const QVariantMap &values);
    // [{from, to, text}] with dates as "dd.MM.yyyy"
    Q_INVOKABLE QVariantList attributeHistory(const QString &athleteId, const QString &art) const;
    // Replaces the record starting at oldFrom (empty: new record)
    Q_INVOKABLE QString saveAttributeRecord(const QString &athleteId, const QString &art,
                                            const QString &oldFrom, const QString &from,
                                            const QString &to, const QString &text);
    Q_INVOKABLE bool removeAttributeRecord(const QString &athleteId, const QString &art,
                                           const QString &from);

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
    Q_INVOKABLE QString importBak(const QUrl &file, bool ignoreTimestamps = false);
    // mode: "all", "since" (since = "dd.MM.yyyy" and "HH:mm"), "athlete"
    // (athleteId, week labels from/to). Returns a summary.
    Q_INVOKABLE QString exportBak(const QUrl &file, const QString &mode, const QString &sinceDate,
                                  const QString &sinceTime, const QString &athleteId,
                                  const QString &fromWeek, const QString &toWeek);
    Q_INVOKABLE QUrl suggestedExportUrl() const;
    // When the last export was written, "dd.MM.yyyy HH:mm", or empty
    Q_INVOKABLE QString lastExport() const;
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
