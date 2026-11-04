// Problem sets: "Mark solved" per problem, a solved count per set, and numeric/short answer checks.
(function(){
  const sets=[...document.querySelectorAll('.lesson')].filter(l=>l.querySelector('.problem'));
  if(!sets.length)return;
  const norm=v=>v.trim().toLowerCase().replace(/[\s,_]/g,'');
  sets.forEach(set=>{
    const problems=[...set.querySelectorAll('.problem')];
    const summary=document.createElement('p');summary.className='ps-progress';summary.setAttribute('aria-live','polite');
    const lead=set.querySelector('.lead');(lead||set.querySelector('h1')).after(summary);
    function count(){
      const solved=problems.filter(p=>state.answers['solved_'+p.id]==='1').length;
      summary.replaceChildren();const strong=document.createElement('strong');strong.textContent=solved+' of '+problems.length;
      summary.append(strong,document.createTextNode(' problems marked solved in this set.'));
    }
    problems.forEach(problem=>{
      const footer=document.createElement('div');footer.className='problem-footer';
      const box=document.createElement('input');box.type='checkbox';
      box.checked=state.answers['solved_'+problem.id]==='1';problem.classList.toggle('solved',box.checked);
      footer.append(completeToggle(box,'Mark as solved','Solved',true));problem.append(footer);
      box.addEventListener('change',()=>{state.answers['solved_'+problem.id]=box.checked?'1':'0';problem.classList.toggle('solved',box.checked);count();save();});
    });
    set.querySelectorAll('.numcheck').forEach((check,index)=>{
      const input=check.querySelector('input'),button=check.querySelector('button'),feedback=check.querySelector('.quiz-feedback');
      const id=set.id+'-n'+index,accepted=check.dataset.answer.split('|').map(norm);
      // question on its own line; the field and its button side by side
      const row=document.createElement('div');row.className='numcheck-row';input.id=id+'-input';check.querySelector('label').htmlFor=input.id;check.querySelector('label').after(row);row.append(input,button);
      if(typeof state.answers[id]==='string')input.value=state.answers[id];
      const run=()=>{
        if(!input.value.trim()){feedback.textContent='Enter an answer first.';feedback.className='quiz-feedback';return;}
        const ok=accepted.includes(norm(input.value));
        feedback.textContent=(ok?'Correct. ':'Not quite. ')+(ok?check.dataset.explain:(check.dataset.retry||'Check your reasoning, or open the hint.'));
        feedback.className='quiz-feedback '+(ok?'good':'bad');state.answers[id]=input.value.trim().slice(0,128);save();
      };
      button.addEventListener('click',run);input.addEventListener('keydown',e=>{if(e.key==='Enter'){e.preventDefault();run();}});
    });
    count();
  });
})();
