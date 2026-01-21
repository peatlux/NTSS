/*** String sound:
ProxySubmix with ch1, ch2 .. ch8, str1, str2
***/
q.stringNames = [\string1Hall,\string2Wind];
q.stringProxies = q.stringNames.collect(ProxySubmix(_));
q.stringProxies.do { |strproxy|
	strproxy.ar;
	strproxy.postln;
	Ndef.all.localhost.put(strproxy.key, strproxy);
	q.stringProxies.do { |strpx|
		strproxy.addMix(strpx, postVol: true)
	};

	q.pchains.do { |pch, i|
		strproxy.addMix(pch.proxy, postVol: true)
	};
};
