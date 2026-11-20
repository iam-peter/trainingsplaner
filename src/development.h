#pragma once

#include <QList>

// The long-term development of total and body weight as Sandau (2018,
// Leipziger Sportwissenschaftliche Beiträge 59(2), 161-171) models it:
// a Gompertz function y = exp(a - b * exp(-c * t)) fitted by
// Levenberg-Marquardt, started from the initial values of Juric et al.
// (2004), with the model's standard error sqrt(mean residual²). As in
// his script, t is in whole steps (here years).
namespace Development {

struct Fit
{
    bool ok = false;
    double a = 0, b = 0, c = 0;
    double t0 = 0; // the first point's t: the model runs on t - t0
    double se = 0; // standard error of the model, in the units of y
    int points = 0;
};

// Needs four points at least, ascending t, y > 0. Not ok when the fit
// does not level off (c <= 0, or a plateau above three times the best
// value): such a curve would grow without end in a forecast.
Fit gompertz(const QList<double> &t, const QList<double> &y);

double value(const Fit &f, double t);

} // namespace Development
