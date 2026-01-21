/*
StartupFile.writeStartupFileToExternalPath('Biophony', thisProcess.nowExecutingPath);
StartupFile.writeRedirectFile('Biophony');
*/

//XConnect(\gencomp);

q = q ? ();

q.ntss = q.ntss ? ();

//s.options.device = "UMC1820"; // Behringer 1820 in room 111
s.options.numInputBusChannels = 30;
s.options.memSize = 8192 * 32; // boost to 256MB for delaylines
s.options.numAudioBusChannels = 2048;
s.options.maxNodes = 4096;
s.options.numWireBufs = 512;
s.options.hardwareBufferSize = 256;
s.options.sampleRate = 44100;

q.ntss.speakersDict = (
	sub0:    [ 0.0, 0.0, 0.0],
    ldl7:    [ 0.5,-1.0, 2.0],
    wd12:    [ 1.5, 0.5, 0.2],
    wd11:    [ 3.5, 0.5, 0.2],
    crypt3:  [ 5.5, 0.0, 0.0],
    brect:   [ 6.5, 0.5, 1.2],
    wd13:    [ 6.0, 1.5, 1.0],
    cabass1: [ 6.0, 3.8, 3.5],
    cryptA:  [ 4.5,-0.5, 1.0],
    braun1:  [ 4.5, 2.0, 2.2],
    behring: [ 2.5, 3.0, 2.0],
	noname:  [ 2.4, 4.0, 3.5],
    bluecab: [ 2.2, 5.5, 2.2],
    bw5:     [ 1.2, 5.3, 0.0],
    ldl8:    [-3.5, 5.2, 0.0],
	sub1:    [-3.5, 2.8, 0.0],
    braun2:  [-1.0, 3.8, 3.0],
    wd14:    [-3.5, 1.0, 0.5],
    bw6:     [-4.0,-1.0, 1.3],
    cabass2: [-0.5, 2.8, 0.8],
    cabass0: [-0.5, 2.9, 0.8],
);


q.ntss.speakersOrder = [
	// 7 XLR outs from X32, 7 to Denon amp
	\bw5,
	\bw6,
	\cabass2,
	\cabass0,
	\cabass1,
	\ldl7,
	\ldl8,

	// last XLR out from X32
	\empty,

	// 8 XLR outs from s16
	\empty,
	\empty,
	\empty,
	\empty,
	\empty,
	\empty,
	\empty,
	\empty,

	// 5 JACK outs from s16-RME-ADAT to Yamaha Amp
	\wd14,
	\wd13,
	\wd12,
	\wd11,
	\noname,

	// 2 JACK outs from s16-RME-ADAT to stereo amp 1
	\braun1,
	\braun2,

	// 1 JACK out from s16-RME-ADAT to stereo amp 2
	\crypt3,

	// aux 1-6 from x32 to active speakers
	\behring,
	\cryptA,
	\bluecab,
	\empty,
	\empty,
	\empty,

	// monitor out
	\sub0,
	\sub1,
];

q.ntss.speakersActive = q.ntss.speakersOrder.reject {|spk| spk == \empty };
q.ntss.speakers = q.ntss.speakersActive.collect {|key|
	var loc = q.ntss.speakersDict[key];
	[loc[0], loc[1], loc[2]]
}.flat.normalize(-1,1).reshape(q.ntss.speakersActive.size, 3);

q.ntss.amp_names = q.ntss.speakers.size.collect {|i| "amp_%".format(i).asSymbol };

q.numPmcs = 16;
~num = q.ntss.speakersOrder.size;
~numIOchans = 32; // 16 for install, 24 for concert
~hideChanNdefs = false;

s.options.numOutputBusChannels = ~num;

q.bio = q. bio ? ();
q.bio.home = thisProcess.nowExecutingPath.dirname.dirname;
MFdef(\findSoundfiles).add(\find, {
	q.bio.soundfiles = SoundFile.collect(q.bio.home +/+ "sounds*/*")
	++ SoundFile.collect(q.bio.home +/+ "sounds*/*/*");
	q.bio.soundfiles.size;

	"*** q.bio.soundfiles found % files. *** \n\n".postf(q.bio.soundfiles.size);
});

MFdef(\findSoundfiles).();

// general specs for everything
Spec.add(\amp4, [0, 4, \amp]);
Spec.add(\amp10, [0, 10, 4.4]);
Spec.add(\level, \amp4);
Spec.add(\gain, \amp4);
Spec.add(\direct, \amp);
Spec.add(\feedback, \amp);

Spec.add(\micBus, [-5, 5]);

Spec.add(\pos, \pan);
Spec.add(\width, [2, 8, \exp]);
Spec.add(\rotate2, [-5, 5]);
Spec.add(\rate2, [-5, 5]);

Spec.add(\delaytime, [0.01, 10, \exp]);

Spec.add(\loop, \unipolar);

// names of analog input channels:
// q.inNames = [
// 	\mic1innen, \mic2innen, \mic3innen,
// 	\mic4aussen, \mic5aussen,
// 	\plonk1bau, \plonk2bau, \plonk3bau,
// 	\str1gang, \string2wind,
// 	\geoRaspi, \geoLom,
// 	\hydWheel, \hydFount,
// 	\line1, \line2, \line3, \line4,
// ].collect { |name, i| i.asString ++ name }.postln;

