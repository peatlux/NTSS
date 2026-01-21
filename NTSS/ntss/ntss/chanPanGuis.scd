/*
4 kinds of panners for the Pmcs:

fixedPan, rotoPan, feedPan, molens

q.pchains.choose.getHalo;

ProxyChainGui(q.pchains[0]);

MFdef(\setPanner).(q.pchains[0], 1);
MFdef(\setPanner).(q.pchains[0], 0);

q.inNames;
q.pchains[0].slotNames.size
*/

(
MFdef(\updatePchWin).add(\proxySource, { |pch|
	var h = pch.getHalo;
	if (h.pxDrag.object != h.src) {
		h.pxDrag.object = h.src
	};
});

MFdef(\updatePchWin).add(\bufPath, { |pch|
	var h = pch.getHalo;
	var filename;
	if (h.mybuf.notNil and: h.mybuf.path.notNil) {
		filename = h.mybuf.path.basename;
		if (h.sfDrag.string != filename) {
			h.sfDrag.string = filename;
		};
	};
});
MFdef(\updatePchWin).add(\panMode, { |pch|
	var h = pch.getHalo;
	var panName = h.panName;
	var panIndex = q.panNames.indexOf(panName);
	h.panbuts.do { |but, i|
		var panVal = (i == panIndex).binaryValue;
		if (but.value != panVal) { but.value = panVal }
	};
});

/*
MFdef(\updatePchWin).(q.pchains[4]);
*/
);

(
q.pchains.do { |pch, i|
	Butz.add(pch.key, { WinBounds.showOrMake(pch.key) });

	WinBounds.addMake(pch.key, {
		var w = Window(pch.key, Rect(100 * i + 300, 600, 500, 820)).front;
		var flow = w.addFlowLayout;
		var font = Font(Font.defaultMonoFace, 14);

		var inputPop, pxDrag, sfDrag, pchgui, pannerGui, panbuts, panguibounds;

		// make input selections: audio inputs
		inputPop = EZPopUpMenu(w, 160@30, \anaIn, q.inNames,
			{ |pop|
				pop.item.postln;
				pch.set(\micBus, pop.value);
			}, labelWidth: 45
		).font_(font)
		.value_(pch.proxy.get(\micBus).asInteger)
		;

		// dragsink for playing in proxies
		pxDrag = DragBoth(w, 160@30).align_(\center).font = font;
		if (pch.getHalo(\src).notNil) {
			pxDrag.object = pch.getHalo(\src);
		} {
			pxDrag.string = "drop a proxy/chain!";
		};
		pch.addHalo(\pxDrag, pxDrag);
		// dragsink for dropping in soundfiles into buffer
		sfDrag = DragBoth(w, 160@30).align_(\center).font = font;
		if (pch.getHalo(\sfname).notNil) {
			sfDrag.object = pch.getHalo(\sfname);
		} {
			sfDrag.string = "drop a soundfile!";
		};
		pch.addHalo(\sfDrag, sfDrag);

		pxDrag.receiveDragHandler = { arg v;
			var rawdrag = View.currentDrag.postcs;
			// support dragged code - string objects
			var drag = if (rawdrag.isString) { rawdrag.interpret } { rawdrag };
			MFdef(\setSrc).(pch, drag);
		};


		sfDrag.receiveDragHandler = { arg v;
			var path = View.currentDrag.postln;
			MFdef(\setSndfile).(pch, path);
			MFdef(\updatepchhWin).(pch);
		};

		pchgui = ProxyChainGui(pch, 24, w);
		pchgui.editGui.paramGui.paramViews[(0..2)].do(_.enabled_(false));
		q.tuneNameView(pchgui.editGui);
		pchgui.buttons.first.enabled_(false);
		pchgui.buttons[pch.slotNames.size - 1].enabled_(false);
		ProxyMeter.addNdefGui(pchgui.editGui);

		pchgui.buttons[0].valueAction_(0);
		defer ({ pchgui.buttons[0].valueAction_(1) }, 0.25);

		panbuts = q.panNames.collect { |panName, i|
			Button(w, Rect(0, 0, 480 / q.panNames.size, 30)).font_(f)
			.states_([
				[ panName ],
				[ panName, Color.black, Color.green ]
			]).font_(font)
			.value_((pch.getHalo.panName == panName).binaryValue)
			.action = { |bt|
				if (bt.value == 1) {
					"switch to %\n".postf(panName);
					MFdef(\setPanner).(pch, i);
				}
			}
		};
		pch.addHalo(\panbuts, panbuts);

		pannerGui = NdefGui(pch.getHalo(\panner).postln, 12, w, 490@250);
		pannerGui.paramGui.paramViews[0].enabled_(false);
		q.tuneNameView(pannerGui);
		ProxyMeter.addNdefGui(pannerGui);
		defer({
			SkipJack({ MFdef(\updatePchWin).(pch) }, 0.5, { w.isClosed });
		}, 0.5);

		w;
	});
};
);

