// usage: node screenshots.mjs  -> writes the README screenshots to ../docs/screenshots (run build.py first)
import {launch} from './browser.mjs';import fs from 'fs';import path from 'path';import {fileURLToPath} from 'url';
const R=path.dirname(fileURLToPath(import.meta.url));const OUT=path.join(R,'..','docs','screenshots');fs.mkdirSync(OUT,{recursive:true});
const url='file://'+path.join(R,'..','tla-plus-course.html');
const b=await launch();
// selector: clip to that element (document coordinates, so nothing depends on scrolling); maxHeight crops long elements
async function shot(name,{hash,theme='light',width=1280,height=800,selector,maxHeight=760,pad=24,prepare}={}){
  const p=await b.newPage({viewport:{width,height},deviceScaleFactor:2});
  await p.goto(url+'#'+hash);await p.waitForTimeout(500);
  if(theme==='dark')await p.click('#theme');
  if(prepare)await prepare(p);
  await p.evaluate(()=>{document.activeElement&&document.activeElement.blur();window.scrollTo(0,0);});await p.waitForTimeout(200);
  const file=path.join(OUT,name+'.png');
  if(selector){
    const box=await p.evaluate(sel=>{const r=document.querySelector(sel).getBoundingClientRect();return {x:r.left+scrollX,y:r.top+scrollY,w:r.width,h:r.height};},selector);
    await p.screenshot({path:file,fullPage:true,clip:{x:Math.max(0,box.x-pad),y:Math.max(0,box.y-pad),width:box.w+2*pad,height:Math.min(box.h,maxHeight)+2*pad}});
  }else await p.screenshot({path:file});
  await p.close();console.log('wrote',name);
}
await shot('lesson',{hash:'diehard'});
await shot('diagram',{hash:'paxos-commit',selector:'#paxos-commit figure:nth-of-type(2)'});
await shot('lab',{hash:'diehard',selector:'#diehard-lab',maxHeight:700,prepare:async p=>{for(const a of ['FillBig','BigToSmall','EmptySmall','BigToSmall','FillBig','BigToSmall'])await p.locator('#diehard-lab button',{hasText:a}).first().click();}});
await shot('problem-set',{hash:'ps-l7',theme:'dark',selector:'#ps-l7 article.problem:nth-of-type(1)',maxHeight:640});
await shot('phone',{hash:'ps-l4',width:390,height:844});
await b.close();
