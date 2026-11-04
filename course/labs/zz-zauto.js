// Automatic completion from what the learner does. A problem ticks itself when every check in it is correct;
// a lesson when its end has been reached and every quiz on it is correct; a problem set when all its problems are solved.
// A box the learner unticks by hand (stored as false or '0') is never ticked automatically again.
(function(){
  const norm=v=>String(v).trim().toLowerCase().replace(/[\s,_]/g,'');
  const quizKey=new Map();
  document.querySelectorAll('.quiz').forEach((quiz,index)=>quizKey.set(quiz,quiz.closest('.lesson').id+'-'+index));
  const numKey=new Map();
  lessons.forEach(lesson=>lesson.querySelectorAll('.numcheck').forEach((check,index)=>numKey.set(check,lesson.id+'-n'+index)));
  const correct=el=>el.classList.contains('quiz')
    ?state.answers[quizKey.get(el)]===el.dataset.answer
    :typeof state.answers[numKey.get(el)]==='string'&&el.dataset.answer.split('|').map(norm).includes(norm(state.answers[numKey.get(el)]));
  const checks=root=>[...root.querySelectorAll('.quiz,.numcheck')];
  const isSet=lesson=>!!lesson.querySelector('.problem');
  const openedAt={};
  const DWELL=30000;
  function note(lesson){
    let el=lesson.querySelector(':scope>.auto-note');
    if(!el){el=document.createElement('p');el.className='auto-note';el.setAttribute('aria-live','polite');lesson.querySelector(':scope>.lesson-footer').before(el);}
    return el;
  }
  // the rule and its outcome, shown beside the completion button (the live region above is for screen readers)
  function caption(container,first){
    let el=container.querySelector('.complete-caption');
    if(!el){el=document.createElement('span');el.className='complete-caption';el.setAttribute('aria-hidden','true');first?container.prepend(el):container.append(el);}
    return el;
  }
  function show(el,text,auto){if(el.textContent===text)return;el.textContent=text;el.classList.toggle('good',!!auto);if(text)replay(el);}
  const AUTO='Completed automatically';
  function describe(lesson,justMarked){
    const done=state.done[lesson.id];let text;
    if(justMarked)text=AUTO+(isSet(lesson)?': every problem in this set is solved.':checks(lesson).length?': you reached the end and every quiz is correct.':': you read to the end.');
    else if(done===false)text='You undid this, so it won\u2019t complete itself again.';
    else if(done)text='';
    else text=isSet(lesson)?'Completes itself once every problem in the set is solved.':checks(lesson).length?'Completes itself once you reach the end and every quiz here is correct.':'Completes itself when you reach the end after reading for a while.';
    note(lesson).textContent=text;
    show(caption(lesson.querySelector(':scope>.lesson-footer .complete-group')),text,justMarked);
  }
  function describeProblem(problem,auto){
    const solved=state.answers['solved_'+problem.id];
    const text=auto?'Solved automatically: every check here is correct.':solved==='0'?'You undid this, so it won\u2019t solve itself again.':solved==='1'||!checks(problem).length?'':'Solves itself once every check here is correct.';
    show(caption(problem.querySelector('.problem-footer'),true),text,auto);
  }
  function tick(box){box.checked=true;box.dispatchEvent(new Event('change'));}
  function evaluate(lesson){
    let changed=false;
    lesson.querySelectorAll('.problem').forEach(problem=>{
      const key='solved_'+problem.id,list=checks(problem);
      if(state.answers[key]===undefined&&list.length&&list.every(correct)){
        tick(problem.querySelector('.problem-footer input'));changed=true;describeProblem(problem,true);
      }
    });
    if(state.done[lesson.id]===undefined){
      const ready=isSet(lesson)
        ?[...lesson.querySelectorAll('.problem')].every(p=>state.answers['solved_'+p.id]==='1')
        :state.answers['end_'+lesson.id]==='1'&&checks(lesson).every(correct);
      if(ready){tick(lesson.querySelector(':scope>.lesson-footer input[type=checkbox]'));describe(lesson,true);return;}
    }
    if(changed||!note(lesson).textContent.startsWith(AUTO))describe(lesson,false);
  }
  function reachedEnd(lesson){
    if(lesson.hidden||isSet(lesson)||state.answers['end_'+lesson.id]==='1')return;
    // a page without quizzes needs some reading time first
    const waited=Date.now()-(openedAt[lesson.id]||Date.now());
    if(!checks(lesson).length&&waited<DWELL){
      clearTimeout(lesson._autoTimer);
      lesson._autoTimer=setTimeout(()=>{if(!lesson.hidden&&lesson._footerVisible)reachedEnd(lesson);},DWELL-waited+50);
      return;
    }
    state.answers['end_'+lesson.id]='1';save();evaluate(lesson);
  }
  const io=typeof IntersectionObserver==='undefined'?null:new IntersectionObserver(entries=>entries.forEach(entry=>{
    const lesson=entry.target.closest('.lesson');lesson._footerVisible=entry.isIntersecting;
    if(entry.isIntersecting)reachedEnd(lesson);
  }));
  const mo=new MutationObserver(records=>records.forEach(r=>{if(!r.target.hidden){openedAt[r.target.id]=Date.now();evaluate(r.target);}}));
  lessons.forEach(lesson=>{
    if(io)io.observe(lesson.querySelector(':scope>.lesson-footer'));
    mo.observe(lesson,{attributes:true,attributeFilter:['hidden']});
    lesson.querySelector(':scope>.lesson-footer input[type=checkbox]').addEventListener('change',()=>describe(lesson,false));
    lesson.querySelectorAll('.problem').forEach(problem=>{describeProblem(problem,false);problem.querySelector('.problem-footer input').addEventListener('change',()=>describeProblem(problem,false));});
    evaluate(lesson);
  });
  const after=event=>{const lesson=event.target.closest&&event.target.closest('.lesson');if(lesson)setTimeout(()=>evaluate(lesson));};
  document.addEventListener('click',event=>{if(event.target.closest('.quiz button,.numcheck button,.problem-footer input'))after(event);});
  document.addEventListener('keydown',event=>{if(event.key==='Enter'&&event.target.closest('.numcheck'))after(event);});
})();
