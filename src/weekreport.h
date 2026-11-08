#pragma once

#include "model.h"

#include <QString>

class QPagedPaintDevice;

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

// Paints all pages onto `device` (a QPrinter or QPdfWriter that is already
// set up with page size and margins).
void render(QPagedPaintDevice *device, const Week &week, const Header &header);

bool writePdf(const QString &path, const Week &week, const Header &header);

} // namespace WeekReport
