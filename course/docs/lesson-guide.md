# Lesson authoring guide

The lessons follow Lamport's TLA+ video course: each lecture lesson teaches what its lecture teaches, in its order, and every lesson is one step harder than the one before.

The course is one offline HTML page, built by `build.py` from the files below. Paths are relative to `course/`.

## Files
- `curriculum.py`: the full lesson order (id, part, title, old material, videos). Read it first, so you know what comes before and after your lessons.
- Lecture lessons MUST follow what the lecture actually teaches and use its examples, names and order (the lecture scripts are on Lamport\'s video page; they are not in this repo). Paraphrase; do not copy his prose. Short formulas and specs are fine.
- `src/<id>.html`: your lesson body. `src/<id>.figs.py`: its diagrams. `labs/<id>.js`: optional new interactive lab. `specs/<Name>.tla/.cfg`: specs you check.
- `dg.py`: diagram helpers (`graph`, `sequence`, `lanes`, `regions`). Read its docstrings.
- `tlc.sh Name`: run real TLC on `specs/Name.tla`.

## Lesson format
`src/<id>.html` starts with `<h1>` (a claim or idea, not the sidebar title), then `<p class="lead">`. No `<section>` wrapper and no "Lesson N" line; the build adds those, and the video player is inserted automatically right after the lead.
- Refer to other lessons only with `{{lesson:id}}`, never a number. Lessons get renumbered.
- Diagrams: put `<!--fig:name-->` in the HTML and in `src/<id>.figs.py`:
  ```python
  import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
  from dg import graph,sequence,lanes,regions
  FIGS={"name":(graph({...},[...],"alt text saying what it shows"),"Caption stating the point of the diagram.")}
  ```
- Components already styled: `<h2>`,`<h3>`, `<p class="goal">`, `<div class="callout"><p>..</p></div>`, `<div class="table-wrap"><table>..</table></div>`, `<pre><code>..</code></pre>` (escape `<`, `>`, `&`), `<details class="answer"><summary>Predict: ...</summary><p>..</p></details>`, and quizzes:
  `<div class="quiz" data-answer="1" data-explain="Why."><fieldset><legend>Question?</legend><label><input type="radio" name="q-UNIQUE" value="0">A</label><label><input type="radio" name="q-UNIQUE" value="1">B</label></fieldset><button type="button">Check answer</button><p class="quiz-feedback" aria-live="polite"></p></div>`
  Links out: `<a target="_blank" rel="noopener noreferrer" href="...">`. End with `<p class="resources">` when there are useful references.
- Existing labs (`<div class="lab" id="...-lab">` in old lessons) are wired up by JS through their element ids. If your lesson keeps a lab, copy its markup with every id unchanged. A lab's JS is NOT in your file; don't rewrite it. Don't drop a lab unless it no longer fits; say so in your report if you do.
- New lab (only where it really teaches, e.g. stepping a protocol): markup in the lesson with ids prefixed by the lesson id, and a self-contained `labs/<id>.js` IIFE. Use `textContent`, not innerHTML with data; use CSS vars for colour, class `lab`, `controls`. It must work with no network. Labs are educational models, say so; they are not TLC.

## What matters
1. **Order and complexity.** Assume ONLY what earlier lessons taught. Each lesson should feel like one step harder than the last. Never use a concept (operator, syntax, term) before the lesson that introduces it; if you must mention something later, say where it comes. Start each lesson with a sentence or two connecting it to what was just learned.
2. **Diagrams carry the explanation.** Lecture lessons that are new: at least 3 diagrams. Rewritten lessons: at least 2, plus one new diagram replacing any CSS `.flow` figure that would be clearer as a real graph. The first should appear in the first screen of the lesson. Each must show the real mechanism (the actual states and transitions, the actual message order, the actual quorum overlap), not boxes-and-arrows decoration, and the text must use it ("in the diagram, the dashed arrow..."). Prefer showing a bad trace next to the good one. Keep labels short.
3. **Lecture alignment.** For lecture lessons, include a short "While you watch" section: what to look for, where to pause and try it, what the lesson adds. Do not give timestamps, you can't verify them. Be careful with lessons sharing a lecture: split the lecture's content between them so nothing is taught twice.
4. **Accuracy.** Every complete module you print must parse and be checked with `tlc.sh`, and every number you state (states found, trace length, what fails) must come from a TLC run you did. Fragments that can't run alone must come from a module that does. If a lecture's spec differs from what you'd write, follow the lecture. If you can't verify a claim, cut it. Don't invent facts about Lamport, tools, or papers. The Toolbox appears in lecture 3; also mention the VS Code extension as the current option, as the old `tools` lesson does.
5. **Voice.** Match the old lessons: plain, precise, direct, second person, no hype. Define each term the first time you use it. 600 to 1200 words per lesson, more only when a spec needs room. Keep the worked real-world example (app/product) when the old lesson had one, if it still fits.
6. Keep predict-style `<details class="answer">` and quizzes; at least one of each per lecture lesson.

## Checking your work
```
python3 build.py --partial --out /tmp/course-draft.html   # prints stats and ERRORS; --partial skips lessons not written yet
COURSE=/tmp/course-draft.html node render.mjs <id> light   # writes shots/<id>-light.png
COURSE=/tmp/course-draft.html node render.mjs <id> dark
```
There must be no errors. Look at the screenshot of every lesson you write, at least in one theme, and fix any diagram with clipped text, crossing labels or arrows passing through nodes. The linter only approximates this. Check one lesson in dark too, and phone width with `node render.mjs <id> light 390` for one diagram-heavy lesson.

