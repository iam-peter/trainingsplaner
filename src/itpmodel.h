#pragma once

#include "planning.h"

#include <QAbstractTableModel>
#include <QtQml/qqmlregistration.h>

// The week × exercise grid of an ITP or RO: per exercise the columns WH,
// MHG and BW, then load level and competition position per week. The last
// row holds the averages. Edits are saved right away.
class ItpModel : public QAbstractTableModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString owner READ owner WRITE setOwner NOTIFY configChanged)
    Q_PROPERTY(QString fromMonday READ fromMonday WRITE setFromMonday NOTIFY configChanged)
    Q_PROPERTY(int weeks READ weeks WRITE setWeeks NOTIFY configChanged)
    Q_PROPERTY(QVariantList exercises READ exercises WRITE setExercises NOTIFY configChanged)
    // Phases of the MAZ for the row labels (A = build-up, L = performance)
    Q_PROPERTY(QString mazId READ mazId WRITE setMazId NOTIFY configChanged)
    Q_PROPERTY(bool averageAllWeeks READ averageAllWeeks WRITE setAverageAllWeeks NOTIFY configChanged)
    Q_PROPERTY(bool percent READ percent NOTIFY configChanged)

public:
    enum Roles { EditRole = Qt::UserRole + 1, AverageRole, KindRole, ExerciseRole };

    explicit ItpModel(QObject *parent = nullptr);

    QString owner() const { return m_owner; }
    void setOwner(const QString &v);
    QString fromMonday() const { return m_from.toString(Qt::ISODate); }
    void setFromMonday(const QString &v);
    int weeks() const { return m_weeks; }
    void setWeeks(int v);
    QVariantList exercises() const;
    void setExercises(const QVariantList &v);
    QString mazId() const { return m_mazId; }
    void setMazId(const QString &v);
    bool averageAllWeeks() const { return m_averageAll; }
    void setAverageAllWeeks(bool v);
    bool percent() const { return Planning::isRoOwner(m_owner); }

    int rowCount(const QModelIndex &parent = {}) const override;
    int columnCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role) override;
    QVariant headerData(int section, Qt::Orientation orientation, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    // {exercise, title, sub, first} for a column header
    Q_INVOKABLE QVariantMap columnInfo(int column) const;
    Q_INVOKABLE QString rowLabel(int row) const;
    Q_INVOKABLE QString rowMonday(int row) const;
    Q_INVOKABLE void reload();

signals:
    void configChanged();

private:
    enum Kind { Wh, Mhg, Bw, Load, Position };
    Kind kindOf(int column) const;
    int exerciseOf(int column) const;
    int value(int row, int column) const;

    QString m_owner;
    QDate m_from;
    int m_weeks = 0;
    QList<int> m_exercises;
    QString m_mazId;
    Maz m_maz;
    bool m_averageAll = false;
    QMap<QPair<QDate, int>, WeekTarget> m_targets;
    QMap<QDate, WeekMeta> m_meta;
};
