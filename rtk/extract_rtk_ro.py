"""The Rahmenorientierungen of the BVDG's RTK-Online as data for the program.

RTK-Online (https://rtk.gewichtheben.sport-iat.de, status July 2023, the
Rahmentrainingskonzeption 2019 as a website) has one MAZ per age group as
a PDF printed by WinWoTA:

    https://rtk.gewichtheben.sport-iat.de/fileadmin/user_upload/BVDG-Gewichtheben/Downloads/MAZ_U13_6W.pdf
    https://rtk.gewichtheben.sport-iat.de/fileadmin/user_upload/BVDG-Gewichtheben/MAZ_U15_13W.pdf
    https://rtk.gewichtheben.sport-iat.de/fileadmin/user_upload/BVDG-Gewichtheben/MAZ_U17_13W.pdf
    https://rtk.gewichtheben.sport-iat.de/fileadmin/user_upload/BVDG-Gewichtheben/MAZ_U20_17W.pdf

Per week: the load (h/m/g), LG/WK/HWK, per exercise MHG and BW in percent
of the competition target with the reps (and sets) at BW, and per complex
K1..K7 the WH. Read by the words' positions (pdftotext -bbox, poppler), so
an empty cell stays empty. Every week's complexes are checked against the
printed K1-7 and K1-5.

    python3 rtk/extract_rtk_ro.py <folder with the four PDFs> > rtk/rtk-ro.json
"""
import json
import re
import subprocess
import sys
from html import unescape

# Phases as RTK-Online gives them (pages "Training" of each stage): U15 and
# U17 six weeks Grundlagen-, four Aufbau-, three Leistungsausprägungsphase;
# U13 none ("aufgrund des kurzen Makrozyklus"); U20 names the three phases
# without their lengths.
TEMPLATES = [
    ("U13", "MAZ_U13_6W.pdf", None, None),
    ("U15", "MAZ_U15_13W.pdf", 7, 11),
    ("U17", "MAZ_U17_13W.pdf", 7, 11),
    ("U20", "MAZ_U20_17W.pdf", None, None),
]


def words(pdf):
    out = subprocess.run(["pdftotext", "-bbox", pdf, "-"], capture_output=True, text=True, check=True).stdout
    pages, page = [], None
    for line in out.splitlines():
        if line.strip().startswith("<page"):
            page = []
            pages.append(page)
        m = re.search(r'<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="[\d.]+">(.*)</word>', line)
        if m and page is not None:
            page.append((float(m[1]), float(m[2]), float(m[3]), unescape(m[4])))
    return pages


def rows(page):
    """The page's lines by y, each its words by x."""
    lines = {}
    for w in page:
        key = round(w[1])
        lines.setdefault(key, []).append(w)
    return [sorted(ws) for _, ws in sorted(lines.items())]


def headers(page, prefix):
    """{exercise or complex: centre x} of the heading row's "TÜ n" or "Kn"."""
    found = {}
    for line in rows(page):
        texts = [w[3] for w in line]
        if prefix == "TÜ" and "TÜ" in texts:
            for i, w in enumerate(line[:-1]):
                if w[3] == "TÜ" and line[i + 1][3].isdigit():
                    found[int(line[i + 1][3])] = (w[0] + line[i + 1][2]) / 2
        if prefix == "K" and "K1" in texts and "K7" in texts:
            for w in line:
                m = re.fullmatch(r"K([1-7])", w[3])
                if m:
                    found[int(m[1])] = (w[0] + w[2]) / 2
    return found


def week_rows(page):
    """The lines of the weeks: (calendar week, load, position, k17, k15, rest)."""
    for line in rows(page):
        texts = [w[3] for w in line]
        if len(texts) < 6 or not re.fullmatch(r"\d\d\.", texts[2]):
            continue
        week = int(texts[2][:-1])
        i = 3
        load = texts[i] if texts[i] in ("h", "m", "g") else ""
        i += 1 if load else 0
        position = texts[i] if texts[i] in ("LG", "WK", "HWK") else ""
        i += 1 if position else 0
        k17, k15 = int(texts[i]), int(texts[i + 1])
        yield week, load, position, k17, k15, line[i + 2:]


def nearest(x, columns):
    return min(columns, key=lambda c: abs(columns[c] - x))


def extract(pdf):
    pages = words(pdf)
    weeks = {}
    for page in pages:
        exercises = headers(page, "TÜ")
        complexes = headers(page, "K")
        for week, load, position, k17, k15, rest in week_rows(page):
            w = weeks.setdefault(week, {"week": week, "load": load, "position": position, "k17": k17,
                                        "k15": k15, "complexes": {}, "exercises": {}})
            if complexes:
                for x0, _, x1, t in rest:
                    w["complexes"][nearest((x0 + x1) / 2, complexes)] = int(t)
                continue
            # A cell: MHG, "BW/reps", maybe "/sets"
            cell = None
            for x0, _, x1, t in rest:
                if re.fullmatch(r"\d+", t):
                    cell = {"mhg": int(t), "x0": x0, "x1": x1}
                elif m := re.fullmatch(r"(\d+)/(\d+)", t):
                    cell.update(bw=int(m[1]), reps=int(m[2]), sets=1, x1=x1)
                    w["exercises"][nearest((cell["x0"] + cell["x1"]) / 2, exercises)] = cell
                elif m := re.fullmatch(r"/(\d+)", t):
                    cell["sets"] = int(m[1])
                else:
                    raise ValueError("%s week %d: %r" % (pdf, week, t))
    out = []
    for week in sorted(weeks):
        w = weeks[week]
        ks = w["complexes"]
        assert sum(ks.values()) == w["k17"], (pdf, week, ks, w["k17"])
        assert sum(v for k, v in ks.items() if k <= 5) == w["k15"], (pdf, week, ks, w["k15"])
        out.append({
            "week": week, "load": w["load"], "position": w["position"],
            "complexes": {str(k): v for k, v in sorted(ks.items())},
            "exercises": {str(e): [c["mhg"], c["bw"], c["reps"], c["sets"]]
                          for e, c in sorted(w["exercises"].items())},
        })
    return out


def main():
    folder = sys.argv[1]
    data = {
        "source": "BVDG, Rahmentrainingskonzeption 2019, RTK-Online (status July 2023): Rahmenorientierung "
                  "MAZ_U13_6W, MAZ_U15_13W, MAZ_U17_13W, MAZ_U20_17W. https://rtk.gewichtheben.sport-iat.de",
        "about": "Per week the load, LG/WK/HWK, the WH of the complexes K1..K7 and per exercise "
                 "[MHG %, BW %, reps at BW, sets at BW], percent of the competition target. Made by "
                 "rtk/extract_rtk_ro.py. Numbers only.",
        "templates": [],
    }
    for key, pdf, build_up, peak in TEMPLATES:
        weeks = extract(folder + "/" + pdf)
        data["templates"].append({"key": key, "weeks": len(weeks), "buildUp": build_up, "peak": peak,
                                  "rows": weeks})
    json.dump(data, sys.stdout, ensure_ascii=False, indent=1)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
