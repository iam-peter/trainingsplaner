"""The handbook as a page of the website: docs/HANDBUCH.md to handbuch.html.

Run by the website's workflow (.github/workflows/pages.yml) into the
site folder, beside index.html, with the pictures copied to
handbuch/bilder/ there:

    python3 docs/handbuch/build_page.py docs/HANDBUCH.md site/handbuch.html

Only the Markdown the handbook uses is read: headings, paragraphs,
lists, tables, block quotes (the examples), pictures, links, code,
bold, italic and struck-through text.
"""
import html
import re
import sys


def inline(text):
    t = html.escape(text, quote=False)
    t = re.sub(r'`([^`]+)`', r'<code>\1</code>', t)
    t = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', t)
    t = re.sub(r'~~([^~]+)~~', r'<del>\1</del>', t)
    t = re.sub(r'(?<![*\w])\*([^*]+)\*(?!\*)', r'<em>\1</em>', t)

    def link(m):
        label, href = m.group(1), m.group(2)
        chapter = re.match(r'#(\d+)-', href)
        if chapter:
            href = '#kapitel-%s' % chapter.group(1)
        return '<a href="%s">%s</a>' % (href, label)
    return re.sub(r'\[([^\]]+)\]\(([^)]+)\)', link, t)


def convert(md):
    """Returns (intro, chapters html, [(number, title)])."""
    lines = md.split('\n')
    out, chapters, para = [], [], []
    i, n, in_contents = 0, len(lines), False

    def flush():
        if para:
            out.append('<p>%s</p>' % inline(' '.join(para)))
            para.clear()

    while i < n:
        line = lines[i]
        stripped = line.strip()
        if line.startswith('# '):
            i += 1
            continue
        # The page has its own list of chapters
        if stripped == '**Inhalt**':
            in_contents = True
        if in_contents:
            if stripped == '---':
                in_contents = False
            i += 1
            continue
        if stripped == '---' or not stripped:
            flush()
            i += 1
            continue
        m = re.match(r'^## (\d+)\. (.+)$', line)
        if m:
            flush()
            if chapters:
                out.append('</section>')
            chapters.append((m.group(1), m.group(2)))
            out.append('<section class="chapter" id="kapitel-%s"><h2><span class="num">%s</span> %s</h2>'
                       % (m.group(1), m.group(1), inline(m.group(2))))
            i += 1
            continue
        m = re.match(r'^### (.+)$', line)
        if m:
            flush()
            out.append('<h3>%s</h3>' % inline(m.group(1)))
            i += 1
            continue
        m = re.match(r'^!\[([^\]]*)\]\(([^)]+)\)$', line)
        if m:
            flush()
            alt = html.escape(m.group(1))
            out.append('<figure><img src="%s" alt="%s" width="1366" height="860" loading="lazy">'
                       '<figcaption>%s</figcaption></figure>' % (m.group(2), alt, alt))
            i += 1
            continue
        if line.startswith('>'):
            flush()
            block = []
            while i < n and lines[i].startswith('>'):
                block.append(lines[i][1:].strip())
                i += 1
            text = ' '.join(block)
            label = 'Beispiel'
            m = re.match(r'^\*\*(Beispiel[^*]*|Was man sieht:)\*\*\s*(.*)$', text)
            if m:
                label, text = m.group(1).rstrip(':'), m.group(2)
            out.append('<aside class="example"><div class="label">%s</div><p>%s</p></aside>'
                       % (html.escape(label), inline(text)))
            continue
        if line.startswith('|'):
            flush()
            rows = []
            while i < n and lines[i].startswith('|'):
                rows.append([c.strip() for c in lines[i].strip().strip('|').split('|')])
                i += 1
            head = rows[0]
            body = [r for r in rows[1:] if not re.fullmatch(r':?-+:?', r[0])]
            t = '<div class="table"><table><thead><tr>%s</tr></thead><tbody>' % ''.join(
                '<th>%s</th>' % inline(c) for c in head)
            t += ''.join('<tr>%s</tr>' % ''.join('<td>%s</td>' % inline(c) for c in r) for r in body)
            out.append(t + '</tbody></table></div>')
            continue
        if re.match(r'^(\d+\.|-) ', line):
            flush()
            ordered = line[0].isdigit()
            items = []
            while i < n and (re.match(r'^(\d+\.|-) ', lines[i]) or (lines[i].startswith('  ') and lines[i].strip())):
                if re.match(r'^(\d+\.|-) ', lines[i]):
                    items.append(re.sub(r'^(\d+\.|-) ', '', lines[i]))
                else:
                    items[-1] += ' ' + lines[i].strip()
                i += 1
            tag = 'ol' if ordered else 'ul'
            out.append('<%s>%s</%s>' % (tag, ''.join('<li>%s</li>' % inline(x) for x in items), tag))
            continue
        para.append(stripped)
        i += 1
    flush()
    if chapters:
        out.append('</section>')
    content = '\n'.join(out)
    start = content.index('<section')
    return content[:start], content[start:], chapters


