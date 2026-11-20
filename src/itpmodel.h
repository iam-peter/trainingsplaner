#pragma once

#include "planning.h"

#include <QAbstractTableModel>
#include <QtQml/qqmlregistration.h>

// The week × exercise grid of an ITP or RO: per exercise the columns WH,
// MHG and BW, then load level and competition position per week. The last
// row holds the averages. Edits are saved right away. A value against the
// Trainingsmittelkatalog for the athlete's age (for a RO: the youngest
// of the MAZ) carries a warning.
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
    enum Roles { EditRole = Qt::UserRole + 1, AverageRole, KindRole, ExerciseRole, WarningRole };

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

    // {exercise, title, sub, first, tip, readOnly} for a column header
    Q_INVOKABLE QVariantMap columnInfo(int column) const;
    Q_INVOKABLE QString rowLabel(int row) const;
    Q_INVOKABLE QString rowMonday(int row) const;
    Q_INVOKABLE void reload();

signals:
    void configChanged();

private:
    // Reads the plan for the current owner, weeks and MAZ (no signals)
    void load();
    // The columns: per exercise WH, MHG and BW; per complex (K1..K7) its
    // WH only, as the RTK and WinWoTA plan them; then the week's K1-7 and
    // K1-5, the sums of the complexes; then load and WK-Lage
    enum Kind { Wh, Mhg, Bw, Load, Position, Sum17, Sum15 };
    struct Column
    {
        Kind kind;
        int exercise;
    };
    void layColumns();
    Kind kindOf(int column) const;
    int exerciseOf(int column) const;
    int value(int row, int column) const;
    int complexSum(const QDate &monday, int last) const;
    // What the TMK 2018 says against a cell, "" when nothing
    QString warning(int row, int column) const;

    QString m_owner;
    QDate m_from;
    int m_weeks = 0;
    QList<int> m_exercises;
    QList<Column> m_columns;
    QString m_mazId;
    Maz m_maz;
    bool m_averageAll = false;
    QMap<QPair<QDate, int>, WeekTarget> m_targets;
    QMap<QDate, WeekMeta> m_meta;
    // For the TMK: the birth date of the athlete, or of the youngest of
    // the MAZ for a RO, and the athlete's targets in the MAZ
    QDate m_born;
    MazAthlete m_athlete;
};
