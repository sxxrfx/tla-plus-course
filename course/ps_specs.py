"""Checks every complete module printed in the problem sets: identical to a checked file in specs/, or at least parsed by SANY.
usage: python3 ps_specs.py [course.html]"""
import re,html,glob,os,subprocess,tempfile,sys
R=os.path.dirname(os.path.abspath(__file__));os.chdir(R)
JAR=os.environ.get('TLA2TOOLS',os.path.join(R,'tla2tools.jar'))
s=open(sys.argv[1] if len(sys.argv)>1 else os.path.join(R,'..','tla-plus-course.html')).read()
norm=lambda t:re.sub(r'\s+',' ',t).strip()
files={norm(open(f).read()):f for f in glob.glob('specs/*.tla')}
sets=re.findall(r'<section class="lesson" id="(ps-[\w-]+)".*?</section>',s,flags=re.S)
tot=match=0;bad=[]
for sec in re.finditer(r'<section class="lesson" id="(ps-[\w-]+)"(.*?)</section>',s,flags=re.S):
    for code in re.findall(r'<pre><code>(.*?)</code></pre>',sec.group(2),flags=re.S):
        t=html.unescape(code)
        for m in re.finditer(r'-{4,}\s*MODULE\s+(\w+)\s*-{4,}.*?\n={4,}',t,flags=re.S):
            tot+=1;mod=m.group(0);name=m.group(1)
            if norm(mod) in files: match+=1;continue
            # not byte-identical to a checked file: at least parse it with SANY
            d=tempfile.mkdtemp();open(f"{d}/{name}.tla","w").write(mod)
            for f in glob.glob('specs/*.tla'):
                b=os.path.basename(f)
                if b!=name+'.tla': os.symlink(os.path.abspath(f),f"{d}/{b}")
            if re.search(r'--(fair )?algorithm',mod) and 'BEGIN TRANSLATION' not in mod and os.path.exists(f'specs/{name}.tla'):
                # PlusCal printed without its translation: translating it must give the checked file
                subprocess.run(['java','-cp',JAR,'pcal.trans','-nocfg',f'{name}.tla'],cwd=d,capture_output=True)
                strip=lambda x:re.sub(r'\s+',' ',re.sub(r'\(chksum[^)]*\)','',x)).strip()
                if strip(open(f"{d}/{name}.tla").read())==strip(open(f'specs/{name}.tla').read()): match+=1;continue
            r=subprocess.run(['java','-cp',JAR,'tla2sany.SANY',f'{name}.tla'],cwd=d,capture_output=True,text=True)
            ok=r.returncode==0 and 'Semantic processing of module '+name in r.stdout and '*** Errors' not in r.stdout and 'Fatal' not in r.stdout
            close=[f for k,f in files.items() if os.path.basename(f)==name+'.tla']
            bad.append((sec.group(1),name,'parses' if ok else 'PARSE FAIL',close[0] if close else 'no file'))
print(f"{tot} printed modules, {match} identical to a checked spec file (PlusCal after translation)")
for b in bad: print(' ',*b)
