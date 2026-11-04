import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
FIGS={
"vars":(regions([
 (20,14,380,150,"Variables of AB","accent"),
 (280,14,380,150,"Variables of AB2","good"),
],"Two overlapping sets of variables. AB has AVar, BVar, AtoB and BtoA. AB2 has AVar, BVar, AtoB2 and BtoA2. Only AVar and BVar are shared, so AB2 says nothing about AtoB and BtoA.",width=680,height=210,notes=[
 (150,90,"AtoB, BtoA"),
 (340,90,"AVar, BVar"),
 (530,90,"AtoB2, BtoA2"),
 (340,190,"ABSpec needs only the overlap. AB needs the left part too, and AB2 never mentions it."),
]),"Why <code>THEOREM Spec =&gt; ABS!Spec</code> still works for AB2, and why the same trick can't claim AB2 implements AB. Nothing in AB2 constrains <code>AtoB</code> and <code>BtoA</code>."),
"unfold":(graph({
 "a":(280,28,'RemoveX(<<"Tom", "X", "Dick">>)',"accent"),
 "b":(280,104,'<<"Tom">> \\o RemoveX(<<"X", "Dick">>)'),
 "c":(280,180,'<<"Tom">> \\o RemoveX(<<"Dick">>)'),
 "d":(280,256,'<<"Tom">> \\o <<"Dick">> \\o RemoveX(<<>>)'),
 "e":(280,332,'<<"Tom", "Dick">>',"good"),
},[
 ("a","b","head is Tom: keep it"),
 ("b","c","head is X: drop it"),
 ("c","d","head is Dick: keep it"),
 ("d","e","empty: base case"),
],"RemoveX unfolding step by step on a three element sequence, each step applying the definition to a shorter sequence until the empty sequence.",width=620,height=360,mono=True),
"Each line applies the definition once, to a shorter sequence, until the base case stops it. Without that case the definition would never bottom out."),
"subst":(lanes([
 ("Run 1: x",["1","2","3"]),
 ("y",["3","3","3"]),
 ("y = x + 2",[("true","good"),("false","bad"),("false","bad")]),
 ("Run 2: x",["1","2","3"]),
 ("y",["3","4","5"]),
 ("y = x + 2",[("true","good"),("true","good"),("true","good")]),
],"Two behaviors. In run 1 y equals x plus 2 only in the first state, so y prime does not equal x plus 2 primed. In run 2 it holds in every state and the substitution is valid.",cols=["s1","s2","s3"],labelw=120),
"Run 1 is why the simple law fails: <code>y = x + 2</code> holds in s1, but <code>y'</code> is 3 and <code>(x + 2)'</code> is 4. Run 2 satisfies <code>[](y = x + 2)</code>, and there you may substitute anywhere, primes included."),
"corrupt":(sequence(["A","B"],[
 ("A","B","Bad (was <<Mary,1>>)  CorruptMsg, B ignores it",{"tone":"bad","dash":True}),
 ("A","B","<<Mary,1>>  new bit, so BVar := <<Mary,1>>",{"tone":"good"}),
 ("B","A","Bad (was 1)  not equal to A's bit, ignored",{"tone":"bad","dash":True}),
 ("B","A","1  matches A's bit, so choose a new value",{"tone":"good"}),
],"Message sequence for AB2. A corrupted message from A arrives as Bad and B ignores it. The next copy gets through. A corrupted ack arrives as Bad and A ignores it, and the next ack gets through.",gap=420,step=40),
"In AB2 a damaged message still arrives, as <code>Bad</code>, and keeps its slot in the channel. Receiving it does nothing except consume it. The resending from {{lesson:abp}} still does the rest."),
"loop":(lanes([
 ("step",[None,"BSnd","ASnd","BRcv","ASnd","BSnd","BRcv","Corrupt","ARcv","Corrupt","ARcv"]),
 ("AtoB2",["empty","empty","m","empty","m","m","empty","empty","empty","empty","empty"]),
 ("BtoA2",["empty","1","1","1","1","1,1","1,1",("Bad,1","bad"),"1",("Bad","bad"),"empty"]),
 ("AVar",["d1,1"]*11),
],"TLC's counterexample for AB2's FairSpec. Over ten steps both acks are corrupted before A receives them, so A only ever receives Bad, and the behavior returns to its first state with AVar unchanged.",cols=["1","2","3","4","5","6","7","8","9","10","to 1"],labelw=56,cell=58),
"TLC's counterexample with <code>Data = {d1, d2}</code> and channels of length at most 2 (m = <code>&lt;&lt;d1, 1&gt;&gt;</code>; channels shown without brackets). Every ack gets corrupted before A reaches it, and <code>BVar</code> never changes. <code>ARcv</code> does keep happening, so <code>SF_vars(ARcv)</code> is satisfied."),
"good":(lanes([
 ("AtoB2",["<Tom,0>","<Tom,0>","<Fred,1>"]),
 ("AtoBgood",[("TRUE","good"),("FALSE","bad"),("FALSE","bad")]),
 ("may corrupt?",["no","yes","yes"]),
],"The channel AtoB2 holds three messages. A parallel imaginary sequence AtoBgood holds TRUE, FALSE, FALSE, marking the first as protected from corruption.",cols=["1","2","3"]),
"The real channel and its imaginary shadow, kept in separate variables: one flag per message, decided when the message is sent."),
}
FIGS={k:(s.replace('id="dg-a"',f'id="dg-a-ig-{k}"').replace('url(#dg-a)',f'url(#dg-a-ig-{k})'),c) for k,(s,c) in FIGS.items()}
