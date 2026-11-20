#pragma once

#include "model.h"

#include <QColor>
#include <QPageSize>
#include <QString>

class QPagedPaintDevice;
class QPageLayout;

// Printable week plan in the layout the trainers are used to: one table per
// session, weight steps written as "kg over reps, sets beside", and the
// WH / MHG / BW figures per exercise.
namespace WeekReport {

struct Header
{
    QString trainer;
    QString organisation; // shown top right, may be empty
    QString athleteName;
    int load = 0;         // the week's load from the ITP (Planning::loadText), 0 none
};

struct Options
{
    enum Notation {
        Fraction, // kg over reps, sets beside
        Slash     // 100/2/2
    };

    bool weekNote = false;          // print the week note
    bool weekNoteCentered = false;
    bool figures = false;           // weekly figures K1-K7
    bool tonnage = false;           // a column "t" with each line's tonnage
    bool sessionNoteCentered = false;
    Notation notation = Fraction;
    int blankHeader = 0;            // empty lines below the header
    int blankPerSession = 0;        // empty rows at the end of each session
    int blankAfterNote = 0;         // empty lines below the week note
    double fontSmall = 9;           // pt
    double fontNormal = 10;
    double fontLarge = 12;
    int marginTop = 12;             // whole mm
    int marginLeft = 12;
    int marginRight = 12;
    int marginBottom = 12;
    QPageSize::PageSizeId paper = QPageSize::A4; // A4, A5 or A3
    bool landscape = false;
    QString logoPath;               // drawn faintly behind the content
    QColor sessionColor = Qt::white; // background of the session header rows

    QPageLayout pageLayout() const;
};

// What the printout shows beside the old program's: a line's tonnage in
// t ("0,66"), the week's AMKT reps (groups 8 and 9: the reps of weight
// lines and the totals of text lines), and the creation line
QString tonnageText(const Stats &stats);
int amktReps(const Week &week);
QString createdText(const QDate &day);
// "Belastung: hoch" (mittel, gesenkt) under the title; "" without a load
QString loadLine(int load);

// Paints all pages onto `device` (a QPrinter or QPdfWriter that is already
// set up with pageLayout()).
void render(QPagedPaintDevice *device, const Week &week, const Header &header,
            const Options &options = {});

bool writePdf(const QString &path, const Week &week, const Header &header,
              const Options &options = {});

} // namespace WeekReport
