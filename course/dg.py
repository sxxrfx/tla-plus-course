"""Static SVG diagrams for the TLA+ course. Colours come from CSS classes, so they follow the light/dark theme.

Every function returns an SVG string. Keep width <= 720. Use \\n in labels for multiple lines.
Tones: "" (default), "good", "bad", "accent", "muted".
Approximate text fit is linted: problems are collected in LINT and printed by build.py (a build with lint errors fails).
"""
import math
from html import escape
LINT=[]
CHAR=7.0   # mean px per char at 13px sans
MONO=7.9   # px per char at 13px mono
def _w(text,mono=False,size=13):
    return len(text)*(MONO if mono else CHAR)*size/13
def _text(x,y,label,cls="dg-t",anchor="middle",mono=False,size=13,lh=17):
    lines=str(label).split("\n");out=[]
    y0=y-(len(lines)-1)*lh/2
    c=cls+(" dg-mono" if mono else "")
    st=f' style="font-size:{size}px"' if size!=13 else ""
    for i,l in enumerate(lines):
        out.append(f'<text x="{x:.1f}" y="{y0+i*lh:.1f}" class="{c}" text-anchor="{anchor}" dominant-baseline="central"{st}>{escape(l)}</text>')
    return "".join(out)
def _svg(w,h,body,label):
    if not label: LINT.append("diagram without label (alt text)")
    return f'<svg class="dg" viewBox="0 0 {w:.0f} {h:.0f}" width="{w:.0f}" role="img" aria-label="{escape(label,quote=True)}"><defs><marker id="dg-a" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0 0L10 5L0 10z" class="dg-head"/></marker></defs>{body}</svg>'
def _clip(cx,cy,hw,hh,tx,ty):
    dx,dy=tx-cx,ty-cy
    if dx==0 and dy==0: return cx,cy
    s=min(hw/abs(dx) if dx else 1e9, hh/abs(dy) if dy else 1e9)
    return cx+dx*s,cy+dy*s
def graph(nodes,edges,label,width=None,height=None,mono=False):
    """State/flow graph.
    nodes: {id:(x,y,"text") or (x,y,"text",tone)}; x,y = node centre. Boxes size themselves to the text.
    edges: (a,b) | (a,b,"label") | (a,b,"label",{"tone":..,"bend":px,"dash":True,"lx":dx,"ly":dy})
      bend curves the edge sideways by px (use for a<->b pairs); a==b draws a self-loop above the node; lx/ly nudge the label.
    """
    box={}
    for k,n in nodes.items():
        x,y,t=n[0],n[1],n[2];lines=str(t).split("\n")
        hw=max(_w(l,mono) for l in lines)/2+12;hh=len(lines)*17/2+8
        box[k]=(x,y,hw,hh,t,n[3] if len(n)>3 else "")
    W=width or max(b[0]+b[2] for b in box.values())+14
    H=height or max(b[1]+b[3] for b in box.values())+14
    ks=list(box)
    for i,a in enumerate(ks):
        A=box[a]
        if A[0]-A[2]<0 or A[1]-A[3]<0 or A[0]+A[2]>W or A[1]+A[3]>H: LINT.append(f"node {a!r} outside canvas in {label[:40]!r}")
        for b in ks[i+1:]:
            B=box[b]
            if abs(A[0]-B[0])<A[2]+B[2]+4 and abs(A[1]-B[1])<A[3]+B[3]+4: LINT.append(f"nodes {a!r},{b!r} overlap in {label[:40]!r}")
    if W>720: LINT.append(f"width {W:.0f} > 720 in {label[:40]!r}")
    body=[];labels=[];boxes=[]
    for e in edges:
        a,b=e[0],e[1];txt=e[2] if len(e)>2 else "";o=e[3] if len(e)>3 else {}
        A,B=box[a],box[b];tone=o.get("tone","");dash=' stroke-dasharray="5 4"' if o.get("dash") else ""
        cls=f'dg-e {("dg-"+tone) if tone else ""}'
        if a==b:
            x,y,hw,hh=A[0],A[1],A[2],A[3]
            d=f"M{x-14:.1f} {y-hh:.1f}C{x-34:.1f} {y-hh-34:.1f} {x+34:.1f} {y-hh-34:.1f} {x+14:.1f} {y-hh:.1f}"
            lx,ly=x,y-hh-36
        else:
            bend=o.get("bend",0)
            mx,my=(A[0]+B[0])/2,(A[1]+B[1])/2
            dx,dy=B[0]-A[0],B[1]-A[1];L=math.hypot(dx,dy) or 1
            cx,cy=mx-dy/L*bend,my+dx/L*bend
            x1,y1=_clip(A[0],A[1],A[2]+1,A[3]+1,cx,cy);x2,y2=_clip(B[0],B[1],B[2]+3,B[3]+3,cx,cy)
            d=f"M{x1:.1f} {y1:.1f}Q{cx:.1f} {cy:.1f} {x2:.1f} {y2:.1f}" if bend else f"M{x1:.1f} {y1:.1f}L{x2:.1f} {y2:.1f}"
            lx,ly=(x1+2*cx+x2)/4 if bend else (x1+x2)/2,(y1+2*cy+y2)/4 if bend else (y1+y2)/2
        body.append(f'<path d="{d}" class="{cls}" marker-end="url(#dg-a)"{dash}/>')
        if txt:
            lx+=o.get("lx",0);ly+=o.get("ly",0)
            lines=str(txt).split("\n");tw=max(_w(l,size=12) for l in lines)+8;th=len(lines)*15+2
            labels.append(f'<rect x="{lx-tw/2:.1f}" y="{ly-th/2:.1f}" width="{tw:.1f}" height="{th:.1f}" class="dg-lbg"/>'+_text(lx,ly,txt,cls="dg-t dg-sm"+(f" dg-t-{tone}" if tone else ""),size=12,lh=15))
            boxes.append((lx,ly,tw/2,th/2,txt))
            if lx-tw/2<0 or lx+tw/2>W or ly-th/2<0 or ly+th/2>H: LINT.append(f"edge label {txt!r} outside canvas in {label[:40]!r}")
    for i,p in enumerate(boxes):
        for q in boxes[i+1:]:
            if abs(p[0]-q[0])<p[2]+q[2] and abs(p[1]-q[1])<p[3]+q[3]: LINT.append(f"edge labels {p[4]!r},{q[4]!r} overlap in {label[:40]!r}")
        for k,B in box.items():
            if abs(p[0]-B[0])<p[2]+B[2] and abs(p[1]-B[1])<p[3]+B[3]: LINT.append(f"edge label {p[4]!r} overlaps node {k!r} in {label[:40]!r}")
    for k,B in box.items():
        x,y,hw,hh,t,tone=B
        body.append(f'<rect x="{x-hw:.1f}" y="{y-hh:.1f}" width="{2*hw:.1f}" height="{2*hh:.1f}" rx="7" class="dg-n {("dg-"+tone) if tone else ""}"/>'+_text(x,y,t,mono=mono))
    return _svg(W,H,"".join(body)+"".join(labels),label)
