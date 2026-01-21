/*
Make one 20ch panner for one mono input:
circle choose which ring to go to,
cirWidth opens to more than 2 rings
pos sets position in circle,
posWidth opens to more chans;
modRate and modDepth modulate pos with a sinosc

this could be a multi-panning algorithm for any sound source

check giui2.scd for the gui of it
*/

Spec.add(\cirWidth, \unipolar);
Spec.add(\circle, [0, 3]);
Spec.add(\pos, [0, 2]);
Spec.add(\posWidth, \unipolar);
Spec.add(\rotRate, [-5, 5]);
Spec.add(\modRate, [0, 5, 8]);
Spec.add(\modDepth, [0, 5, 3]);


Spec.add(\srcBus, [s.options.firstPrivateBus] + [0, 32] ++ [\lin, 1]);

q.rotoNames = q.numPmcs.collect { |i| (\panRoto ++ (i + 1)).asSymbol };

q.rotoPans = q.rotoNames.collect { |name, i|
	var ndef = Ndef(name);
	var krBus = Bus.control(s, 4);

	Ndef(name).addHalo(\krBus, krBus);

	Ndef(name, { |srcBus = 64,
		pos = 0, posWidth = 0,
		circle  = 0, cirWidth = 0,
		rotRate = 0, modRate = 0.05, modDepth = 1|

		var in = Limiter.ar(InFeedback.ar(srcBus, 1));

		var circleAmp = cirWidth.linexp(0, 1, 1, 0.4);
		var cirPan2 = Pan2.ar(in, cirWidth ** 2 * 2 - 1, circleAmp);
		var cirWidth2 = (cirWidth  ** 2).linlin(0, 1, 2, 6);
		var circleMagnet =  circle + ((circle * -2pi).sin * 0.15)/2;
		var circles = PanAz.ar(4, cirPan2[0], circleMagnet.lag(1), 1, cirWidth2, 0)
		+ cirPan2[1].dup(4);

		var posAmp = posWidth.linexp(0, 1, 1, 0.4);
		var posWidth2 = (posWidth  ** 2).linlin(0, 1, 2, 6);
		var panPos2 = posWidth ** 2 * 2 - 1;
		var rotPos = LFSaw.kr(rotRate ** 2);
		var posMod = SinOsc.kr((modRate / modDepth.lag(2).max(1)).lag(2), 0, modDepth.lag(2));
		var posAll = pos.lag(2) + posMod + rotPos;
		Out.kr(krBus, [posAll, posWidth2, circleMagnet.lag(1), cirWidth2]);

		circles.collect { |cirChan, i|
			var posPan2 = Pan2.ar(cirChan, panPos2, posAmp);
			PanAz.ar(5, posPan2[0], posAll, 1, posWidth2, 0) + posPan2[1].dup(5);
		}.flat;

	})
	.fadeTime_(3)
	.vol_(0.25);

};