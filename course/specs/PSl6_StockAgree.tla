---- MODULE PSl6_StockAgree ----
EXTENDS PSl6_Stock
Bound == \A w \in RM : stock[w] =< 4
====
