// make a Mono in channel for mic1,
// pans to 5 chans
// pick a bus to play it to,
// and let it rotate

Spec.add(\srcPos, [-1, 1]);
Spec.add(\direct, \amp);
Spec.add(\delayed, \amp);
Spec.add(\feedback, \amp);
Spec.add(\inside, \amp);
Spec.add(\shakers, \amp);
Spec.add(\outside, \amp);
Spec.add(\bigPA, \amp);

q.feedNames = q.numPmcs.collect { |i| ("panFeed" ++ (i+1)).asSymbol };

q.feedPans = q.feedNames.collect { |name, i|
	// Ndef(name).clear;
	Ndef(name, { |srcBus, pos = 0, width = 2,
		direct = 1, delayed = 0, feedback = 0, delaytime = 2, rotate = 0,
		inside = 0.5, shakers, outside, bigPA|

		var in = PanAz.ar(5, InFeedback.ar(srcBus), pos.lag(2), 1, width, 0);
		var feedy = LocalIn.ar(5) * feedback;
		var dts = delaytime.lag(5) * LFDNoise3.kr(0.03 ! 5, 0.02, 0.98);
		var delays = DelayL.ar(LeakDC.ar(in + feedy, 0.998), 10, dts);
		//// cheap but clumsy fixed out with rotate
		//// var rotated = delays.rotate(1);

		////// better rotate with PanAz:
		var rotated = delays.collect { |chan, i|
			var rotatedpos = i + rotate * (2 / ~num);
			PanAz.ar(5, chan, rotatedpos, 1, 2, 0);
		}.sum;

		rotated = Limiter.ar(rotated);
		LocalOut.ar(rotated);

		// 5 outs, table-multiplied by ring amps

		(((in * direct) + (rotated * delayed))
		*.t
			[ inside, shakers, outside, bigPA ].collect(_.lag(1)))
		.flop.flat;


	})
	.fadeTime_(3)
	.vol_(0.25);
};
