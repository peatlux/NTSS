Quarks.install("https://github.com/aiberlin/NTSS");
Quark("NTSS").dependencies.do(_.update);

thisProcess.recompile;

q = q ? ();
q.ntss = q.ntss ? ();
q.ntss.spat = q.ntss.spat ? ();


(
q.ntss.spat.pulsar = { arg name, speakers, snd;
	// creates a local buffer (temporary buffer valid inside this synth)
	var buf = LocalBuf.newFrom(0 ! (10 * s.sampleRate));
	// main trigger speed, how fast we play grains
	var trigSpeed = \trigSpeed.kr(1, spec:[0.1,200,\exp]);
	// shift the speed of grain between each speaker
	var deviation = \dev.kr(0, spec:[0,1]);
	var shiftSpeakers = ({1 + (15.0.rand * deviation)}!speakers.size);
	// creates N speakers trigs
	var trigs = Impulse.kr(trigSpeed * shiftSpeakers);
	// record the sound coming to the local buf, with optional loop control
	RecordBuf.ar(snd, buf, 0, 1, 0, 1, \loop.kr(1, spec:[0,1]));
	     //PlayBuf.ar(1, buf, {2.0.rand2} ! speakers.size, trigs, 0, 1);
	// plays N speaker grains, using the trigSpeed as defined above, with random rate
	GrainBuf.ar(1, trigs,
		trigSpeed.reciprocal * \release.kr(1, spec:[0,4]),
		buf,
		1 * shiftSpeakers,
		LFSaw.kr(\stretchSpeed.kr(0.01, spec:[0.0001, 10, \exp])).range(0,1)
	)
};
ProxyChain.add3(\pulsar, q.ntss.getSpat(\pulsar));
)

~env = Buffer.loadCollection(s, Env.perc(0.1, 0.9).discretize(2048));
~env.loadCollection(Env.perc(0.9, 0.1, 1, -10).discretize(2048))
~env.loadCollection(Env.sine(1).discretize(2048));
~miniPGbufs[60].copy()
~env


(
q.ntss.spat.pulsarfb = { arg name, speakers, snd;
	var fb = LocalIn.ar(1);
	// creates a local buffer (temporary buffer valid inside this synth)
	var buf = LocalBuf.newFrom(0 ! (5 * s.sampleRate));
	// main trigger speed, how fast we play grains
	var trigSpeed = \trigSpeed.kr(1, spec:[0.1,200,\exp]);
	// shift the speed of grain between each speaker
	var deviation = \dev.kr(0, spec:[0,1]);
	var shiftSpeakers = ({1 + (15.0.rand * deviation)}!speakers.size);
	// creates N speakers trigs
	var trigs = Impulse.kr(trigSpeed * shiftSpeakers);
	var grains;
	//var in = SelectX.ar(LFDNoise3.kr(0.2).range(0,1), [snd, fb]);
	var in = SelectX.ar(
		\which.kr(0, spec:[0,1]) +
		(LFDNoise3.kr(0.2).range(-1,1) * \noiseamount.kr(0, spec:[0,1])),
		[snd, fb]);
	// record the sound coming to the local buf, with optional loop control
	RecordBuf.ar(in, buf, 0, 1, 0, 1, \loop.kr(1, spec:[0,1]));
	     //PlayBuf.ar(1, buf, {2.0.rand2} ! speakers.size, trigs, 0, 1);
	// plays N speaker grains, using the trigSpeed as defined above, with random rate
	grains = GrainBuf.ar(1, trigs,
		trigSpeed.reciprocal * \release.kr(1, spec:[0,4]),
		buf,
		1 * shiftSpeakers,
		LFSaw.kr(\stretchSpeed.kr(0.01, spec:[0.0001, 10, \exp])).range(0,1),
		2,
		0,
		speakers.size.collect { ~miniPGbufs.choose }
	);
	LocalOut.ar(grains.mean);
	grains;
};
ProxyChain.add3(\pulsarfb, q.ntss.getSpat(\pulsarfb));
)




(
q.ntss.spat.grainnet = { arg name, speakers, snd;
	var fb = Limiter.ar(LocalIn.ar(speakers.size));
	//var in = SelectX.ar(LFDNoise3.kr(0.2).range(0,1), [snd, fb]);
	/*var ins = speakers.size.collect { |i|
		SelectX.ar((SinOsc.kr(0.01, i/speakers.size * pi).range(0,1) * fb.size).poll, fb.rotate(1));
	} * \fb.kr(0, spec:\ampx4);
*/
	// record the sound coming to the local buf, with optional loop control
	var ins;
	var map = \map.ar((0..speakers.size-1), spec:[0,speakers.size-1]);
	snd = snd * \snd.kr(1, spec:\amp);
	fb[0] = snd + fb[0];
	ins = fb.collect {|fbch, i| Select.ar(map[i], fb)};
	LocalOut.ar(DelayC.ar(ins * \fb.kr(0, spec:\amp), 5, \delayTime.kr(1, spec:[0,5])));
	fb;
};

Ndef('chP1ada').set(\map, (0..25).rotate(1));

ProxyChain.add3(\grainnet, q.ntss.getSpat(\grainnet));
)


(
q.ntss.spat.grainnet = { arg name, speakers, snd;
	var fb = Limiter.ar(LocalIn.ar(speakers.size));
	var ins;
	var map = \map.ar((0..speakers.size-1), spec:[0,speakers.size-1]);
	snd = snd * \snd.kr(1, spec:\amp);
	//fb = fb.collect {|f, idx|
	//	PitchShift.ar(f, 0.2, rrand(0.9,1.1));
	//};
	fb[0] = snd + fb[0];
	ins = fb.collect {|fbch, i| Select.ar(map[i], fb)};
	LocalOut.ar(DelayC.ar(ins * \fb.kr(0, spec:\amp), 5, \delayTime.kr(1, spec:[0,5]) * 26.collect {rrand(0.75,1.25)}));
	fb;
};

Ndef('chP1ada').set(\map, (0..25).rotate(1));

ProxyChain.add3(\grainnet, q.ntss.getSpat(\grainnet));
)

~possibles= (0..25);
~possibles.scramble
Ndef('chP1ada').set(\map, ~possibles.rotate(1));
(
i = ~possibles.size.rand;
j = ~possibles.size.rand;
o = ~possibles[i];
~possibles[i] = ~possibles[j];
~possibles[j] = o;
Ndef('chP1ada').set(\map, ~possibles);
)
NTSS.run;

~possibles[0] = 25;
~possibles[1] = 0;
~possibles[25] = 1
Ndef('chP1ada').set(\map, ~possibles.scramble);







NTSS.filenameSymbol.asString.dirname.dirname.openOS

.asString.dirname.dirname



//This for Trajectories:
Quarks.install("https://github.com/aiberlin/AbsRel");
Quark("AbsRel").update;

thisProcess.recompile;

t = Trajectories();
t.attach(0, Ndef('chP1ada'));
t.attach(1, Ndef('chP2bob'));
t.actions[1] = {|vals| vals.postln };