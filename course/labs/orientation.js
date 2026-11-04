// Quicksort lab: the iterative code from the orientation lesson, one choice of interval at a time. Not TLC.
(function(){
  const root=document.getElementById('orientation-qs-lab');
  if(!root)return;
  const byId=id=>document.getElementById(id);
  const NS='http://www.w3.org/2000/svg';
  const svgEl=(tag,attrs,text)=>{const el=document.createElementNS(NS,tag);for(const k in attrs)el.setAttribute(k,attrs[k]);if(text!==undefined)el.textContent=text;return el;};
  // Hoare's partition, exactly as printed in the lesson
  function partition(a,lo,hi){
    const pivot=a[Math.floor((lo+hi)/2)];
    let i=lo-1,j=hi+1;
    for(;;){
      do i++; while(a[i]<pivot);
      do j--; while(a[j]>pivot);
      if(i>=j)return j;
      [a[i],a[j]]=[a[j],a[i]];
    }
  }
  const N=8,X=i=>36+i*72,BW=52,BASE=236,UNIT=20;
  const graph=byId('orientation-qs-graph'),choices=byId('orientation-qs-choices');
  const iv=([lo,hi])=>'['+lo+', '+hi+']';
  const byLo=U=>[...U].sort((x,y)=>x[0]-y[0]);
  const setText=U=>'{'+byLo(U).map(iv).join(', ')+'}';
  let hist,lines;
  function draw(){
    const {a,U,last}=hist[hist.length-1];
    graph.replaceChildren();
    graph.append(svgEl('title',{},'Array '+a.join(', ')+'. Intervals still to sort: '+(U.length?byLo(U).map(iv).join(', '):'none')+'.'));
    const open=new Set();U.forEach(([lo,hi])=>{for(let i=lo;i<=hi;i++)open.add(i);});
    a.forEach((v,i)=>{
      const fresh=last&&last.p!==undefined&&i>=last.lo&&i<=last.hi;
      const style=open.has(i)?'fill:var(--chart-1);opacity:'+(fresh?.85:.4):'fill:var(--success);opacity:.8';
      graph.append(svgEl('rect',{x:X(i),y:BASE-v*UNIT,width:BW,height:v*UNIT,rx:4,style}));
      graph.append(svgEl('text',{x:X(i)+BW/2,y:BASE-v*UNIT-7,'text-anchor':'middle',style:'font-weight:600'},v));
      graph.append(svgEl('text',{x:X(i)+BW/2,y:BASE+18,'text-anchor':'middle',style:'fill:var(--muted);font-size:12px'},i));
    });
    if(last&&last.p!==undefined){
      const x=X(last.p)+BW+10;
      graph.append(svgEl('line',{x1:x,y1:24,x2:x,y2:BASE,style:'stroke:var(--primary);stroke-width:2;stroke-dasharray:5 4'}));
      graph.append(svgEl('text',{x:x+6,y:16,style:'fill:var(--primary);font-size:13px'},'p = '+last.p));
    }
    U.forEach(([lo,hi])=>{
      const x1=X(lo)+2,x2=X(hi)+BW-2,y=BASE+30;
      graph.append(svgEl('path',{d:'M'+x1+' '+(y-6)+'V'+y+'H'+x2+'V'+(y-6),style:'fill:none;stroke:var(--primary);stroke-width:1.5'}));
      graph.append(svgEl('text',{x:(x1+x2)/2,y:y+19,'text-anchor':'middle',style:'fill:var(--primary);font-size:13px'},iv([lo,hi])));
    });
    choices.replaceChildren();
    const label=document.createElement('span');label.textContent=U.length?'Choose':'U is empty';choices.append(label);
    byLo(U).forEach(I=>{const b=document.createElement('button');b.type='button';b.textContent=iv(I);
      b.addEventListener('click',()=>step(U.findIndex(J=>J[0]===I[0]&&J[1]===I[1]),''));choices.append(b);});
    byId('orientation-qs-stack').disabled=byId('orientation-qs-queue').disabled=!U.length;
    byId('orientation-qs-undo').disabled=hist.length<2;
    byId('orientation-qs-trace').textContent=lines.join('\n');
  }
  function status(msg,cls){const el=byId('orientation-qs-status');el.textContent=msg;el.classList.toggle('good',cls==='good');}
  // why: '' when the reader picked, else a sentence on which interval the stack or queue took
  function step(k,why){
    const {a,U}=hist[hist.length-1];
    if(k<0||k>=U.length)return;
    const [lo,hi]=U[k],a2=[...a],U2=U.filter((_,j)=>j!==k);
    if(lo<hi){
      const pivot=a2[Math.floor((lo+hi)/2)],p=partition(a2,lo,hi);
      U2.push([lo,p],[p+1,hi]);
      hist.push({a:a2,U:U2,last:{lo,hi,p}});
      lines.push(iv([lo,hi])+' p='+p+'  A=['+a2.join(',')+']  U='+setText(U2).replace(/ /g,''));
      status(why+'Partitioned '+iv([lo,hi])+' around the pivot '+pivot+'. Every value in '+iv([lo,p])+' is at most every value in '+iv([p+1,hi])+', and both go back into U.');
    }else{
      hist.push({a:a2,U:U2,last:{lo,hi}});
      lines.push(iv([lo,hi])+' done  U='+setText(U2).replace(/ /g,''));
      status(why+iv([lo,hi])+' has one element, so it is already sorted. Bar '+lo+' is in its final place.');
    }
    if(!U2.length){draw();status('U is empty and the array is sorted, after '+(hist.length-1)+' steps. Restart with the other button and compare the readouts.','good');return;}
    draw();
  }
  function start(a){hist=[{a,U:[[0,a.length-1]],last:null}];lines=['A=['+a.join(',')+']  U={[0,'+(a.length-1)+']}'];draw();
    status('U holds the whole array. Choose an interval to partition, or let a stack or a queue choose.');}
  let first=[3,7,8,5,2,1,9,6];
  byId('orientation-qs-stack').addEventListener('click',()=>{const U=hist[hist.length-1].U;step(U.length-1,'Newest: '+iv(U[U.length-1])+' was added to U most recently. ');});
  byId('orientation-qs-queue').addEventListener('click',()=>{const U=hist[hist.length-1].U;step(0,'Oldest: '+iv(U[0])+' has been in U longest. ');});
  byId('orientation-qs-undo').addEventListener('click',()=>{if(hist.length<2)return;hist.pop();lines.pop();draw();status('Stepped back.');});
  byId('orientation-qs-restart').addEventListener('click',()=>start([...first]));
  byId('orientation-qs-new').addEventListener('click',()=>{let a;do a=Array.from({length:N},()=>1+Math.floor(Math.random()*9));while(a.every((v,i)=>!i||a[i-1]<=v));first=a;start([...a]);});
  start([...first]);
})();
