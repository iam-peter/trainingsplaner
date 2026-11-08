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

    // Chart: ITP targets against the week plans (basis "P" or "I") for an
    // exercise or group: {labels, itpWh, itpMhg, itpBw, actWh, actMhg, actBw}
    Q_INVOKABLE QVariantMap comparison(const QString &athleteId, const QString &fromMonday, int weeks,
                                       int exercise, const QString &basis) const;

    // Planned weight steps per week: [{monday, label, text, wh, mhg, bw}]
    Q_INVOKABLE QVariantList plannedSteps(const QString &owner, int exercise, const QString &fromMonday,
                                          int weeks) const;
    // Returns an error message, empty on success
    Q_INVOKABLE QString setPlannedSteps(const QString &owner, int exercise, const QString &monday,
                                        const QString &text);

    // The ITP of an athlete for one week and exercise, for the week plan:
    // {has, wh, mhg, bw, repsSets, steps}
    Q_INVOKABLE QVariantMap itpForWeek(const QString &athleteId, const QString &monday, int exercise) const;

    // Exports a MAZ with its athletes and RO; returns a summary
    Q_INVOKABLE QString exportMaz(const QUrl &file, const QString &mazId);

    Q_INVOKABLE QString weekLabel(const QString &monday) const;
    Q_INVOKABLE QString mondayFromLabel(const QString &label) const;

signals:
    void changed();
};
