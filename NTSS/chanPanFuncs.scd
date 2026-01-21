/*
Switchable panners for a Mono Ndef bus going to ring of 5 * 4 outs:

srcPos sets position in circle,
srcWidth opens to more chans
send levels to 4 rings are independent

pendRate and pendDepth modulate pos with a sinosc

Ndef(\pan1, ProxyChain.allSources[\panFixed]);
Ndef(\pan1, ProxyChain.allSources[\panFixed]);
Ndef(\pan1).gui;

Ndef(\pan1).gui;

*/

/// BIOPHONY Panners: //////

q.panNames = [ \panFixed, \panRoto, \panFeed];


// shared params:
Spec.add(\srcBus, [s.options.firstPrivateBus] + [0, 31] ++ [\lin, 1]);
Spec.add(\srcPos, [-5, 5]);
Spec.add(\srcWidth, \unipolar);
// separate levels on 4 rings:
q.ringNames = [\inside, \shakers, \outside, \bigPA];
q.ringNames.do (Spec.add(_, \amp));

ProxyChain.add3(\panFixed, { |srcBus = 0, srcPos = 0, srcWidth = 0|
	// \panFixed
	var width = (srcWidth  ** 2).linlin(0, 1, 2, 6);
	var widAmp = srcWidth.linexp(0, 1, 1, 0.4);
	var in = InFeedback.ar(srcBus);
	var amps = q.ringNames.collect(_.kr(0.25));
	var panned = PanAz.ar(5, in, srcPos * 0.4, amps * widAmp, width, 0).flat;
	panned;
});


Spec.add(\rotRate, [-5, 5]);
Spec.add(\pendRate, [0, 5, 8]);
Spec.add(\pendDepth, [0, 5, 3]);
Spec.add(\circle, [0, 3]);
Spec.add(\cirWidth, \unipolar);


ProxyChain.add3(\panRoto, { |srcBus = 64,
	srcPos = 0, srcWidth = 0,
	circle  = 0, cirWidth = 0,
	rotRate = 0, pendRate = 0.05, pendDepth = 1|
	// \panRoto

	var in = Limiter.ar(InFeedback.ar(srcBus, 1), 1, 0.001);

	var circleAmp = cirWidth.linexp(0, 1, 1, 0.4);
	var cirPan2 = Pan2.ar(in, cirWidth ** 2 * 2 - 1, circleAmp);
	var cirWidth2 = (cirWidth  ** 2).linlin(0, 1, 2, 6);
	var circleMagnet =  circle + ((circle * -2pi).sin * 0.15)/2;
	var circles = PanAz.ar(4, cirPan2[0], circleMagnet.lag(1), 1, cirWidth2, 0)
	+ cirPan2[1].dup(4);

	var posAmp = srcWidth.linexp(0, 1, 1, 0.4);
	var srcWidth2 = (srcWidth  ** 2).linlin(0, 1, 2, 6);
	var panPos2 = srcWidth ** 2 * 2 - 1;
	var rotPos = LFSaw.kr(rotRate ** 2);
	var posMod = SinOsc.kr((pendRate / pendDepth.lag(2).max(1)).lag(2), 0, pendDepth.lag(2));
	var posAll = (srcPos.lag(2) * 0.4) + posMod + rotPos;
	// Out.kr(krBus, [posAll, srcWidth2, circleMagnet.lag(1), cirWidth2]);

	circles.collect { |cirChan, i|
		var posPan2 = Pan2.ar(cirChan, panPos2, posAmp);
		PanAz.ar(5, posPan2[0], posAll, 1, srcWidth2, 0) + posPan2[1].dup(5);
	}.flat;

}, 0.25);


Spec.add(\direct, \amp);
Spec.add(\delayed, \amp);
Spec.add(\feedback, \amp);
Spec.add(\inside, \amp);
Spec.add(\shakers, \amp);
Spec.add(\outside, \amp);
Spec.add(\bigPA, \amp);
Spec.add(\rotate, [-5, 5]);

ProxyChain.add3(\panFeed, { |srcBus, srcPos = 0, srcWidth = 0,
	direct = 1, delayed = 0.8, feedback = 0.8, delaytime = 2, rotate = 0,
	inside = 0.5, shakers = 0.2, outside = 0.5, bigPA = 0.5|

	var width = (srcWidth  ** 2).linlin(0, 1, 2, 5);
	var in = PanAz.ar(5, InFeedback.ar(srcBus), srcPos.lag(2) * 0.4, 1, width, 0);
	var feedy = LocalIn.ar(5) * feedback.lag(2);
	var dts = delaytime.lag(5) * LFDNoise3.kr(0.03 ! 5, 0.02, 0.98);
	var delays = DelayL.ar(LeakDC.ar(in + feedy, 0.998), 10, dts);
	//// cheap but clumsy fixed out with rotate
	//// var rotated = delays.rotate(1);

	////// better rotate with PanAz:
	var rotated = delays.collect { |chan, i|
		var rotatedpos = i + rotate * (2 / q.ntss.speakersOrder.size);
		PanAz.ar(5, chan, rotatedpos, 1, 2, 0);
	}.sum;

	rotated = Limiter.ar(rotated, 1, 0.001);
	LocalOut.ar(rotated);

	// 5 outs, table-multiplied by ring amps

	(((in * direct.lag(2)) + (rotated * delayed.lag(2)))
		*.t
		[ inside, shakers, outside, bigPA ].collect(_.lag(1)))
	.flop.flat;
});