def sequence(actors,msgs,label,gap=None,step=44):
    """Message sequence chart. actors: names. msgs: (from,to,"label") | (from,to,"label",{"tone":..,"dash":True,"lost":True})
    or ("note",actor,"text") / ("note",actor,"text",tone). from==to draws a local step note. lost stops the arrow part-way with an X."""
    n=len(actors);gap=gap or min(180,(700-120)/max(1,n-1));x0=60+ (0 if n>1 else 200)
    xs={a:x0+i*gap for i,a in enumerate(actors)}
    W=x0*2+(n-1)*gap;H=48+step*len(msgs)+20
    if W>720: LINT.append(f"sequence width {W:.0f} > 720 in {label[:40]!r}")
    b=[]
    for a,x in xs.items():
        if _w(a)+18>max(gap,110): LINT.append(f"actor name {a!r} too wide in {label[:40]!r}")
        b.append(f'<line x1="{x}" y1="38" x2="{x}" y2="{H-8}" class="dg-life"/>')
        hw=_w(a)/2+9
        b.append(f'<rect x="{x-hw:.1f}" y="8" width="{2*hw:.1f}" height="30" rx="6" class="dg-n dg-accent"/>'+_text(x,23,a))
    y=48+step/2
    for m in msgs:
        o=m[3] if len(m)>3 and isinstance(m[3],dict) else {}
        if m[0]=="note":
            x=xs[m[1]];t=m[2];tone=m[3] if len(m)>3 and isinstance(m[3],str) else ""
            hw=_w(t,size=12)/2+8
            x=max(hw+2,min(W-hw-2,x))
            b.append(f'<rect x="{x-hw:.1f}" y="{y-12:.1f}" width="{2*hw:.1f}" height="24" rx="5" class="dg-n {("dg-"+tone) if tone else "dg-muted"}"/>'+_text(x,y,t,size=12))
        else:
            x1,x2=xs[m[0]],xs[m[1]];tone=o.get("tone","");cls=f'dg-e {("dg-"+tone) if tone else ""}'
            dash=' stroke-dasharray="5 4"' if o.get("dash") else ""
            if _w(m[2],size=12)>abs(x2-x1)+60: LINT.append(f"message label {m[2]!r} wider than its arrow in {label[:40]!r}")
            if o.get("lost"):
                xe=x1+(x2-x1)*.6
                b.append(f'<line x1="{x1}" y1="{y+7:.1f}" x2="{xe:.1f}" y2="{y+7:.1f}" class="{cls}"{dash}/><path d="M{xe-5:.1f} {y+2:.1f}l10 10m0-10l-10 10" class="dg-e dg-bad"/>')
            else:
                b.append(f'<line x1="{x1}" y1="{y+7:.1f}" x2="{x2+(-3 if x2>x1 else 3)}" y2="{y+7:.1f}" class="{cls}" marker-end="url(#dg-a)"{dash}/>')
            b.append(_text((x1+x2)/2,y-6,m[2],cls="dg-t dg-sm"+(f" dg-t-{tone}" if tone else ""),size=12))
        y+=step
    return _svg(W,H,"".join(b),label)