# A line of a session, taken apart, after the heading that explains it
ANATOMY = '''<div class="anatomy" role="group" aria-label="Eine Zeile einer Trainingseinheit">
<div><b>1</b><span>Übung</span><small>Reißen WKÜ</small></div>
<div><b>7</b><span>WH</span><small>Wiederholungen</small></div>
<div><b>54</b><span>MHG</span><small>mittleres Hantelgewicht, kg</small></div>
<div><b>58</b><span>BW</span><small>Bestwert, kg</small></div>
<div><b>1/3</b><span>Wdh/<wbr>Sätze</span><small>beim Bestwert</small></div>
</div>'''

LOADS = '(<span class="load h">h</span> <span class="load m">m</span> <span class="load g">g</span>)'

PAGE = '''<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Handbuch – Trainingsplaner</title>
<meta name="description" content="Das Handbuch zum Trainingsplaner Gewichtheben: jede Ansicht mit Bild, an Beispieldaten erklärt.">
<link rel="icon" href="favicon.svg" type="image/svg+xml">
<link rel="stylesheet" href="style.css">
<script src="theme.js"></script>
</head>
<body>

<nav>
  <div class="wrap">
    <a class="brand" href="./"><img src="trainingsplaner.svg" alt=""> Trainingsplaner</a>
    <div class="links">
      <a href="./#download">Download</a>
      <a href="handbuch.html" aria-current="page">Handbuch</a>
      <a href="./#fragen">Fragen</a>
      <a href="https://github.com/iam-peter/trainingsplaner">GitHub</a>
    </div>
    <button class="theme-switch" id="theme-switch" type="button" aria-label="Dunkles Design">
      <svg class="moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z" /></svg>
      <svg class="sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="4" /> <path d="M12 2v2" /> <path d="M12 20v2" /> <path d="m4.93 4.93 1.41 1.41" /> <path d="m17.66 17.66 1.41 1.41" /> <path d="M2 12h2" /> <path d="M20 12h2" /> <path d="m6.34 17.66-1.41 1.41" /> <path d="m19.07 4.93-1.41 1.41" /></svg>
    </button>
  </div>
</nav>

<main class="wrap handbook">
  <aside class="contents" aria-label="Kapitel">
    <p class="contents-label">Kapitel</p>
    <ol>
{nav}
    </ol>
  </aside>
  <article>
    <h1>Handbuch</h1>
{intro}
    <p class="loads">Belastung einer Woche: <span class="load h">h</span> hoch
      <span class="load m">m</span> mittel <span class="load g">g</span> gesenkt</p>
{chapters}
  </article>
</main>

<footer>
  <div class="wrap">
    <span>MIT-Lizenz</span>
    <a href="https://github.com/iam-peter/trainingsplaner">GitHub</a>
    <a href="hinweise.html">Hinweise</a>
    <a href="./">Startseite</a>
  </div>
</footer>
</body>
</html>
'''


def main():
    src, dst = sys.argv[1], sys.argv[2]
    intro, chapters_html, chapters = convert(open(src, encoding='utf-8').read())
    chapters_html = chapters_html.replace('<h3>Eine Zeile lesen</h3>', '<h3>Eine Zeile lesen</h3>\n' + ANATOMY, 1)
    chapters_html = chapters_html.replace('(h / m / g)', LOADS)
    nav = '\n'.join('      <li><a href="#kapitel-%s"><span class="num">%s</span> %s</a></li>' % (num, num, inline(t))
                    for num, t in chapters)
    page = PAGE.replace('{nav}', nav).replace('{intro}', intro).replace('{chapters}', chapters_html)
    open(dst, 'w', encoding='utf-8').write(page)


if __name__ == '__main__':
    main()
