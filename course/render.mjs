// usage: node render.mjs <lesson-id> [dark|light] [width]  -> writes shots/<id>-<theme>.png of the whole lesson (run build.py first)
import {launch} from './browser.mjs';import fs from 'fs';import path from 'path';import {fileURLToPath} from 'url';
const R=path.dirname(fileURLToPath(import.meta.url));const [id,theme='light',w='1280']=process.argv.slice(2);
const b=await launch();
const p=await b.newPage({viewport:{width:+w,height:900}});p.on('pageerror',e=>console.log('PAGEERROR',String(e)));
await p.goto('file://'+(process.env.COURSE||path.join(R,'..','tla-plus-course.html'))+'#'+id);await p.waitForTimeout(300);
if(theme==='dark')await p.click('#theme');await p.waitForTimeout(700);
console.log('overflow',await p.evaluate(()=>document.documentElement.scrollWidth>innerWidth));
await p.locator('#'+id).screenshot({path:(fs.mkdirSync(R+'/shots',{recursive:true}),R+'/shots/')+id+'-'+theme+'.png'});await b.close();
