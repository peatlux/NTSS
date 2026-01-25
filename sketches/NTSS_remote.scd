// sketch how to send state to remote GUIs

n = NetAddr.localAddr;

~pcSplits = [\ProxyChain, \halo, \settings, \panner, \settings ];

OSCdef(\ntssPCState, { |msg|
	msg.postcs;
}, \ntssPCState)

// handmade state message
(
n.sendMsg(\ntssPCState, *[
	ProxyChain: \ch01ada,
	halo: [srcNdef: \allArm, \sndfile: \tralala],
	isPlaying: true, vol: 0.5, monitorPlaying: false,
	amps: [0.6, 0.3],
	settings: Ndef(\ch01ada).getKeysValues.flat,
	panner: \chP01ada,
	panName: \panFixed,
	settings: Ndef(\chP01ada).getKeysValues.flat
].flat)
)


// get state as flat array to send / broadcast
MFdef(\getPCState).add(\get, { |pchain, haloNames|
	var halo = pchain.getHalo;
	var panner = pchain.getHalo.panner;
	[
		ProxyChain: pchain.key,
		halo: [srcName: try { halo.src.key }, \sfname: halo.sndfile],
		isPlaying: true, vol: 0.5, monitorPlaying: false,
		amps: [0.6, 0.3],
		settings: Ndef(\ch01ada).getKeysValues.flat,
		panner: panner.key,
		panName: pchain.getHalo.panName,
		settings: panner.getKeysValues.flat
	]
});

n.sendMsg(\ntssPCState, *MFdef(\getPCState).(q.pchains[0]).flat);

// decode received flat array to check and set
MFdef(\decodePCState).add(\get, { |pchain, flatState|

});

// same for Ndefs
MFdef(\getNdefState).add(\get, { |ndef, haloNames|

});