q.inNames = [
	\kiteMic, \richtMic, \funkMic1,\funkMic2,
	\micA_innen, \micB_innen, \micC_innen,
	\stringGang, \stringWind,
	\plonkBauL, \plonkBauM, \plonkBauR,
	\line1, \line2, \line3, \line4,
	\echoShure, \geoLom,
	\hydroWheel, \hydroFount,
	\angel, \arianeFunk
].collect { |name, i| ((i+1).asString ++ name).asSymbol }.postcs;


// make nameViews better readable
q.tuneNameView = { |q, obj|
	var nameFont = Font(Font.defaultSansFace, 14);
	if (obj.respondsTo(\nameView)) { obj = obj.nameView };
	if (obj.isKindOf(View)) {
		obj.font_(nameFont)
		.stringColor_(Color.white)
		.background_(Color.blue)
	} {
		"q.tuneNameView: obj % has/is no nameView.".postf(obj.cs)
	};
	obj
};
/*
g = NdefGui(Ndef(\x));
q.tuneNameView(g);
*/

// General GUIs

Butz.addMiniMax;
Butz.add(\BIOPHONIUM, {});

Butz.add(\AUTOPILOT, { });
Butz.add(\soundfiles, { q.bio.home.openOS });
// Butz.add(\StartupDial, { StartupFile.dialog });
Butz.add(\SpatioScope, { WinBounds.showOrMake(\SpatioScope) });
Butz.add(\NdefMixer, { WinBounds.showOrMake(\NdefMixer) });
Butz.add(\Levels, { WinBounds.showOrMake(\Levels) });
Butz.add(\LevelControl, { WinBounds.showOrMake(\LevelControl) });

WinBounds.addMake(\NdefMixer, {
	m = NdefMixer(s, 24).moveTo(120,200);
	m.arGuis.do(q.tuneNameView(_));

	ProxyMeter.hideKrs;
	ProxyMeter.addMixer(m);
	m.parent.name_("NdefMixer");
});

WinBounds.addMake(\Levels, {
	var server = s.meter;
	Window.find(server.name).name_("Levels").moveTo(0,0);
});

WinBounds.addMake(\SpatioScope, {
	q.spat = SpatioScope.new(q.ntss.speakers.collect {|sp| Point(*sp)});

	q.spat.magnify_(10);
	q.spat.parent.background_(Color.blue(0.5));
	q.spat.ampViews.do(_.stringColor_(Color.white));
	q.spat.ampViews.do {|view,i|
		view.string = q.ntss.speakersActive[i];
	};
	q.spat.parent.moveTo(120, 480);
	q.spat.parent
});

WinBounds.stored.putAll( (
	BIOPHONIUM: Rect(520, Window.availableBounds.height - 430, 900, 450),
	AUTOPILOT: Rect(124.0, 256.0, 274.0, 126.0),
	SpatioScope: Rect(120, 540, 400, 400),
	NdefMixer: Rect(120, 300, 1086.0, 500),
	Levels: Rect(0.0, 37.0, 58 + (~numIOchans * 38), 230.0),
	LevelControl: Rect(128.0, 36.0, 610.0, 270.0),
	MainFX: Rect(803.0, 642.0, 500, 350),
	geoPlaya: Rect(512.0, 516.0, 400.0, 400.0),
	KeyPlayer: Rect(127.0, 300.0, 434.0, 338.0),
) );

s.waitForBoot {
	Butz.numButz_(20).show;

	Butz.run(\NdefMixer);
	// Butz.run(\Levels);

	0.5.wait;
	"MainFX.scd".postcs.resolveRelative.loadPaths;

	s.volume = -12;

	"make q.buses".postln;
	q.bus_inside  = Bus.audio(s, 5);
	q.bus_outside = Bus.audio(s, 5);
	q.bus_shakers = Bus.audio(s, 5);
	q.bus_bigPA   = Bus.audio(s, 5);

	q.buses = [
		q.bus_inside,
		q.bus_shakers,
		q.bus_outside,
		q.bus_bigPA,
	];

	// make mono sources first:
	try { "geo/geophoneReceiver.scd".postcs.loadRelative };
	try { "geo/geoSim.scd".postcs.loadRelative };

	// play on all single channels
	"one-shot-sampler.scd".postcs.loadRelative;

	// and others ...

	// get biophony panner functions
	"chanPanFuncs.scd".postcs.loadRelative;

	"chain1make.scd".postcs.loadRelative;

	0.2.wait;

	if (~hideChanNdefs) {
		q.pcNames.do { |pcKey| Ndef.all.localhost.removeAt(pcKey) };
	};

	"chanPanGuis.scd".postcs.loadRelative;

	"beatstep.scd".postcs.loadRelative;

	// ("audio buses top: " + s.audioBusAllocator.top).postcs;
	// ("bufs top: " + s.bufferAllocator.top).postcs;

	0.5.wait;
	"TopWindow.scd".postcs.resolveRelative.loadPaths;
	Butz.run(\Biophonium);

	Butz.run('chain1');
	0.1.wait;

	"autopilot.scd".postcs.loadRelative;
	Butz.run('SpatioScope');
	Butz.run('AUTOPILOT');
	Butz.run('BIOPHONIUM');

	1.wait;

	//Tdef(\AUTOPILOT).play;

	WinBounds.restoreAll;
};
