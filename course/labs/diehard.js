// Die Hard stepping lab: a small JavaScript model of the jug rules, not TLC.
(function(){
  const root=document.getElementById('diehard-lab');
  if(!root)return;
  const byId=id=>document.getElementById(id);
  const NS='http://www.w3.org/2000/svg';
  const svgEl=(tag,attrs,text)=>{const el=document.createElementNS(NS,tag);for(const k in attrs)el.setAttribute(k,attrs[k]);if(text!==undefined)el.textContent=text;return el;};
  const ACTIONS={
    FillSmall:(s,b)=>[3,b],
    FillBig:(s,b)=>[s,5],
    EmptySmall:(s,b)=>[0,b],
    EmptyBig:(s,b)=>[s,0],
    SmallToBig:(s,b)=>b+s<=5?[0,b+s]:[s-(5-b),5],
    BigToSmall:(s,b)=>b+s<=3?[b+s,0]:[3,s-(3-b)]
  };
  const names=Object.keys(ACTIONS);
  const key=(s,b)=>s+','+b;
  // Breadth-first search over the model: reachable states and shortest distance to big = 4.
  const dist=new Map([[key(0,0),0]]);const queue=[[0,0]];let goalDist=null;
  while(queue.length){const [s,b]=queue.shift();const d=dist.get(key(s,b));
    if(b===4&&goalDist===null)goalDist=d;
    for(const n of names){const [s2,b2]=ACTIONS[n](s,b);if(!dist.has(key(s2,b2))){dist.set(key(s2,b2),d+1);queue.push([s2,b2]);}}}
  const X=b=>168+b*88,Y=s=>48+(3-s)*70,R=20;
  const graph=byId('diehard-graph');
  let path,steps;
  function line(a,b,style,marker){
    const x1=X(a[1]),y1=Y(a[0]),x2=X(b[1]),y2=Y(b[0]),dx=x2-x1,dy=y2-y1,len=Math.hypot(dx,dy)||1;
    // Same row or column more than one cell apart: curve into the empty middle so the arrow doesn't cross a node.
    const skip=(a[0]===b[0]&&Math.abs(a[1]-b[1])>1)||(a[1]===b[1]&&Math.abs(a[0]-b[0])>1);
    if(skip){
      const cx=(x1+x2)/2+(a[1]===b[1]?(a[1]===0?46:-46):0),cy=(y1+y2)/2+(a[0]===b[0]?(a[0]===0?-46:46):0);
      const ax=cx-x1,ay=cy-y1,al=Math.hypot(ax,ay),bx=cx-x2,by=cy-y2,bl=Math.hypot(bx,by);
      const d='M'+(x1+ax/al*(R+1))+' '+(y1+ay/al*(R+1))+'Q'+cx+' '+cy+' '+(x2+bx/bl*(R+5))+' '+(y2+by/bl*(R+5));
      return svgEl('path',{d,style:'fill:none;'+style,'marker-end':marker});
    }
    return svgEl('line',{x1:x1+dx/len*(R+1),y1:y1+dy/len*(R+1),x2:x2-dx/len*(R+5),y2:y2-dy/len*(R+5),style,'marker-end':marker});
  }
  function jug(x,cap,amount,label){
    const unit=30,base=266,w=38,top=base-cap*unit;
    graph.append(svgEl('rect',{x,y:top,width:w,height:cap*unit,rx:4,style:'fill:var(--secondary);stroke:var(--border)'}));
    if(amount>0)graph.append(svgEl('rect',{x:x+1,y:base-amount*unit,width:w-2,height:amount*unit,rx:3,style:'fill:var(--chart-1);opacity:.75'}));
    graph.append(svgEl('text',{x:x+w/2,y:base+20,'text-anchor':'middle'},label+' '+amount));
  }
  function draw(){
    const [cs,cb]=path[path.length-1];
    graph.replaceChildren();
    graph.append(svgEl('title',{},'State graph of the jugs. Current state: small '+cs+', big '+cb+'. Steps taken: '+steps.length+'.'));
    const defs=svgEl('defs',{});
    [['diehard-ah','var(--muted)'],['diehard-ah2','var(--primary)']].forEach(([id,fill])=>{
      const m=svgEl('marker',{id,viewBox:'0 0 10 10',refX:8,refY:5,markerWidth:6,markerHeight:6,orient:'auto-start-reverse'});
      m.append(svgEl('path',{d:'M0 0L10 5L0 10z',style:'fill:'+fill}));defs.append(m);});
    graph.append(defs);
    jug(14,3,cs,'small');jug(72,5,cb,'big');
    for(let b=0;b<=5;b++)graph.append(svgEl('text',{x:X(b),y:16,'text-anchor':'middle',style:'fill:var(--muted);font-size:12px'},'big '+b));
    if(byId('diehard-all').checked){
      dist.forEach((_,k)=>{const [s,b]=k.split(',').map(Number);
        for(const n of names){const [s2,b2]=ACTIONS[n](s,b);if(s2!==s||b2!==b)graph.append(line([s,b],[s2,b2],'stroke:var(--border);stroke-width:1'));}});
    }
    for(const n of names){const [s2,b2]=ACTIONS[n](cs,cb);if(s2!==cs||b2!==cb)graph.append(line([cs,cb],[s2,b2],'stroke:var(--muted);stroke-width:1.5;stroke-dasharray:4 4','url(#diehard-ah)'));}
    for(let i=1;i<path.length;i++){if(key(...path[i-1])!==key(...path[i]))graph.append(line(path[i-1],path[i],'stroke:var(--primary);stroke-width:2.5','url(#diehard-ah2)'));}
    const seen=new Set(path.map(p=>key(...p)));
    for(let s=0;s<=3;s++)for(let b=0;b<=5;b++){
      if(!dist.has(key(s,b))){graph.append(svgEl('circle',{cx:X(b),cy:Y(s),r:3,style:'fill:var(--border)'}));continue;}
      const cur=s===cs&&b===cb,goal=b===4;
      let style='fill:var(--secondary);stroke:var(--border)';
      if(seen.has(key(s,b)))style='fill:var(--accent);stroke:var(--primary)';
      if(goal)style=(seen.has(key(s,b))?'fill:color-mix(in srgb,var(--success) 25%,var(--card))':'fill:var(--card)')+';stroke:var(--success);stroke-width:2';
      if(cur)style+=';stroke-width:3.5'+(goal?'':';stroke:var(--primary)');
      graph.append(svgEl('circle',{cx:X(b),cy:Y(s),r:R,style}));
      graph.append(svgEl('text',{x:X(b),y:Y(s)+5,'text-anchor':'middle',style:'font-size:13px'},s+','+b));
    }
    byId('diehard-undo').disabled=steps.length===0;
    const out=byId('diehard-trace');
    out.textContent='(small,big)  ('+path[0].join(',')+')'+steps.map((n,i)=>'\n'+n+' -> ('+path[i+1].join(',')+')').join('');
  }
  function status(msg,cls){const el=byId('diehard-status');el.textContent=msg;el.classList.toggle('good',cls==='good');el.classList.toggle('bad',cls==='bad');}
  function restart(){path=[[0,0]];steps=[];draw();status('Both jugs empty. Dashed arrows show where the next step can go. Predict one, then press its button.');}
  names.forEach(n=>byId('diehard-'+n).addEventListener('click',()=>{
    const [s,b]=path[path.length-1],[s2,b2]=ACTIONS[n](s,b);
    path.push([s2,b2]);steps.push(n);draw();
    if(b2===4)status('big = 4 after '+steps.length+' steps. The fewest possible in this model is '+goalDist+'.','good');
    else if(s2===s&&b2===b)status(n+' is allowed here, but it leaves both jugs as they were. The step is in the behavior; nothing moved.');
    else status(n+': small '+s+' to '+s2+', big '+b+' to '+b2+'.');
  }));
  byId('diehard-undo').addEventListener('click',()=>{if(!steps.length)return;path.pop();steps.pop();draw();status('Stepped back.');});
  byId('diehard-reset').addEventListener('click',restart);
  byId('diehard-all').addEventListener('change',draw);
  restart();
})();
