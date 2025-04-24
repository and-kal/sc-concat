// Server config
s.options.memSize = 8192 * 64;
s.boot;

// Global state
~samples = Array.fill(16, { Array.newClear(128) }); // 16 channels, 128 values each
~currentSynths = Array.newClear(16);
~sampleBuffers = Dictionary.new;

// Load samples into buffers and assign them to CC values
~loadSamples = { |folderPath|
  var files = PathName(folderPath).files.select({ |f| 
    f.extension.toLower == "wav" 
  });
  
  files.do({ |file, i|
    ~sampleBuffers[i] = Buffer.read(s, file.fullPath);
  });
  
  // Assign samples to CC values (you might want to customize this)
  16.do({ |channel|
    128.do({ |cc|
      var sampleIndex = (cc * files.size / 128).floor;
      ~samples[channel][cc] = ~sampleBuffers[sampleIndex];
    });
  });
};

// Synth definition for sample playback with crossfade
SynthDef(\loopPlayer, { 
  |out = 0, buf, amp = 0.5, fadeTime = 0.1, loopLen = 0.25|
  var sig, env;
  
  // Looped playback
  sig = PlayBuf.ar(
    numChannels: 2,
    bufnum: buf,
    rate: BufRateScale.kr(buf),
    trigger: Impulse.kr(1/loopLen),
    loop: 1
  );
  
  // Amplitude envelope for smooth transitions
  env = EnvGen.kr(
    Env([0, 1, 1, 0], [fadeTime, 1, fadeTime], \sin),
    gate: 1,
    doneAction: 2
  );
  
  // Apply envelope and output with level compensation
  Out.ar(out, sig * env * amp * (1/4));  // Divide by 4 for -12dB headroom
}).add;

// MIDI CC responder
16.do({ |channel|
  var ccNum = channel + 32;  // CC numbers 32-47
  
  MIDIdef.cc(("cc_" ++ channel).asSymbol, { |val|
    var buffer = ~samples[channel][val];
    var currentSynth = ~currentSynths[channel];
    
    if(buffer.notNil, {
      // Release current synth with fadeout
      if(currentSynth.notNil, {
        currentSynth.set(\gate, 0);
      });
      
      // Create new synth
      ~currentSynths[channel] = Synth(\loopPlayer, [
        \buf, buffer,
        \amp, 0.5,  // Adjust base amplitude as needed
        \fadeTime, 0.1,  // 100ms crossfade
        \loopLen, 0.25  // Default loop length
      ]);
    });
  }, ccNum);
});

// Initialize MIDI
MIDIClient.init;
MIDIIn.connectAll;

// Example usage:
// ~loadSamples.("/path/to/samples");
