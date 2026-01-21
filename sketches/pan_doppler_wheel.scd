// Sonoaviatic style Doppler Wheel as ProxyChanin.3. module
// HH/AdC ca. 2004 - 2022
// ToDo: add assymetry offset / elliptic curve

(
ProxyChain.add3('dopler_whel', \filterIn -> { | in, amp = 1, speed = 0.051, dimension=16, asym=1, ampExp = 0.75, lag=12.5|

	var wheelRotAngle, wheelXY, xys, dists, dt, dAmp , rad=1;
	var poly = 5; // 5 speakers on the wheel

	dimension = dimension.lag3(lag);
	wheelRotAngle = LFSaw.kr(speed.neg.lag3(lag), 0.5, pi);
	// pos of rotating object.
	wheelXY = dimension * [wheelRotAngle.cos, wheelRotAngle.sin ]
	* [1, asym]; // added ellipsoidity

	// pos of virtual speakers/listeners
	xys = ((0,1..poly-1)*2pi/poly).collect({ arg ang;
		[ang.sin, ang.cos]
	}) * rad ;

	// distances between rotator and listeners
	dists = xys.collect({ arg pair;
		(pair/xys.flat.sort.last * dimension
			- wheelXY).squared.sum + 1
	});

	dt = dists.sqrt / 330;
	// amp compensation
	dAmp = (dists ** (ampExp.neg * ;
		(dimension ** 0.45)).reciprocal.lag3(1));
	in = Limiter.ar(in.sum  * dAmp * amp.lag(0.1) , 0.97, 0.1);
	DelayC.ar(in, 0.5, dt);
}, 1, (

	\amp: \gain,
	\speed: [-10, 50, 3],
	\dimension: [0.5, 100, \exp],
	\ampExp: [0.1, 10, \exp, 0.1],
	\lag: [0, 120, 6, 1],
	\asym: [0.3, 3, \exp, 0.1]

)
)
);