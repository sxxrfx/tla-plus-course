#!/usr/bin/env python3
"""Assemble src/<id>.html (+ src/<id>.figs.py, labs/<id>.js) into a course page.
usage: build.py [--out PATH]   default out: ../tla-plus-course.html (the page the Mac app bundles).
Lesson source rules:
  * file holds only the lesson body, starting with <h1>, then a <p class="lead">. No <section>, no chapter line.
  * <!--fig:name--> is replaced by a <figure> from FIGS in src/<id>.figs.py: FIGS={"name":(svg_string,"caption")}.
  * {{lesson:id}} becomes a link reading "lesson N"; {{ref:id}} a link reading the lesson's sidebar title. {{lessons:a,b}} not supported; write two.
"""
import re,sys,os,glob,importlib.util,json
R=os.path.dirname(os.path.abspath(__file__));sys.path.insert(0,R)
import dg
from curriculum import C
BASE=f"{R}/template.html"   # page shell: styles, scripts and lab code; build.py fills in the lessons
out=sys.argv[sys.argv.index('--out')+1] if '--out' in sys.argv else os.path.join(os.path.dirname(R),"tla-plus-course.html")
only_existing='--partial' in sys.argv
s=open(BASE).read()
ids=[c[0] for c in C];num={k:i+1 for i,k in enumerate(ids)}
errs=[];sections=[];stats={}
for lid,part,title,_,_v in C:
    p=f"{R}/src/{lid}.html"
    if not os.path.exists(p):
        if only_existing: continue
        errs.append(f"missing {p}");continue
    b=open(p).read()
    figs={}
    fp=f"{R}/src/{lid}.figs.py"
    if os.path.exists(fp):
        sp=importlib.util.spec_from_file_location("figs_"+lid.replace('-','_'),fp);m=importlib.util.module_from_spec(sp);n0=len(dg.LINT);sp.loader.exec_module(m);figs=m.FIGS
        for i in range(n0,len(dg.LINT)): dg.LINT[i]=f"{lid}: {dg.LINT[i]}"
    used=set()
    def fig(mm):
        k=mm.group(1)
        if k not in figs: errs.append(f"{lid}: unknown fig {k}");return ""
        used.add(k);svg,cap=figs[k]
        # arrowhead ids must be unique per SVG: url() resolves to the first match, which may sit in a hidden lesson
        mid=re.search(r'<marker id="([^"]+)"',svg)
        if mid: svg=svg.replace(mid.group(1),f"m-{lid}-{k}")
        return f'<figure><div class="dg-scroll">{svg}</div><figcaption>{cap}</figcaption></figure>'
    b=re.sub(r'<!--fig:([\w-]+)-->',fig,b)
    for k in set(figs)-used: errs.append(f"{lid}: fig {k} never placed")
    def ref(mm):
        k=mm.group(1)
        if k not in num: errs.append(f"{lid}: bad lesson ref {k}");return k
        return f'<a href="#{k}">lesson {num[k]}</a>'
    titles={c[0]:c[2] for c in C}
    def tref(mm):
        k=mm.group(1)
        if k not in num: errs.append(f"{lid}: bad lesson ref {k}");return k
        return f'<a href="#{k}">{titles[k]}</a>'
    if lid.startswith('ps-'):
        for k in re.findall(r'\{\{(?:lesson|ref):([\w-]+)\}\}',b):
            if k in num and num[k]>num[lid]: errs.append(f"{lid}: refers forward to {k}; problem sets may use only earlier lessons")
    b=re.sub(r'\{\{ref:([\w-]+)\}\}',tref,b)
    b=re.sub(r'\{\{lesson:([\w-]+)\}\}',ref,b)
    if '{{' in b: errs.append(f"{lid}: leftover {{{{")
    if not b.lstrip().startswith('<h1>'): errs.append(f"{lid}: must start with <h1>")
    if re.search(r'\b[Ll]esson \d',re.sub(r'<a href="#[^"]+">lesson \d+</a>','',b)): errs.append(f"{lid}: hard-coded lesson number; use {{{{lesson:id}}}}")
    stats[lid]=dict(words=len(re.sub(r'<svg.*?</svg>|<[^>]+>',' ',b,flags=re.S).split()),svg=b.count('<svg'))
    if lid.startswith('ps-'):
        probs=re.findall(r'<article class="problem" id="([^"]+)"',b)
        need=5 if lid=='ps-final' else 4
        if len(probs)<need: errs.append(f"{lid}: {len(probs)} problems, need {need}")
        for pid in probs:
            if not pid.startswith(lid+'-'): errs.append(f"{lid}: problem id {pid} must start with {lid}-")
        for art in re.findall(r'<article class="problem".*?</article>',b,flags=re.S):
            pid=re.search(r'id="([^"]+)"',art).group(1)
            if 'class="uses"' not in art: errs.append(f"{pid}: missing <p class=\"uses\">")
            if 'class="answer solution"' not in art: errs.append(f"{pid}: missing solution")
        if b.count('<article class="problem"')!=b.count('</article>'): errs.append(f"{lid}: unbalanced <article>")
        stats[lid]['problems']=len(probs)
        chap=f"Problem set · {part}"
    else: chap=f"Lesson {num[lid]} · {part}"
    sections.append(f'<section class="lesson" id="{lid}" data-part="{part}" data-title="{title}">\n<p class="chapter">{chap}</p>{b}</section>')
