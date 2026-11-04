import sys,os,math; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions,_svg,_text
RM=[2,3,4,5,6,7,8]
plain=[56,288,1568,8832,50816,296448,1745408]
sym=[34,80,166,314,553,920,1461]
W,H=680,300;L,R,T,B=82,120,18,40
X=lambda i:L+(W-L-R)*i/(len(RM)-1)
Y=lambda v:T+(H-T-B)*(1-(math.log10(v)-1)/6)
b=[]
for e in range(1,8):
    y=Y(10**e);b.append(f'<line x1="{L}" y1="{y:.1f}" x2="{W-R}" y2="{y:.1f}" class="dg-life"/>')
    b.append(_text(L-8,y,f"{10**e:,}",anchor="end",cls="dg-t dg-sm",size=12))
for i,n in enumerate(RM): b.append(_text(X(i),H-B+16,str(n),cls="dg-t dg-sm",size=12))
b.append(_text((L+W-R)/2,H-8,"Resource managers",cls="dg-t dg-sm",size=12))
def series(vals,dash,shape,name,lab):
    pts=" ".join(f"{X(i):.1f},{Y(v):.1f}" for i,v in enumerate(vals))
    d=' stroke-dasharray="6 5"' if dash else ""
    s=[f'<polyline points="{pts}" fill="none" stroke="var(--primary)" stroke-width="2"{d}/>']
    for i,v in enumerate(vals):
        x,y=X(i),Y(v);t=f'<title>{RM[i]} RMs, {name}: {v:,} distinct states</title>'
        if shape=="c": s.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="5" fill="var(--primary)" stroke="var(--background)" stroke-width="2">{t}</circle>')
        else: s.append(f'<rect x="{x-5:.1f}" y="{y-5:.1f}" width="10" height="10" rx="2" fill="var(--background)" stroke="var(--primary)" stroke-width="2">{t}</rect>')
    s.append(_text(X(6)+12,Y(vals[-1]),lab,anchor="start",size=12))
    return "".join(s)
b.append(series(plain,False,"c","no symmetry","1,745,408\nno symmetry"));b.append(series(sym,True,"s","symmetry","1,461\nsymmetry"))
chart=_svg(W,H,"".join(b),"Line chart on a logarithmic axis of distinct states TLC found for two-phase commit, from 2 to 8 resource managers. Without symmetry the count rises from 56 to 1,745,408, a nearly straight line, so roughly exponential. With symmetry it rises from 34 to 1,461.")
race=sequence(["Origin","Edge"],[("Edge","Origin","fetch"),("Origin","Edge","v1 in flight",{"dash":True}),("note","Origin","publish v2"),("Origin","Edge","invalidate through v1"),("note","Edge","cached copy removed"),("Origin","Edge","v1 arrives",{"tone":"bad"}),("note","Edge","cached = v1, floor = 1","bad")],
 "The race: a fetch for version 1 is in flight while version 2 is published and version 1 invalidated. When the old response arrives the cache fills with the invalidated version.",gap=300,step=38)
cut=graph({"a":(70,40,"origin 1\ncached 1"),"b":(70,140,"origin 1, v1\nin flight"),"c":(280,140,"origin 2\ncached 1","muted"),"d":(470,140,"floor 1\nno copy","muted"),"e":(620,140,"cached 1\nfloor 1","bad")},
 [("a","b","Fetch"),("b","c","Publish",{"dash":True}),("c","d","Invalidate",{"dash":True}),("d","e","Fill",{"dash":True})],
 "With the constraint, TLC explores the first two states. Publish leads to a state where the cache differs from the origin, which the constraint removes, so the failing state is never visited.")
FIGS={"chart":(chart,"Distinct states TLC found for two-phase commit, on a logarithmic axis. On this axis, a straight line means exponential growth."),
"race":(race,"The race, in the order TLC’s 4-step trace finds it. Removing a cached object does not cancel an older response already in flight."),
"cut":(cut,"The same failing path as the previous diagram, seen by a constrained run. TLC keeps only the first two states; the dashed path is never explored.")}
FIGS={k:(v[0].replace("dg-a\"",f"dg-a-scl-{k}\"").replace("#dg-a)",f"#dg-a-scl-{k})"),v[1]) for k,v in FIGS.items()}
