// flexible project class, redirects everything to internal dict:
NTSS {
	classvar <q;
	*initClass {
		q = (
			run: {|dict, path|
				path = (path ? (NTSS.filenameSymbol.asString.dirname.dirname
					+/+ "NTSS/00_loadMe_NTSS.scd"));
				path.postcs.loadPaths
			},
			// init necessary dicts
			defaults: (),
			process: (),
			pre: (),
			slots: (),
			inph: (),
			mfx: (),
		);
		// use defaults automatically if nil:
		NTSS.q.parent = NTSS.q.defaults;
	}

	// redirect everything to NTSS.q:
	*doesNotUnderstand { |selector ... args|
		^q.performList(selector, args)
	}
}
