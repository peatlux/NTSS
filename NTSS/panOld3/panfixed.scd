
Spec.add(\inside, \amp);
Spec.add(\outside, \amp);
Spec.add(\bigPA, \amp);
Spec.add(\shakers, \amp);

q.fixNames = q.numPmcs.collect { |i| ("panFix" ++ (i+1)).asSymbol };
q.fixPans = q.fixNames.collect { |name, i|

	Ndef(name, { |srcBus = 0,
		pos = 0, width = 2,
		inside = 0.25, shakers = 0.25, outside = 0.25,
		bigPA = 0.25|

		var in = InFeedback.ar(srcBus);
		var amps = [inside, outside, bigPA, shakers];
		var panned = PanAz.ar(5, in, pos, amps, width, 0).flat;

		// panned.size.postln;
		panned;
	})
	.fadeTime_(3)
	.vol_(0.25);
};
