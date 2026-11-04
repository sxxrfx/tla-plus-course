import {launch} from './browser.mjs';import fs from 'fs';import path from 'path';import {fileURLToPath} from 'url';
const COURSE=path.join(path.dirname(fileURLToPath(import.meta.url)),'..','tla-plus-course.html');
const b=await launch();
const p=await b.newPage({viewport:{width:1280,height:900}});const errs=[];p.on('pageerror',e=>errs.push(String(e)));
const url='file://'+(process.argv[2]||COURSE);const go=async id=>{await p.evaluate(i=>{location.hash=i},id);await p.waitForTimeout(250);};
const st=()=>p.evaluate(()=>JSON.parse(localStorage.getItem('tla-course-v1')));
const progress=()=>p.textContent('#progress-text');
async function answerAll(root){
  for(const q of await p.locator(root+' .quiz').all()){const a=await q.getAttribute('data-answer');await q.locator(`input[value="${a}"]`).check();await q.locator('button').click();}
  for(const n of await p.locator(root+' .numcheck').all()){const a=(await n.getAttribute('data-answer')).split('|')[0];await n.locator('input').fill(a);await n.locator('button').click();}
  await p.waitForTimeout(100);
}
const toEnd=async()=>{await p.evaluate(()=>window.scrollTo(0,document.documentElement.scrollHeight));await p.waitForTimeout(300);};
const done=id=>p.evaluate(i=>document.querySelector('#'+i+'>.lesson-footer input').checked,id);
await p.goto(url);await p.evaluate(()=>localStorage.clear());await p.goto(url+'#states');await p.waitForTimeout(400);
// 1. quizzes right but end not reached -> not ticked
await answerAll('#states');console.log('1 quizzes only, studied:',await done('states'),'| note:',await p.textContent('#states>.auto-note'));
await toEnd();console.log('  after reaching end, studied:',await done('states'),'|',await p.textContent('#states>.auto-note'),'|',await progress(),'| sidebar ✓',await p.evaluate(()=>!document.querySelector('#toc a[href="#states"] .done').hidden));
// 2. end first, then wrong answer, then right
await go('program');await toEnd();const q=p.locator('#program .quiz').first();const a=await q.getAttribute('data-answer');
const wrong=a==='0'?'1':'0';await q.locator(`input[value="${wrong}"]`).check();await q.locator('button').click();await p.waitForTimeout(100);
console.log('2 end + wrong answer, studied:',await done('program'));
await answerAll('#program');console.log('  all right, studied:',await done('program'));
// 3. manual untick sticks
await p.locator('#program>.lesson-footer input').uncheck();await answerAll('#program');console.log('3 unticked then re-answered, studied:',await done('program'),'|',await p.textContent('#program>.auto-note'));
// 4. problems and the set
await go('ps-l1');const probs=await p.locator('#ps-l1 .problem').evaluateAll(ps=>ps.map(x=>x.id));
await answerAll('#'+probs[0]);console.log('4 problem 1 solved:',await p.locator('#'+probs[0]+' .problem-footer input').isChecked(),'|',await p.textContent('#ps-l1 .ps-progress'),'| set studied:',await done('ps-l1'));
for(const id of probs.slice(1))await answerAll('#'+id);
console.log('  all problems answered:',await p.textContent('#ps-l1 .ps-progress'),'| set studied:',await done('ps-l1'),'|',await p.textContent('#ps-l1>.auto-note'));
// 5. manual problem untick sticks
await p.locator('#'+probs[0]+' .problem-footer input').uncheck();await answerAll('#'+probs[0]);console.log('5 problem unticked + re-answered:',await p.locator('#'+probs[0]+' .problem-footer input').isChecked());
// 6. reload keeps it
await p.reload();await p.waitForTimeout(400);await go('ps-l1');console.log('6 after reload:',await progress(),'| states',await done('states'),'program',await done('program'),'ps-l1',await done('ps-l1'));
// 7. quiz-less review needs 30 s
await go('review');await toEnd();console.log('7 review at end now:',await done('review'),'|',await p.textContent('#review>.auto-note'));
await p.waitForTimeout(31000);console.log('  after 31 s:',await done('review'),'|',await p.textContent('#review>.auto-note'));
// 8. a lesson merely scrolled past isn't ticked
await go('logic');await toEnd();console.log('8 logic scrolled only:',await done('logic'));
const s=await st();console.log('stored keys',Object.keys(s.answers).filter(k=>/^(end|solved)_/.test(k)).length,'all identifier-safe',Object.keys(s.answers).every(k=>/^[A-Za-z0-9_-]+$/.test(k)));
console.log('errors',errs);await b.close();
