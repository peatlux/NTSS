Ins:

INS 1-8 - 8 Microphones on
4 air mics for performers inside
3 contact mics on house
1 hydrophone ...

INS 9-16 - ANALOG INS ON MIXER
- 5 Stations w Mixer and PA speaker, mono
-- from input 9-13, test is on input 9
1 geophone (line);

32 analog ins on mixer;

// how to place them so the channels are continuous?
//
s.reboot;
s.meter

OUTS:
8 MAIN OUTS
6 AUXES, CAN SEND DIRECT CHANNELS
2 MONITORS,

read all 32 in software
send 22 or max 32 chans back

Simplest CASE:
16 analog ins on plugs
16 return inputs from SC
-> 8 + 6 aux hardware outs on mixer

With expander:
16 + 16 analog ins on plugs
16 + 8 return inputs from SC
-> 8 + 6 aux + 8 hardware outs on mixer

s.meter;

//////////////// TESTS WITH JUST Behringer X-USB ///////////
s.options.device = "X-USB";
s.options.numInputBusChannels = 32;
s.options.numOutputBusChannels = 32;

s.boot;

s.meter;

Ndef(\pink, { PinkNoise.ar(0.1) });

Tdef(\pinka, {
	loop {
		5.do { |i|
			Ndef(\pink).play((i + 16).postln);
			1.wait;
		}
	}
}).play;

// play on first 5
(
Tdef(\x, {
	loop {
		5.do { |i|
			(degree: i, pan: -1, out: (i + 16).postln).play;
			0.25.wait;
		}
	}
}).play;
)

// play on second 5
(
Tdef(\x, {
	loop {
		5.do { |i|
			(degree: i, pan: -1, out: (i + 21).postln).play;
			0.25.wait;
		}
	}
}).play;
)


NdefMixer(s);

Spec.add(\cycleRate, [-1, 1]);
Spec.add(\numCycles, [0, 5, \amp]);

Ndef(\in9pan, { |cycleRate = 0.1, numCycles = 3|
	PanAz.ar(5, SoundIn.ar(8),
		SinOsc.kr(cycleRate ** 2, 0, numCycles)
	)
}).play(16);

