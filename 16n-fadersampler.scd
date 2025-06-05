(
Server.default.options.outDevice_("ASIO : JackRouter");
Server.default.options.inDevice_("ASIO : JackRouter");
s.options.memSize = 8192 * 64;
s.boot;
)

(
~samples = Array.fill(16, { Array.newClear(128) });
~currentSynths = Array.newClear(16);
~sampleBuffers = Dictionary.new;

~loadSamples = { |folderPath|
  var files = PathName(folderPath).files.select({ |f|
    f.extension.toLower == "wav"
  });

  files.do({ |file, i|
    ~sampleBuffers[i] = Buffer.read(s, file.fullPath);
  });

  // TODO: better distribution
  16.do({ |channel|
    128.do({ |cc|
      var sampleIndex = (cc * files.size / 128).floor;
      ~samples[channel][cc] = ~sampleBuffers[sampleIndex];
    });
  });
};
)

(
SynthDef(\loopPlayer, {
  |out = 0, buf, amp = 0.5, gate = 1, fadeTime = 0.1, loopLen = 0.25, rate = 1|
  var sig, env;

  loopLen = loopLen + rrand(-0.1,0.1);
  sig = PlayBuf.ar(
    numChannels: 1,
    bufnum: buf,
	rate: BufRateScale.kr(buf) * rate,
    trigger: Impulse.kr(1 / loopLen),
	// startPos: 0 + Rand(0.0, BufFrames.kr(buf) / 10),
    loop: 1
  );

  env = EnvGen.kr(
    // Env([0, 1, 1, 0], [fadeTime, 1, fadeTime], \sin),
	Env.asr(fadeTime, 1, fadeTime),
    gate: gate,
    doneAction: 2
  );

	Out.ar(out, Pan2.ar(sig * env * amp * (1/4), Rand(-1.0, 1.0) ));  // Divide by 4 for -12dB headroom
}).add;
)

(
var w, slider_loopLen, slider_playRate;

w = Window("Extra Controls", Rect(100, 100, 300, 150)).front;

slider_loopLen = Slider(w, Rect(10, 40, 280, 20));
slider_loopLen.value = 0.25;  // default
slider_loopLen.action = {
    var loopLen = slider_loopLen.value.linexp(0, 1, 0.05, 2);  // Map slider to loop length
    16.do({ |i|
        var synth = ~currentSynths[i];
        if(synth.notNil) {
            synth.set(\loopLen, loopLen);
        }
    });
};

slider_playRate = Slider(w, Rect(10, 90, 280, 20));
slider_playRate.value = 1.0;
slider_playRate.action = {
	var playRate = slider_playRate.value.linlin(0, 1, 0.01, 2.0);
	16.do({ |i|
		var synth = ~currentSynths[i];
		if(synth.notNil) {
			synth.set(\rate, playRate);
		}
	});
};

StaticText(w, Rect(10, 10, 280, 20))
    .string_("Loop Length")
    .align_(\center);

StaticText(w, Rect(10, 60, 280, 20))
    .string_("Play Rate")
    .align_(\center);
)


(
16.do({ |channel|
  var ccNum = channel + 32;

  MIDIdef.cc(("cc_" ++ channel).asSymbol, { |val|
    var buffer = ~samples[channel][val];
    var currentSynth = ~currentSynths[channel];

    if(buffer.notNil, {
      // Release current synth with fadeout
      if(currentSynth.notNil, {
        // currentSynth.set(\gate, 0);
		currentSynth.free;
      });
	  ~currentSynths[channel] = Synth(\loopPlayer, [
		\buf, buffer,
		\amp, 0.5,  // adjust as needed
		\fadeTime, 0.05,  // 100ms crossfade
		\loopLen, 0.5,
		\gate, 1
		// \loopLen, buffer.duration
	  ]);
    });
  }, ccNum);
});
)

(
MIDIClient.init;
MIDIIn.connectAll;
)

MIDIdef.cc(\test1, {~currentSynths.postln}, 32);

~loadSamples.("C:/Users/Li/Documents/Ableton/samples/RENEGADE ANDROiD's 90's BREAK COLLECTION/drum & Bass");

Buffer.freeAll;