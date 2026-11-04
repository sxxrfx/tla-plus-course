// Stepping lab for the alternating bit protocol. Educational model, not TLC.
(function(){
  const root=document.getElementById('abp-lab');if(!root)return;
  const $=id=>document.getElementById(id);
  const CAP=3,NAMES=['Mary','Ted','Ann','Fred'];
  let s;
  const show=p=>'<<"'+p[0]+'", '+p[1]+'>>';
  const same=(p,q)=>p[0]===q[0]&&p[1]===q[1];
  function reset(){
    s={A:['Fred',1],B:['Fred',1],AtoB:[],BtoA:[],n:0,recv:[],msg:'Start: AVar = BVar, both channels empty.',bad:false};
    draw();
  }
  function highLevel(a0,b0){
    if(same(a0,s.A)&&same(b0,s.B))return 'ABSpec sees: stuttering.';
    if(!same(a0,s.A)&&same(b0,s.B)){
      if(same(a0,b0))return 'ABSpec sees: an A step. A chose '+show(s.A)+'.';
      s.bad=true;
      return 'NOT an ABSpec step: A changed AVar while AVar # BVar, so '+show(a0)+' was overwritten without being received.';
    }
    if(!same(s.B,s.A)){s.bad=true;return 'NOT an ABSpec step: B set BVar to '+show(s.B)+', which is not the current AVar.';}
    s.recv.push(s.B[0]);
    return 'ABSpec sees: a B step. B received '+show(s.B)+'.';
  }
  function act(name,f){
    const a0=s.A,b0=s.B;f();
    s.msg=name+'. '+highLevel(a0,b0);draw();
  }
  function lose(ch,i){
    act('LoseMsg removed message '+(i+1)+' of '+ch,()=>{s[ch]=s[ch].filter((_,j)=>j!==i);});
  }
  function fill(id,ch,fmt){
    const box=$(id);box.replaceChildren();
    if(!s[ch].length){const e=document.createElement('span');e.className='chip';e.textContent='empty';box.append(e);return;}
    s[ch].forEach((m,i)=>{
      const b=document.createElement('button');b.type='button';b.className='chip';b.textContent=fmt(m);
      b.setAttribute('aria-label','Lose message '+(i+1)+' on '+ch+': '+fmt(m));
      b.addEventListener('click',()=>lose(ch,i));box.append(b);
    });
  }
  function draw(){
    fill('abp-atob','AtoB',show);fill('abp-btoa','BtoA',String);
    $('abp-asnd').disabled=s.AtoB.length>=CAP;
    $('abp-bsnd').disabled=s.BtoA.length>=CAP;
    $('abp-arcv').disabled=!s.BtoA.length;
    $('abp-brcv').disabled=!s.AtoB.length;
    $('abp-state').textContent='AVar = '+show(s.A)+'\nBVar = '+show(s.B)+'\nB has received: '+(s.recv.length?s.recv.join(', '):'nothing yet');
    $('abp-view').textContent=s.msg;
  }
  $('abp-asnd').addEventListener('click',()=>act('ASnd',()=>{s.AtoB=s.AtoB.concat([s.A]);}));
  $('abp-bsnd').addEventListener('click',()=>act('BSnd',()=>{s.BtoA=s.BtoA.concat([s.B[1]]);}));
  $('abp-arcv').addEventListener('click',()=>act('ARcv',()=>{
    const h=s.BtoA[0];s.BtoA=s.BtoA.slice(1);
    if($('abp-bug').checked||h===s.A[1]){s.A=[NAMES[s.n++%NAMES.length],1-s.A[1]];}
  }));
  $('abp-brcv').addEventListener('click',()=>act('BRcv',()=>{
    const h=s.AtoB[0];s.AtoB=s.AtoB.slice(1);
    if(h[1]!==s.B[1])s.B=h;
  }));
  $('abp-reset').addEventListener('click',reset);
  reset();
})();
