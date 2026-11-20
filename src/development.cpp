#include "development.h"

#include <cmath>

namespace Development {

namespace {

double model(double a, double b, double c, double t)
{
    return std::exp(a - b * std::exp(-c * t));
}

double squaredError(const QList<double> &t, const QList<double> &y, double a, double b, double c)
{
    double sum = 0;
    for (int i = 0; i < t.size(); ++i) {
        const double r = y[i] - model(a, b, c, t[i]);
        sum += r * r;
    }
    return sum;
}

// Solves the 3x3 system m x = v (Gaussian elimination with pivoting)
bool solve3(double m[3][3], double v[3], double x[3])
{
    double a[3][4];
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 3; ++j)
            a[i][j] = m[i][j];
        a[i][3] = v[i];
    }
    for (int col = 0; col < 3; ++col) {
        int pivot = col;
        for (int r = col + 1; r < 3; ++r) {
            if (std::abs(a[r][col]) > std::abs(a[pivot][col]))
                pivot = r;
        }
        if (std::abs(a[pivot][col]) < 1e-300)
            return false;
        for (int j = 0; j < 4; ++j)
            std::swap(a[col][j], a[pivot][j]);
        for (int r = 0; r < 3; ++r) {
            if (r == col)
                continue;
            const double f = a[r][col] / a[col][col];
            for (int j = col; j < 4; ++j)
                a[r][j] -= f * a[col][j];
        }
    }
    for (int i = 0; i < 3; ++i)
        x[i] = a[i][3] / a[i][i];
    return true;
}

// Juric et al. (2004): from three points at t1, t2 = (t1 + t3) / 2, t3 on
// the log scale; here the first, middle and last point
bool initial(const QList<double> &t, const QList<double> &y, double *a, double *b, double *c)
{
    const int n = int(t.size());
    const double t1 = t[0], t3 = t[n - 1];
    // y at the middle of the range, interpolated between its neighbours
    const double tm = (t1 + t3) / 2;
    double ym = y[0];
    for (int i = 1; i < n; ++i) {
        if (t[i] >= tm) {
            const double f = t[i] > t[i - 1] ? (tm - t[i - 1]) / (t[i] - t[i - 1]) : 0;
            ym = y[i - 1] + f * (y[i] - y[i - 1]);
            break;
        }
    }
    const double l1 = std::log(y[0]), l2 = std::log(ym), l3 = std::log(y[n - 1]);
    const double d = l3 - 2 * l2 + l1;
    const double ratio = (l3 - l2) / (l2 - l1);
    if (std::abs(d) > 1e-12 && ratio > 0 && std::isfinite(ratio) && t3 > t1) {
        *c = -2 / (t3 - t1) * std::log(ratio);
        *a = l1 - (l2 - l1) * (l2 - l1) / d;
        *b = (*a - l1) * std::exp(*c * t1);
        if (std::isfinite(*a) && std::isfinite(*b) && std::isfinite(*c) && *c > 0)
            return true;
    }
    // Otherwise: a plateau a little above the best, a moderate rate
    double best = 0;
    for (double v : y)
        best = std::max(best, v);
    *a = std::log(best * 1.15);
    *c = 0.3;
    *b = (*a - l1) * std::exp(*c * t1);
    return std::isfinite(*b);
}

} // namespace

Fit gompertz(const QList<double> &t, const QList<double> &y)
{
    Fit f;
    const int n = int(t.size());
    f.points = n;
    if (n < 4 || y.size() != n)
        return f;
    for (int i = 0; i < n; ++i) {
        if (!(y[i] > 0) || (i > 0 && t[i] <= t[i - 1]))
            return f;
    }
    // Times from the first, for well-sized numbers
    const double t0 = t[0];
    QList<double> ts;
    for (double v : t)
        ts.append(v - t0);

    double a = 0, b = 0, c = 0;
    if (!initial(ts, y, &a, &b, &c))
        return f;

    // Levenberg-Marquardt
    double lambda = 1e-3;
    double err = squaredError(ts, y, a, b, c);
    bool converged = false;
    for (int iter = 0; iter < 500 && !converged; ++iter) {
        double jtj[3][3] = {}, jtr[3] = {};
        for (int i = 0; i < n; ++i) {
            const double e = std::exp(-c * ts[i]);
            const double m = model(a, b, c, ts[i]);
            const double j[3] = {m, -m * e, m * b * ts[i] * e};
            const double r = y[i] - m;
            for (int p = 0; p < 3; ++p) {
                jtr[p] += j[p] * r;
                for (int q = 0; q < 3; ++q)
                    jtj[p][q] += j[p] * j[q];
            }
        }
        bool improved = false;
        for (int tries = 0; tries < 20 && !improved; ++tries) {
            double m[3][3], delta[3];
            for (int p = 0; p < 3; ++p) {
                for (int q = 0; q < 3; ++q)
                    m[p][q] = jtj[p][q];
                m[p][p] += lambda * (jtj[p][p] > 0 ? jtj[p][p] : 1);
            }
            if (!solve3(m, jtr, delta)) {
                lambda *= 10;
                continue;
            }
            const double na = a + delta[0], nb = b + delta[1], nc = c + delta[2];
            const double nerr = squaredError(ts, y, na, nb, nc);
            if (std::isfinite(nerr) && nerr < err) {
                const double change = std::abs(err - nerr) / std::max(err, 1e-12);
                a = na;
                b = nb;
                c = nc;
                err = nerr;
                lambda = std::max(lambda / 10, 1e-12);
                improved = true;
                if (change < 1e-10)
                    converged = true;
            } else {
                lambda *= 10;
            }
        }
        if (!improved)
            converged = true; // no step makes it better: a minimum
    }
    if (!std::isfinite(a) || !std::isfinite(b) || !std::isfinite(c) || c <= 0)
        return f;
    // A curve without a level in sight: an exponential in disguise, whose
    // plateau lies far beyond anything lifted
    double best = 0;
    for (double v : y)
        best = std::max(best, v);
    if (a > std::log(3 * best))
        return f;
    f.ok = true;
    f.a = a;
    f.b = b;
    f.c = c;
    f.t0 = t0;
    f.se = std::sqrt(err / n);
    return f;
}

double value(const Fit &f, double t)
{
    return f.ok ? model(f.a, f.b, f.c, t - f.t0) : 0;
}

} // namespace Development
