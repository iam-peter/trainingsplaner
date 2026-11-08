#pragma once

#include <QObject>
#include <QUrl>
#include <QVariant>
#include <QtQml/qqmlregistration.h>

// QML API for the analyses. Reports come back as HTML (shown in the app,
// printed or saved as PDF); chart series as plain lists.
class AnalysisApi : public QObject
{
    Q_OBJECT
    QML_NAMED_ELEMENT(Analysis)
    QML_SINGLETON

public:
    explicit AnalysisApi(QObject *parent = nullptr);

    // p: {athleteId, mazId ("" = weeks below), from (week label), weeks,
    //     basis ("I", "P", "T" = ITP), reference ("kg", "ziel", "wk"),
    //     groups, competitionWeeks, summary,
    //     compareMazId, compareBasis ("I", "P", "T", "R" = framework plan), allMaz,
    //     loadExercise (0 = none)}
    Q_INVOKABLE QString individual(const QVariantMap &p) const;
    // p: {mazId, mode (0 overview, 1 volume, 2 intensity), exercise, reference, competitionWeeks}
    Q_INVOKABLE QString group(const QVariantMap &p) const;
    // p: {from (label), weeks, mode (0 training data, 1 competitions)}; athletes after the filter
    Q_INVOKABLE QString dataCheck(const QVariantMap &p) const;
    // p: {athleteId, mazId, from, weeks, exercise, volume (0 none, 1 exercise, 2..8 K1..K7,
    //     9 K1-5, 10 K1-7), basis, reference}
    // -> {labels, mhg, bw, wh}
    Q_INVOKABLE QVariantMap series(const QVariantMap &p) const;

    Q_INVOKABLE bool printHtml(const QString &html, const QString &title) const;
    Q_INVOKABLE QString saveHtmlPdf(const QString &html, const QString &title, const QUrl &file) const;
};
