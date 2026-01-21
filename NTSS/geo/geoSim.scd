/* geophone data simulator
- generate an array of 25 numbers as a running signal
- send at everz 0.25 sec
- send as message /test with a string that converts to data array and time
*/

(
// send data from file;

Tdef(\geoSim, { |ev|
	var soundfile, allData, data, dataStr;
	~addr = NetAddr.localAddr;
	"Tdef geoSim starts sending data".postln;
	"dont rerecord simulated data...".postln;
	q.geo.end;
	MFdef('geoData').disable('record');

	inf.do { |i|
		soundfile = q.geo.soundfiles.choose;
		"choosing soundfile %\n"
		"% frames, % duration.\n".postf(
			soundfile.path.basename,
			soundfile.numFrames,
			soundfile.duration.asTimeString);

		SoundFile.use(soundfile.path, { |sf|
			allData = FloatArray.newClear(sf.numFrames);
			sf.readData(allData);
		});

		(0, 25 .. allData.size).do { |startindex|
			data = allData.copyRange(startindex, startindex + 24)
			.collect { |val| val + 2 * 8192 };
			// data.round(0.01).postln;
			dataStr = ("exp..." + ([i / 4] ++ data)).cs;
			~addr.sendMsg("/test", dataStr);
			0.25.wait;
			if (startindex % 6000 == 0) {
				"... Tdef geoSim sending data ...".postln;
			};
		};
	}
}).play;
);

// // stupid noise generator ...
// Tdef(\geoSimNoise).set(\maxamp, 0.5);
// Tdef(\geoSimNoise).set(\maxamp, 0.38);
// Tdef(\geoSimNoise, { |ev|
//
// 	var num = 0;
// 	var data, dataStr;
// 	inf.do { |i|
// 		var maxamp = ev.maxamp;
// 		data = 25.collect {
// 			num = (num + maxamp.bilinrand).clip2(maxamp);
// 			(num + 1 * 16384).asInteger;
// 		};
// 		// data.postcs;
// 		dataStr = ("exp..." + ([i / 4] ++ data)).cs;
// 		~addr.sendMsg("/test", dataStr);
// 		0.25.wait;
// 	}
// });
//