def lanes(rows,label,cols=None,cell=None,labelw=110,rowh=34):
    """Timeline/behaviour grid. rows: ("name",[cell,...]); cell = "text" or ("text",tone) or None. cols: optional header list.
    Good for traces: one column per state, one row per variable."""
    n=max(len(r[1]) for r in rows);m=max((_w(c[0] if isinstance(c,tuple) else c,True) for r in rows for c in r[1] if c),default=20)
    cell=cell or max(46,m+14);W=labelw+n*cell+6;top=26 if cols else 4;H=top+len(rows)*rowh+6
    if W>720: LINT.append(f"lanes width {W:.0f} > 720 in {label[:40]!r}")
    b=[]
    if cols:
        for i,c in enumerate(cols): b.append(_text(labelw+i*cell+cell/2,13,c,cls="dg-t dg-sm",size=12))
    for j,(name,cells) in enumerate(rows):
        y=top+j*rowh
        b.append(_text(labelw-8,y+rowh/2,name,anchor="end"))
        for i,c in enumerate(cells):
            if c is None: continue
            t,tone=c if isinstance(c,tuple) else (c,"")
            b.append(f'<rect x="{labelw+i*cell+2}" y="{y+3}" width="{cell-4}" height="{rowh-6}" rx="5" class="dg-n {("dg-"+tone) if tone else ""}"/>'+_text(labelw+i*cell+cell/2,y+rowh/2,t,mono=True))
    return _svg(W,H,"".join(b),label)
def regions(boxes,label,width=680,height=240,notes=()):
    """Nested or overlapping regions (sets, quorums, containment, layers).
    boxes: (x,y,w,h,"title",tone) drawn in order. notes: (x,y,"text") or (x,y,"text",tone) free labels; (x1,y1,x2,y2,"text") draws a pointer line ending at x2,y2."""
    if width>720: LINT.append(f"width {width} > 720 in {label[:40]!r}")
    b=[]
    for x,y,w,h,t,*tone in boxes:
        tn=tone[0] if tone else ""
        if x<0 or y<0 or x+w>width or y+h>height: LINT.append(f"region {t!r} outside canvas in {label[:40]!r}")
        b.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" class="dg-r {("dg-"+tn) if tn else ""}"/>')
        if t:
            if _w(t)>w-16: LINT.append(f"region title {t!r} wider than its box in {label[:40]!r}")
            b.append(_text(x+12,y+15,t,anchor="start"))
    for nt in notes:
        if len(nt)==5:
            x1,y1,x2,y2,t=nt
            b.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" class="dg-e dg-muted-line" marker-end="url(#dg-a)"/>'+_text(x1,y1-10,t,size=12,cls="dg-t dg-sm"))
        else:
            x,y,t,*tone=nt
            b.append(_text(x,y,t,cls="dg-t"+(f" dg-t-{tone[0]}" if tone else "")))
    return _svg(width,height,"".join(b),label)
CSS=""".dg{display:block;max-width:100%;height:auto;margin:auto}.dg-scroll{overflow-x:auto}.dg-t{fill:var(--foreground);font:13px var(--font-sans)}.dg-sm{fill:var(--muted);font-size:12px}.dg-mono{font-family:var(--font-mono)}.dg-n{fill:var(--secondary);stroke:var(--border)}.dg-r{fill:var(--secondary);fill-opacity:.45;stroke:var(--border)}.dg-e{fill:none;stroke:var(--muted);stroke-width:1.5}.dg-head{fill:var(--muted)}.dg-lbg{fill:var(--background)}.dg-life{stroke:var(--border);stroke-dasharray:3 4}.dg-n.dg-good,.dg-r.dg-good{fill:color-mix(in srgb,var(--success) 18%,var(--card));stroke:var(--success)}.dg-n.dg-bad,.dg-r.dg-bad{fill:color-mix(in srgb,var(--destructive) 16%,var(--card));stroke:var(--destructive)}.dg-n.dg-accent,.dg-r.dg-accent{fill:var(--accent);stroke:var(--primary)}.dg-n.dg-muted,.dg-r.dg-muted{fill:var(--card);stroke:var(--border)}.dg-e.dg-good{stroke:var(--success)}.dg-e.dg-bad{stroke:var(--destructive)}.dg-e.dg-accent{stroke:var(--primary)}.dg-t-good{fill:var(--success)}.dg-t-bad{fill:var(--destructive)}.dg-t-accent{fill:var(--primary)}.dg-muted-line{stroke:var(--border)}@media(max-width:650px){.dg-scroll .dg{min-width:520px;max-width:none}}
"""
