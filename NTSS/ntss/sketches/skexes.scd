/*
Alles von anderen Laptops syncen!
HyperDisCo setup nutzen!

Hall speziell fuer draussen!
*/
s.plotTree;

Ndef.all.localhost.do(_.end);

s.meter;

s.sendMsg("/n_free", 1023);


q.pchains.drop(1).do(_.end);

q.panFixes.do(_.end);

q.rotoPans.do(_.end);
q.fixPans.do(_.end);
q.feedPans.do(_.end);

x = Ndef.all.localhost;
x.do(_.end);

s.options.dump;

s.sendMsg("/n_free", 1018);

ProxyChain(\chRev1, [\top, \ins, \tape, \gapz, \rev]);

ProxyChain(\chRev1).gui;