#!/usr/bin/env mash

(* Show Number. Convert to string w/ no trailing dot. Round to the nearest r. *)
Unprotect[Round];   Round[x_,0] := x;   Protect[Round];
shn[x_, r_:0] := StringReplace[
  ToString@NumberForm[Round[N@x,r], ExponentFunction->(Null&)], re@"\\.$"->""]

(* Return a string that is a table in html format. *)
htmlTable[tbl_, headers_, summary_:""] := Module[{htmlrow},
  htmlrow[l_] := cat["<tr>", cat@@(cat["<td>",#,"</td>"]& /@ l), "</tr>\n"];
  cat["<table border=\"1\" summary=\"", summary, "\">\n<tr><th>",
      cat@@Riffle[headers, "</th><th>"], "</th></tr>\n",
      cat@@(htmlrow /@ tbl), "</table>"]]

(* Return a matrix with rows and columns labeled. Helper for textTable[]. *)
labelTable[m_, rl_, cl_] := Module[{mm = m, r = PadRight[rl, Length[m], ""]},
  PrependTo[mm, PadRight[cl, Length@First@m, ""]];
  PrependTo[r, ""];
  Transpose[Prepend[Transpose[mm], r]]]

(* Helper function for textTable[]. NB: table[t] is the same as textTable[t]. *)
table[t_] := StringReplace[ToString[TableForm[shn/@#&/@t]], "\n\n"->"\n"]

(* Return a string representation of a table, with optional row and 
   column labels.  Handy for outputting tables in scripts. *)
textTable[tbl_, rl_:{}, cl_:{}] :=
  Which[ rl==={} && cl==={}, table[tbl],
         rl==={},            table@Prepend[tbl,cl],
         cl==={},            table@Transpose@Prepend[Transpose[tbl], rl],
         True,               table@labelTable[tbl,rl,cl] ]

(* The Nash equilibrium of a Chinese auction w/ common knowledge valuations. *)
nashRaw[v_] := With[{n = Length[v], r = Total[1/v]}, (n-1) * (r-(n-1)/v) / r^2]
nashS[v_] := With[{x = nashRaw[v]}, If[x[[1]]<0, Prepend[nashS[Rest[v]], 0], x]]
nash[v_] := nashS[Sort[v]][[Ordering@Ordering[v]]] (* sort, find Nash, unsort *)

(* From wrapper.php we are getting a string like this:
     { 
       {"MAGIC_SELLER", 123},
       {"alice",1},
       {"bob",1},
       {"carol",1},
       Null 
     }
  So we want to do Most to get rid of that Null and pull out that first line
  with the magic string separately to get the price.
*)

in = cat@@Riffle[readList[], "\n"];  (* slurp stdin as a string *)
in = Most@eval[in]; (* eval it, but not that final Null *)
cval = eval[in[[1, 2]]]; (* price of the good, default $600 *)
in = Rest[in];

each[{who_, bids___}, in,
  b = Max[bids];
  If[b>0, bh[who] = b]];

roster = SortBy[keys[bh], {-bh[#]&}];
bids = bh/@roster;
paymts = nash[bids];
revenue = Total[paymts];
jackpot = cval*paymts/revenue;
chances = MapThread[If[#2==0,Null,#1/#2]&, {paymts, jackpot}];
maxprob = If[#==0,Null,#/cval]& /@ bids;
plose = Mean[DeleteCases[chances, Null]];
plose1 = Min[DeleteCases[chances, Null]];
plose2 = Max[DeleteCases[chances, Null]];

(*
prn["bidders =   ", roster, "<br/>"];
prn["payments =  ", shn[#,.01]& /@ paymts, "<br/>"];
prn["fractions = ", shn[#,.01]& /@ (paymts/revenue), "<br/>"];
*)

prn@htmlTable[{
  Join[{"Your bid (<i>not</i> what you pay):"}, 
       cat["$",shn[#,.01]]& /@ Append[bids, Total@bids]],
  Join[{"What you pay:"}, 
       cat["$",shn[#,.01]]& /@ Append[paymts, Total@paymts]],
  Join[{"Share you get:"}, 
       cat[shn[100*#,1],"%"]& /@ Append[(paymts/revenue), 1]],
  Join[{"What you get if person derails:"}, 
       cat["$",shn[#,.01]]& /@ Append[jackpot, cval]],
  Join[{"Implied chances of derail:"},
       If[#===Null,"-",cat[shn[100*#,Which[#<.01,.01,#<10,.1,True,1]],"%"]]& /@
         Append[maxprob, If[plose1!=plose2, 0, plose]]]
  },
  Join[{"Auction Results"}, roster, {"TOTAL"}], "Auction results."];
