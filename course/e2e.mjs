import {launch} from './browser.mjs';import fs from 'fs';import path from 'path';import {fileURLToPath} from 'url';
const COURSE=path.join(path.dirname(fileURLToPath(import.meta.url)),'..','tla-plus-course.html');
const b=await launch();
const p=await b.newPage({viewport:{width:1280,height:900}});const errs=[];p.on('pageerror',e=>errs.push(String(e)));
await p.goto(process.argv[2]||'file://'+COURSE);await p.waitForTimeout(400);
const ids=await p.evaluate(()=>[...document.querySelectorAll('.lesson')].map(l=>l.id));
const probs=[];
for(const id of ids){
 await p.evaluate(i=>{location.hash=i},id);await p.waitForTimeout(40);
 const r=await p.evaluate(()=>{const l=document.querySelector('.lesson:not([hidden])');const svgs=[...l.querySelectorAll('svg.dg')];
  const brokenMarker=svgs.filter(s=>{const m=s.querySelector('[marker-end]');if(!m)return false;const id=m.getAttribute('marker-end').slice(5,-1);return !s.querySelector('[id="'+id+'"]')}).length;
  const clipped=svgs.filter(s=>{const vb=s.viewBox.baseVal;return [...s.querySelectorAll('text')].some(t=>{const bb=t.getBBox();return bb.x<-1||bb.y<-1||bb.x+bb.width>vb.width+1||bb.y+bb.height>vb.height+1})}).length;
  const brokenLinks=[...l.querySelectorAll('a[href^="#"]')].filter(a=>!document.getElementById(a.hash.slice(1))).length;
  const firstFig=l.querySelector('svg.dg,.lab');
  return {n:svgs.length,brokenMarker,clipped,brokenLinks,firstFigY:firstFig?Math.round(firstFig.getBoundingClientRect().top+scrollY):null,overflow:document.documentElement.scrollWidth>innerWidth,title:document.title}});
 if(r.brokenMarker||r.clipped||r.brokenLinks||r.overflow)probs.push([id,r]);
}
console.log('lessons',ids.length,'problems',JSON.stringify(probs));
// click every lab control
const labs=await p.evaluate(()=>[...document.querySelectorAll('.lab')].map(l=>[l.closest('.lesson').id,l.id]));
for(const [les,lab] of labs){await p.evaluate(i=>{location.hash=i},les);await p.waitForTimeout(60);
 const n=await p.locator('#'+lab+' button').count();let clicks=0;
 for(let r=0;r<3;r++)for(let i=0;i<n;i++){const btn=p.locator('#'+lab+' button').nth(i);if(await btn.isVisible()&&await btn.isEnabled()){await btn.click({timeout:1500}).catch(()=>{});clicks++}}
 console.log(' lab',lab,'buttons',n,'clicks',clicks);}
// phone
await p.setViewportSize({width:390,height:800});const po=[];for(const id of ids){await p.evaluate(i=>{location.hash=i},id);await p.waitForTimeout(30);if(await p.evaluate(()=>document.documentElement.scrollWidth>innerWidth))po.push(id)}
console.log('phone overflow',po);
console.log('page errors',errs.length,errs.slice(0,5));await b.close();
