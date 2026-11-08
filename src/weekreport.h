#pragma once

#include "model.h"

#include <QColor>
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
    bool sessionNoteCentered = false;
    Notation notation = Fraction;
    int blankHeader = 0;            // empty lines below the header
    int blankPerSession = 0;        // empty rows at the end of each session
    int blankAfterNote = 0;         // empty lines below the week note
    double fontSmall = 9;           // pt
    double fontNormal = 10;
    double fontLarge = 12;
    double marginTop = 12;          // mm
    double marginLeft = 12;
    double marginRight = 12;
    double marginBottom = 12;
    bool landscape = false;
    QString logoPath;               // drawn faintly behind the content
    QColor sessionColor = Qt::white; // background of the session header rows

    QPageLayout pageLayout() const;
};

// Paints all pages onto `device` (a QPrinter or QPdfWriter that is already
// set up with pageLayout()).
void render(QPagedPaintDevice *device, const Week &week, const Header &header,
            const Options &options = {});

bool writePdf(const QString &path, const Week &week, const Header &header,
              const Options &options = {});

} // namespace WeekReport
