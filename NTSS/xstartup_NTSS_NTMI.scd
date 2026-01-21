/***
example startupfile for NTMI and NTSS setup:
- copy to
StartupFile.filesDir
- then adjust path!

this loads NTSS first,
then NTMI with no MainFX and no reboot.
adds a window for dragsources for NTMI processes,
so one can drag them to NTSS channels.

***/
//// some things to set before loading anything:

// I want that sampleRate:
s.options.sampleRate = 48000;

//
q = q ? ();
q.ntss = q.ntss ? ();
// special ntss settings would go here...


// first load NTSS, which boots server.
// adjust path to where you have it:
"~/src/aiberlin/Biophony/00_loadMe_NTSS.scd".standardizePath.loadPaths;

// tell ntss what to do when loaded:
q.ntss.finalSetup = {
	// wait a bit
	0.1.wait;

	// prepare groups for switchable NdefMixer:
	q.ndef.groupNames = [\ntssChan, \ntssPan, \NTMI];
	q.ndef.groups.put(\NTMI, NTMI.processes);

	MainFX(s).proxy.set(\mainvol, 0.25);

	// then load NTMI, with some special settings:
	NTMI.reboot = false;
	NTMI.usesMainFX = false;

	NTMI.run;

	// tell NTMI what to do when done:
	NTMI.finalSetup = {
		//make sure the NTMI sounds play directly:
		NTMI.processes.do(_.set(\amp, 0.25));
		q.ndef.groups.keys.postcs;
		q.ndef.groups.put(\NTMI, NTMI.processes);

		q.ndef.groups.keys;

		// for choosing Ndefs as NTSS sources,
		// get these from NTMI:
		q.ntss.getSrcNdefs = {
			NTMI.slots.zz ++
			NTMI.ndefs ++
			NTMI.processes.copy.removeAll(NTMI.ndefs);
		};

		// finetune Butzes
		Butz(\NTMI).remove(\miniNTMI); // not fully working
		Butz(\NTMI).add(\allSrcNdefs, { WinBounds.showOrMake(\allSrcNdefs) });
		// redirect to new flexible NdefMixer
		Butz(\NTMI).add(\ndefMixer, { WinBounds.showOrMake(\NdefMixer) });
		// redirect to general MainFX
		Butz(\NTMI).add(\mainFX, { WinBounds.showOrMake(\MainFX) });

		// end with NTSS Butz and N_T_S_S window in front
		Butz.curr = \NTSS;
		Butz.run(\N_T_S_S);
	};
};

