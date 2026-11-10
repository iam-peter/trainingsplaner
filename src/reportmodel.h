#pragma once

#include "report.h"

#include <QAbstractTableModel>
#include <QFont>
#include <QtQml/qqmlregistration.h>

// A report (Analysis.individual() and the like) laid out for one table
// view: every heading, note and table row is a row of the model, so the
// view builds only the cells in sight. The columns are shared by all
// tables of the report, each as wide as its widest cell. Headings and
// notes stand in the first column and reach over the others.
class ReportModel : public QAbstractTableModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVariantMap report READ report WRITE setReport NOTIFY reportChanged)
    // The font of the cells; widths and heights follow it
    Q_PROPERTY(QFont font READ font WRITE setFont NOTIFY fontChanged)
    Q_PROPERTY(bool empty READ empty NOTIFY reportChanged)
    Q_PROPERTY(qreal totalWidth READ totalWidth NOTIFY layoutDone)
    Q_PROPERTY(qreal totalHeight READ totalHeight NOTIFY layoutDone)
    // The room beside the text of a cell, as the first reports had it
    Q_PROPERTY(qreal padding READ padding CONSTANT)

public:
    enum Kind { Title, Heading, Note, Header, Cell, Blank };
    Q_ENUM(Kind)
    enum Roles { KindRole = Qt::UserRole + 1, BoldRole, MutedRole, LeftRole };

    explicit ReportModel(QObject *parent = nullptr);

    QVariantMap report() const { return m_report; }
    void setReport(const QVariantMap &report);
    QFont font() const { return m_font; }
    void setFont(const QFont &font);
    bool empty() const { return m_lines.isEmpty(); }
    qreal totalWidth() const;
    qreal totalHeight() const;
    qreal padding() const;

    Q_INVOKABLE qreal columnWidth(int column) const;
    Q_INVOKABLE qreal rowHeight(int row) const;

    int rowCount(const QModelIndex &parent = {}) const override;
    int columnCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

signals:
    void reportChanged();
    void fontChanged();
    void layoutDone();

private:
    struct Line
    {
        Kind kind = Blank;
        QString text;          // Title, Heading, Note
        Report::Cells cells;   // Header, Cell
        int lines = 1;         // Note
        int columns = 0;       // Header, Cell: the columns of its table
    };
    void rebuild();
    void measure();

    QVariantMap m_report;
    QFont m_font;
    QList<Line> m_lines;
    int m_columns = 1;
    QList<qreal> m_widths;
    qreal m_lineHeight = 16;
};
