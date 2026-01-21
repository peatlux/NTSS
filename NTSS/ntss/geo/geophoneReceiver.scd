/*

TODO:
always record if realtime input
autostart sim if no realtime input
never record if simulated input
start simulation when realtime drops out?


GEOPHONE SETUP:

X for a given geodur (e.g. 15 mins):
X always capture sound from geophone to disk / soundfile,
X reopen every geodur

x always write continuously into
x a short buffer for current signal
x a long buffer with geodur // preload from soundfile
- write index where now is
- loop valid time in buffer with given speedup?

OSCdef.trace(false)
OSCdef.trace(true)

MFdef(\geoData).enable(\post);
MFdef(\geoData).disable(\post);



*/

// put everything geo here
q = q ? ();
q.geo = q.geo ? ();
q.geo.recdur = 60 * 60;

(
MFdef(\geoData).add(\post, { |array, time|
	"time: % array: %\n".postf(time, array)
});

OSCdef(\test, { |msg, t, sender|
	// translate forwarded string,
	// because we did not manage that in python...
	var str = msg[1].asString;
	var arrStr = "[" + str.drop(9).drop(-2) + "]";
	var array = arrStr.interpret;
	var time = array[0];
	var rawwave = array.drop(1);
	// most of the time, range seemed to be 16384 +-8192,
	// but to be safe, we scale to linear 15 bit:
	var wave = rawwave - 16384 / 16384;

	// sender.postln;
	// if sender is from outside SC (not sim)
		// then start rec now
	if (sender.port != NetAddr.langPort) {
		//  and not recording yet, then start rec
		if (q.geo.isRecording.not) {
			q.geo.startRec;
		};
	};
	MFdef(\geoData).value(wave, time);

}, "/test").permanent_(true);
);

MFdef(\geoData).enable(\post);
MFdef(\geoData).disable(\post);


MFdef(\geoData).add(\average, { |wave, time|
	q.geo.avg = wave.mean;
});

(
MFdef(\geoData).add(\record, { |wave, time|
	// "writing % samples\n".postf(wave.size);
	if (q.geo.sf.notNil and: { q.geo.sf.isOpen }) {
		q.geo.sf.writeData(wave.as(FloatArray));
		q.geo.reccount = q.geo.reccount + 1;
		if (q.geo.reccount % 40 == 0) {
			"geo recorded % secs now.\n".postf(q.geo.reccount div: 4);
			if (q.geo.recdur <= (q.geo.reccount div: 4)) {
				"restart rec after q.geo.recdur ended:".postln;
				q.geo.startRec;
				q.geo.reccount = 0;
			};
		};
	};
});

q.geo.startRec = {
	"rec starts".postln;
	try { q.geo.sf.close };
	// q.geo.sfpath = "~/Desktop/geodata%.aiff".format(Date.getDate.stamp	.postln.standardizePath;
	q.geo.sfpath = "~/Music/biophony/geophone_rpi/geodata%.aiff".format(Date.getDate.stamp)
	.postln.standardizePath;
	q.geo.sf = SoundFile.openWrite(q.geo.sfpath, "aiff", "float", 1, 100);
	MFdef(\geoData).enable(\record);
	q.geo.reccount = 0;
};

q.geo.endRec = {
	MFdef(\geoData).disable(\record);
	try { q.geo.sf.close };
	"stopped recording, can read soundfile now.".postln;
};

CmdPeriod.add({ q.geo.endRec });

q.geo.isRecording = { q.geo.sf.notNil and: { q.geo.sf.isOpen } };

q.geo.searchpath = "~/Seafile/BiophonySetup/soundsMono/geo/*";
q.geo.soundfiles = {
	SoundFile.collect(q.geo.searchpath)
	.select(_.numFrames > 0);
};

q.geo.filebuf = Buffer.read(s, q.geo.soundfiles.last.path);


// sound players
Spec.add(\speedup, [1, 441, \exp]);

Ndef('geoFile', { |speedup = 10, loop = 1|
	var buf = q.geo.filebuf;
	PlayBuf.ar(1, buf, BufRateScale.kr(buf) * speedup, loop: loop > 0.5);
}).vol_(0.5);

//// live geodata signal buffer with 1 second = 100 values
q.geo.livebuf = Buffer.alloc(s, 100);

Ndef(\geoSigLive, {
	var readpos = LFSaw.kr(1, -1).range(0, q.geo.livebuf.numFrames);
	BufRd.kr(1, q.geo.livebuf.bufnum, readpos, 1, 4);
});

MFdef(\geoData).add(\controlSignal, { |wave|
	q.geo.liveIndex = q.geo.liveIndex ? 0 + 25 % q.geo.livebuf.numFrames;
	q.geo.livebuf.sendCollection(wave, q.geo.liveIndex);
	q.geo.longIndex = q.geo.longIndex ? 0 + 25 % q.geo.longbuf.numFrames;
	q.geo.longbuf.sendCollection(wave, q.geo.longIndex);

	wave;
});

// last 5 mins
q.geo.longbuf = Buffer.read(s, q.geo.soundfiles.last.path, 100 * 300);
try { s.sync };
/*
q.geo.longbuf.plot;
*/

Ndef(\geoLive, { |direct = 1, sonif = 1, freq = 100, mod = 0.5|
	var geoSig = Ndef(\geoSigLive).kr;
	LPF.ar(
		SinOsc.ar(geoSig.clip2(1) * mod * 0.5 + 1 * freq)
		* Amplitude.kr(geoSig, 0.01, 0.3) * sonif
		+
		K2A.ar(geoSig.lag(0.01) * direct),
		freq * 2
	) * 0.5;
}).vol_(0.5);

Ndef(\geoLong, { |speedup = 10, loop = 1|
	var buf = q.geo.longbuf;
	PlayBuf.ar(1, buf, 100 / SampleRate.ir * speedup, loop:  loop > 0.5);
}).vol_(0.5);

WinBounds.addMake(\geoPlaya, {
	var win = Window("geoPlaya", Rect(210, (0@400).flipY.y, 400, 400)).front;
	var ndefs = [ Ndef('geoFile'), Ndef('geoLive'), Ndef('geoLong') ];
	win.addFlowLayout;
	TdefGui(Tdef(\geoSim), 0, win);
	ndefs.do { |ndef|
		var gui = NdefGui(ndef.postln, ndef.controlKeys.size + 1, win);
		q.tuneNameView(gui);
		ProxyMeter.addNdefGui(gui);
		win.view.decorator.nextLine.shift(0, 5);
	};
	win
});

Butz.add(\geoPlaya, { WinBounds.showOrMake(\geoPlaya) });

);