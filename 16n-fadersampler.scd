(
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
  |out = 0, buf, amp = 0.5, fadeTime = 0.1, loopLen = 0.25|
  var sig, env;
  
  sig = PlayBuf.ar(
    numChannels: 2,
    bufnum: buf,
    rate: BufRateScale.kr(buf),
    trigger: Impulse.kr(1/loopLen),
    loop: 1
  );

  env = EnvGen.kr(
    Env([0, 1, 1, 0], [fadeTime, 1, fadeTime], \sin),
    gate: 1,
    doneAction: 2
  );
 
  Out.ar(out, sig * env * amp * (1/4));  // Divide by 4 for -12dB headroom
}).add;
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
        currentSynth.set(\gate, 0);
      });

      ~currentSynths[channel] = Synth(\loopPlayer, [
        \buf, buffer,
        \amp, 0.5,  // adjust as needed
        \fadeTime, 0.1,  // 100ms crossfade
        // \loopLen, 0.25,
        \loopLen, buffer.duration
      ]);
    });
  }, ccNum);
});
)

MIDIClient.init;
MIDIIn.connectAll;

// Example usage:
// ~loadSamples.("/path/to/samples");