# main content
s,n=re.subn(r'<section class="lesson" id="orientation".*?(?=</main>)',lambda m:"\n".join(sections)+"\n",s,count=1,flags=re.S);assert n==1
# styles + counts
s=s.replace('@media(max-width:650px){\n .sidebar details',dg.CSS+open(f'{R}/ps.css').read().strip()+'@media(max-width:650px){\n .sidebar details',1)
s=s.replace('0 / 28 studied',f'0 / {len(C)} studied').replace('max="28"',f'max="{len(C)}"').replace('28 lessons',f'{len(C)} lessons')
# videos
lv={c[0]:c[4] for c in C if c[4]}
s,n=re.subn(r"const lessonVideos=\{.*?\};",lambda m:"const lessonVideos="+json.dumps(lv,separators=(',',':'))+";",s,count=1);assert n==1
s=s.replace("Object.entries(lessonVideos).forEach(([id,keys])=>{\n const lesson=document.getElementById(id);","Object.entries(lessonVideos).forEach(([id,keys])=>{\n const lesson=document.getElementById(id);if(!lesson)return;",1)
# labs
labs="".join(open(f).read()+"\n" for f in sorted(glob.glob(f"{R}/labs/*.js")))
marker="function showLesson(id,focus=false){\n stopVideo();"
if labs: 
    assert s.count(marker)==1
    s=s.replace("const videoPages=",labs+"const videoPages=",1)
# validation
all_ids=re.findall(r'\bid="([^"]+)"',s);d={x for x in all_ids if all_ids.count(x)>1}
if d: errs.append(f"duplicate ids {sorted(d)}")
names=re.findall(r'<input type="radio" name="([^"]+)" value="0"',s);d={x for x in names if names.count(x)>1}
if d: errs.append(f"duplicate quiz names {sorted(d)}")
for e in dg.LINT: errs.append("lint "+e)
open(out,'w').write(s)
print(f"{len(sections)} lessons, {sum(v['svg'] for v in stats.values())} svg, {sum(v['words'] for v in stats.values())} words -> {out}")
for k,v in stats.items(): print(f"  {num[k]:>2} {k:<16} {v['words']:>5}w {v['svg']:>2}svg"+(f" {v['problems']} problems" if 'problems' in v else ""))
if errs:
    print("ERRORS:");[print(" ",e) for e in errs];sys.exit(1)
