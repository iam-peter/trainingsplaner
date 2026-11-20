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
    // An ITP of an athlete in its MAZ: each cell has the RO's value as a
    // proposal, what "Vorlage" would make of it
    Q_PROPERTY(bool proposals READ proposals NOTIFY configChanged)

public:
    enum Roles { EditRole = Qt::UserRole + 1, AverageRole, KindRole, ExerciseRole, WarningRole, ProposalRole };

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
    bool proposals() const { return m_hasRo; }

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
    // The RO's proposal into a cell; with BW its reps and sets too
    Q_INVOKABLE bool takeProposal(int row, int column);
    // Every proposal of a week the grid shows, Bel. and WK too, where it
    // differs; the cells without one stay. Returns how many changed.
    Q_INVOKABLE int takeWeek(int row);

signals:
    void configChanged();

private:
    // Reads the plan for the current owner, weeks and MAZ (no signals)
    void load();
    // The columns: per exercise WH, MHG and BW; per complex (K1..K7) its
    // WH only, as the RTK and WinWoTA plan them; then the week's K1-7 and
    // K1-5, the sums of the complexes; then load and WK-Lage, and the
    // RTK's "Tr.-Wo.", the weeks to the main competition
    enum Kind { Wh, Mhg, Bw, Load, Position, Sum17, Sum15, Countdown };
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
    // The TMK's WH a week of a complex (0: K1-7) for the age in the first
    // week, as a line for a column's tip; "" without one
    QString normTip(int complex) const;
    // The RO's value for a cell as text, "" without one
    QString proposal(int row, int column) const;

    QString m_owner;
    QDate m_from;
    int m_weeks = 0;
    QList<int> m_exercises;
    QList<Column> m_columns;
    QString m_mazId;
    Maz m_maz;
    QDate m_mainWeek; // the MAZ's main competition, for Tr.-Wo.
    bool m_averageAll = false;
    QMap<QPair<QDate, int>, WeekTarget> m_targets;
    QMap<QDate, WeekMeta> m_meta;
    // For the TMK: the birth date of the athlete, or of the youngest of
    // the MAZ for a RO, and the athlete's targets in the MAZ
    QDate m_born;
    MazAthlete m_athlete;
    // The RO of the athlete's MAZ in kg, for the proposals
    bool m_hasRo = false;
    QMap<QPair<QDate, int>, WeekTarget> m_ro;
    QMap<QDate, WeekMeta> m_roMeta;
};
