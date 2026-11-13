#pragma once

#include <QObject>
#include <QUrl>
#include <QVariant>
#include <QtQml/qqmlregistration.h>

// QML API for long-term planning (MAZ, RO, ITP). Weeks cross the boundary
// as ISO dates of their Monday, or as labels "10/2027" where typed.
class Plan : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QVariantList mazList READ mazList NOTIFY changed)
    Q_PROPERTY(QVariantList exerciseSets READ exerciseSets CONSTANT)

public:
    explicit Plan(QObject *parent = nullptr);

    QVariantList mazList() const;
    QVariantList exerciseSets() const;

    Q_INVOKABLE QVariantMap maz(const QString &id) const;
    // m: {id, name, shortName, sex, from, to, buildUp, peakPhase (week labels), note}
    // Returns {id, error}
    Q_INVOKABLE QVariantMap saveMaz(const QVariantMap &m);
    Q_INVOKABLE bool removeMaz(const QString &id);
    Q_INVOKABLE QVariantList mazAthletes(const QString &mazId) const;
    Q_INVOKABLE bool saveMazAthlete(const QVariantMap &a);
    Q_INVOKABLE bool removeMazAthlete(const QString &mazId, const QString &athleteId);
    Q_INVOKABLE QVariantList mazForAthlete(const QString &athleteId) const;

    Q_INVOKABLE QString roOwner(const QString &mazId) const;
    // ITP of an athlete from the MAZ's RO
    Q_INVOKABLE bool itpFromRo(const QString &mazId, const QString &athleteId);
    Q_INVOKABLE bool copyPlan(const QString &fromOwner, const QString &fromMonday, const QString &toOwner,
                              const QString &toMonday, int weeks);

    // The load chart: an athlete's weeks of a MAZ (mazId), or of weeks
    // from fromMonday, for one exercise. Per week: label, load (h/m/g),
    // the ITP's target and the Ist and the Plan of the exercise (mhg, bw),
    // and of K1-7 (wh); null where there is none. With reference "ziel" or
    // "wk" the weights are in % of the athlete's MAZ target or of the
    // result the MAZ started from. todayIndex: the week of today, -1
    // outside. report: the same numbers as a table.
    Q_INVOKABLE QVariantMap loadCourse(const QString &athleteId, const QString &mazId, const QString &fromMonday,
                                       int weeks, int exercise, const QString &reference) const;

    // Planned weight steps per week: [{monday, label, text, wh, mhg, bw}]
    Q_INVOKABLE QVariantList plannedSteps(const QString &owner, int exercise, const QString &fromMonday,
                                          int weeks) const;
    // Returns an error message, empty on success
    Q_INVOKABLE QString setPlannedSteps(const QString &owner, int exercise, const QString &monday,
                                        const QString &text);

    // The ITP of an athlete for one week and exercise, for the week plan:
    // {has, wh, mhg, bw, repsSets, steps}
    Q_INVOKABLE QVariantMap itpForWeek(const QString &athleteId, const QString &monday, int exercise) const;
    // The load of an athlete's week (h, m, g or "" for none), as the ITP's
    // Bel. column; from the week plan. The ITP's other week values stay.
    Q_INVOKABLE bool setWeekLoad(const QString &athleteId, const QString &monday, const QString &load);

    // Exports a MAZ with its athletes and RO; returns a summary
    Q_INVOKABLE QString exportMaz(const QUrl &file, const QString &mazId);

    Q_INVOKABLE QString weekLabel(const QString &monday) const;
    Q_INVOKABLE QString mondayFromLabel(const QString &label) const;

signals:
    void changed();
};
