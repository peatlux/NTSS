// 5Elements ideas

// outs 1-5 : circle meyers1 inside
// outs 6-10 : circle meyers2 outside
// outs 11-15 : PA speakers outside
// outs wo wie struktos und shakers?
// wo wie sub raus?

// ins 1-5 5x pult mono inside mikros
// ins 6-10 pulte mono-outs outside
// ins 11-16 - extras, line in
// wo wie shaker vom haus rein?

// S16 bei thomann 650 ;-)
// XLR-Kabel? Strom?
// sssnake 10m 8 500 Euro Kabel
// strom 30m 50 Euro

/***
wie per joybox rein/raus hinlegen?
autorotation mit gestureloop am joystick?
2-3 sources per hand ruehren koennen?

s.quit;
****/

(
s.options.device = "X-USB";
s.options.numInputBusChannels = 32;
s.options.numOutputBusChannels = 32;

s.options.memSize = 8192 * 16;

s.waitForBoot {

	~num = 5;
	q.bus_drin = Bus.audio(s, 5);
	q.bus_drau = Bus.audio(s, 5);
	q.bus_pa   = Bus.audio(s, 5);

	m = NdefMixer(s);
	ProxyMeter.addMixer(m);
	s.meter;

	Spec.add(\pos, \pan);
	Spec.add(\level, \amp);
	Spec.add(\width, [2, 8, \exp]);
	Spec.add(\rate, [-10, 10]);
	Spec.add(\delaytime, [0.1, 10, \exp]);
	Spec.add(\direct, \amp);
	Spec.add(\feedback, \amp);
	Spec.add(\rotate, [-5, 5]);

};
)

// direct test sources
Ndef(\hydro1, {
	Pulse.ar(
		LFDNoise3.kr(0.1).exprange(20, 200), 0.2, 0.1)
	* LFPulse.kr(LFDNoise3.kr(0.1).exprange(2, 20), 0, 0.2);
});

// play mono to a direct out for monitoring
Ndef(\hydro1).play(16, vol: 0.1);
// or to the bus for the inside speakers
Ndef(\hydro1).play(q.bus_drin.index + 2, vol: 0.1);

// direct test source
Ndef(\mic1, { SoundIn.ar(0) });
Ndef(\mic1).play(16, vol: 0);
Ndef(\mic1).play(q.bus_drin.index,vol: 0.1);



// simple fixed pan by pos
Ndef(\auto1fix, { |pos, level = 1, width = 2|
	var in = InFeedback.ar(q.bus_drin.index, 1);
	PanAz.ar(5, in, pos, level, width);
}).play(16);

// simple rotation by panaz
Ndef(\auto1saw).ar(5);
Ndef(\auto1saw, { |pos, level = 1, width = 2, rate = 0.1|
	var in = InFeedback.ar(q.bus_drin.index, 1);
	var movpos = LFSaw.kr(rate ** 2) + pos;
	PanAz.ar(5, in, movpos, level, width).flop.sum;
}).play(16);

// rotation by delay and feedback:
// read five chans from bus
// write into delays
// read delays back in and rotate
// write rotated delays back out too // feedback

Ndef(\roto1, { |direct, delaytime = 2, feedback = 1, rotate = 1|
	var in = InFeedback.ar(q.bus_drin.index, 5);
	var feedy = LocalIn.ar(5) * feedback;
	var delays = DelayL.ar(in + feedy, 10, delaytime.lag(5));
	////// cheap but clumsy fixed out with rotate
	// var rotated = delays.rotate(1);

	////// better rotate with PanAz:
	var rotated = delays.collect { |chan, i|
		var rotatedpos = i + rotate * (2 / ~num);
		PanAz.ar(~num, chan, rotatedpos, 1, 2, 0);
	}.sum;

	rotated = Limiter.ar(rotated);

	LocalOut.ar(rotated);
	(in * direct) + rotated;

}).play(16);

