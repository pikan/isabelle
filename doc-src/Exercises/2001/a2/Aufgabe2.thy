(*<*)
theory Aufgabe2 = Main:
(*>*)

subsection {* Trees *}

text{* In the sequel we work with skeletons of binary trees where
neither the leaves (``tip'') nor the nodes contain any information: *}

datatype tree = Tp | Nd tree tree

text{* Define a function @{term tips} that counts the tips of a
tree, and a function @{term height} that computes the height of a
tree.

Complete binary trees of a given height are generated as follows:
*}

consts cbt :: "nat \<Rightarrow> tree"
primrec
"cbt 0 = Tp"
"cbt(Suc n) = Nd (cbt n) (cbt n)"

text{*
We will now focus on these complete binary trees.

Instead of generating complete binary trees, we can also \emph{test}
if a binary tree is complete. Define a function @{term "iscbt f"}
(where @{term f} is a function on trees) that checks for completeness:
@{term Tp} is complete and @{term"Nd l r"} ist complete iff @{term l} and
@{term r} are complete and @{prop"f l = f r"}.

We now have 3 functions on trees, namely @{term tips}, @{term height}
und @{term size}. The latter is defined automatically --- look it up
in the tutorial.  Thus we also have 3 kinds of completeness: complete
wrt.\ @{term tips}, complete wrt.\ @{term height} and complete wrt.\
@{term size}. Show that
\begin{itemize}
\item the 3 notions are the same (e.g.\ @{prop"iscbt tips t = iscbt size t"}),
      and
\item the 3 notions describe exactly the trees generated by @{term cbt}:
the result of @{term cbt} is complete (in the sense of @{term iscbt},
wrt.\ any function on trees), and if a tree is complete in the sense of
@{term iscbt}, it is the result of @{term cbt} (applied to a suitable number
--- which one?)
\end{itemize}
Find a function @{term f} such that @{prop"iscbt f"} is different from
@{term"iscbt size"}.

Hints:
\begin{itemize}
\item Work out and prove suitable relationships between @{term tips},
      @{term height} und @{term size}.

\item If you need lemmas dealing only with the basic arithmetic operations
(@{text"+"}, @{text"*"}, @{text"^"} etc), you can ``prove'' them
with the command @{text sorry}, if neither @{text arith} nor you can
find a proof. Not @{text"apply sorry"}, just @{text sorry}.

\item
You do not need to show that every notion is equal to every other
notion.  It suffices to show that $A = C$ und $B = C$ --- $A = B$ is a
trivial consequence. However, the difficulty of the proof will depend
on which of the equivalences you prove.

\item There is @{text"\<and>"} and @{text"\<longrightarrow>"}.
\end{itemize}
*}

(*<*)
end;
(*>*)