/// NTSS Panners: //////

q.ntss = q.ntss ? ();
q.ntss.spat = q.ntss.spat ? ();

/** distance based amplitude panning:
k - small is very focused, big is wide
x, y are positions of left and right channels

**/
q.ntss.getSpat = { arg ntss, name;
	{ arg srcBus;
		var in = InFeedback.ar(srcBus);
		q.ntss.spat[name].(name, q.ntss.speakers, in);
	};
};

q.ntss.spat.dbap = { arg name, speakers, snd;
	var d, g, norm, srcPos;
	var k = 11 - "%_k".format(name).asSymbol.kr(1, spec:[1,10]);
	var x = "%_x".format(name).asSymbol.kr(0, spec:[-1,1]);
	var y = "%_y".format(name).asSymbol.kr(0, spec:[-1,1]);
	var sig;
	srcPos = [x,y];
	sig = snd;
	d = speakers.collect { |p|
		var val = (srcPos - p);
		val[0].hypot(val[1])
	};
	g = 1/(d.pow(k) + 1e-6);
	norm = (g.squared.sum).sqrt;
	g = g / norm;
	sig * g;
};



/** distance based delay & amplitude panning:
k - small is very focused, big is wide
x, y are positions of left and right channels
z - is what?
spread is similar to k
**/

// was dlypan

q.ntss.spat.delayspat = { arg name, speakers, snd;
	var k = "%_k".format(name).asSymbol.kr(1, spec:[1,10]);
	var z = "%_z".format(name).asSymbol.kr(1, spec:[1,30]);
	var x = "%_x".format(name).asSymbol.kr(0, spec:[-1,1])*k*z;
	var y = "%_y".format(name).asSymbol.kr(0, spec:[-1,1])*k*z;
	var spread = 11 - "%_spread".format(name).asSymbol.kr(1, spec:[1,10]);
	var dists = speakers.collect { |pt|
		pt = Point(*(pt)*z);
		(pt.x - x).hypot(pt.y - y)
	};
	var g, norm;
	dists = dists.lag(0.3);
	g = 1/(dists.pow(spread) + 1e-6);
	norm = (g.squared.sum).sqrt;
	g = g / norm;
	DelayC.ar(snd*g, 1, dists / 344, 1/(1+dists).sqrt);
};

// for each source channel, on/off for each speaker
q.ntss.spat.direct = { arg name, speakers, snd;
	var nchannels = speakers.size;
	var output = "%_out".format(name).asSymbol.kr(0, spec:[0,nchannels-1, 0, 1]);
	(0..nchannels-1).collect {|idx|
		snd * Select.kr(BinaryOpUGen('==', output, idx), [Silent.ar, DC.ar(1)]);
	};
};

// for each source channel, set level for each speaker
q.ntss.spat.mixer = { arg name, speakers, snd;
	var nchannels = speakers.size;
	var outs = nchannels.collect {|i| "%_out".format(q.ntss.speakersActive[i]).asSymbol.kr(0, spec: \amp) };
	snd * outs;
};

/*** multitap comb filters on each speaker
- details to follow
***/

q.ntss.spat.taps = { arg name, speakers, snd;
	var nspeakers = speakers.size;
	var dryKr = \dry.kr(1, 1, spec:\amp);
	var sendKr = \send.kr(1, 1, spec:\amp);
	var taps = nspeakers.collect {|idx|
		"%_tap_%".format(name, idx).asSymbol.kr(0, spec:[0,4])
	};
	//(snd*\dry.kr(1, spec:\amp)) + CombC.ar(snd * \send.kr(0, spec:\amp), 4, taps, 6);
	(snd*dryKr) + CombC.ar(snd * sendKr, 4, taps, 0);
};

/*** multitap comb filters on each speaker, with feedback
- details to follow
***/
q.ntss.spat.tapsfb = { arg name, speakers, snd;
	var nspeakers = speakers.size;
	var dryKr = \dry.kr(1, 1, spec:\amp);
	var sendKr = \send.kr(1, 1, spec:\amp);
	var fbKr = \fb.kr(0, spec:\amp);

	var fb = LocalIn.ar(nspeakers);
	var taps = nspeakers.collect {|idx|
		"%_tap_%".format(name, idx).asSymbol.kr(0, spec:[0,4])
	};
	var delayline = DelayC.ar(snd * sendKr + fb, 4, taps);
	delayline = PitchShift.ar(delayline, 0.2, {rrand(1.01,0.99)}!nspeakers);
	LocalOut.ar(delayline * fbKr);
	(snd * dryKr) + delayline;
};


q.ntss.spat.keys.do {|spatName|
	ProxyChain.add3(spatName, q.ntss.getSpat(spatName));
};


q.panNames = q.panNames ++ q.ntss.spat.keys(Array).sort;