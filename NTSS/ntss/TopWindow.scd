Butz.add(\BIOPHONIUM, { WinBounds.showOrMake(\BIOPHONIUM, true) });

WinBounds.addMake(\BIOPHONIUM, {
	var f = Font("Monaco", 18);
	var f2 = Font("Helvetica", 14);
	var w = Window("BIOPHONIUM", Rect(520, Window.availableBounds.height - 500, 900, 450)).front;
	var allViews, leftCol;
	w.alpha = 0.8;
	w.addFlowLayout;

	leftCol = CompositeView(w, 60@440);
	leftCol.addFlowLayout;

	StaticText(leftCol, 60@50).string_("Main Vol").font_(f);

	// 	VolumeGui(s.volume, leftCol, Rect(0, 50, 60, 440));

	allViews = q.pchains.collect { |pch, i|
		var name = pch.key;
		var panna = pch.getHalo.panner;
		var widCol = w.bounds.width - 100 / 8.2, hi = w.bounds.height - 10;
		var wid = widCol - 4;
		var comp = CompositeView(w, widCol@hi).background_(Color.hsv(i / 8, 1, 1));
		var flow = comp.addFlowLayout(0@0, 0@0);
		var label = Button(comp, wid@30).states_([[name]]).font_(f)
		.action = { Butz.run(name) };
		var inPop = EZPopUpMenu(comp, wid@30).font_(f2).items = q.inNames;
		var proxyDrag = DragBoth(comp, wid@30).font_(f2).object = "<proxy>";



		var sfDrag = DragBoth(comp, wid@30).font_(f2).object = "<sndfile>";

		var moni = MonitorGui(panna, comp, wid@220);

		var playBt = Button(comp, wid@30).states_([
			["PLAY"],["PLAY", Color.black, Color.green]
		]).font_(f)
		.action_({ |bt| panna.play; stopBt.value = 0 });
		var stopBt = Button(comp, wid@30).states_([
			["STOP"],
			["STOP", Color.white, Color.red],
		]).font_(f)
		.action_({ |bt| panna.stop; playBt.value = 0 });
		ProxyMeter.addMonitorGui(moni);

		proxyDrag.receiveDragHandler = { arg v;
			var rawdrag = View.currentDrag.postcs;
			// support dragged code - string objects
			var drag = if (rawdrag.isString) { rawdrag.interpret } { rawdrag };
			MFdef(\setSrc).(pch, drag);
			MFdef(\updatePchWin).(pch);
		};
		proxyDrag.action = { |drag|  "clicked".postln };

		sfDrag.receiveDragHandler = { arg v;
			var path = View.currentDrag.postln;
			MFdef(\setSndfile).(pch, path);
			MFdef(\updatePchWin).(pch);
		};



		[inPop, proxyDrag, sfDrag, playBt, stopBt]
	}.flop;

	SkipJack({
		// inPops:
		allViews[0].do { |pop, i|
			var micBusnum = q.pchains[i].proxy.get(\micBus);
			if (pop.value != micBusnum) { pop.value = micBusnum };
		};
		// proxy:
		allViews[1].do { |drag, i|
			var pc = q.pchains[i];
			var inProxy = pc.getHalo.src;
			if (inProxy.notNil) {
				// [drag.object, inProxy].postcs;
				if (drag.object != inProxy) { drag.object = inProxy };
			};
		};

		// sndfile:
		allViews[2].do { |drag, i|
			var pch = q.pchains[i];
			var sfname = pch.getHalo.sfname;
			if (sfname.notNil) {
				if (drag.object != sfname) { drag.object = sfname };
			};
		};

		// play/stop buttons:
		q.pchains.do { |pch, i|
			var panner = pch.getHalo.panner;
			var playBt = allViews[3][i];
			var stopBt = allViews[4][i];
			var pannerPlaying = panner.monitor.isPlaying.binaryValue;
			if (pannerPlaying != playBt.value or: { 1-pannerPlaying != stopBt.value }) {
				playBt.value = pannerPlaying;
				stopBt.value = 1-pannerPlaying;
			};
		};

	}, 0.5, { w.isClosed }, \bio);

	w;
});
