s.options.memSize = 8192 * 64;
s.boot;

~samples = Array.fill(16, { Array.newClear(128) }); // 16 channels, 128 values each
~currentSynths = Array.newClear(16);
~sampleBuffers = Dictionary.new;
~pitchAnalysis = Dictionary.new;

(
~analyzeSamplePitch = { |buffer|
  var pitchTracker, pitchResult = 0;

  // Use FluidPitch for fundamental frequency detection
  FluidPitch.kr(
    buffer.play,  // Play the buffer
    maxFreq: 2000,  // Limit max frequency for stability
    minFreq: 20,   // Minimum frequency threshold
    action: { |pitch, clarity|
      // Use pitch with high clarity
      if (clarity > 0.9, {
        pitchResult = pitch;
      }, {
        // Fallback to RMS-based estimation if pitch clarity is low
        pitchResult = buffer.duration.asFloat.reciprocal * 100;
      });
    }
  );

  pitchResult;
};
)

(
~loadSamples = { |folderPath|
  var files, pitchMap, sortedPitches, channelCount;

  ~sampleBuffers.clear;
  ~pitchAnalysis.clear;
  ~samples = Array.fill(16, { Array.newClear(128) });

  files = PathName(folderPath).files.select({ |f|
    f.extension.toLower == "wav"
  });

  files.do({ |file, i|
    var buffer = Buffer.read(s, file.fullPath);
    ~sampleBuffers[i] = buffer;
    // Synchronous pitch analysis (simplified for this example)
    ~pitchAnalysis[i] = ~analyzeSamplePitch.(buffer);
  });

  pitchMap = ~pitchAnalysis.values.sort;
  channelCount = min(files.size, 16);

  files.do({ |file, i|
    var pitch = ~pitchAnalysis[i];
    var channelIndex, ccStart, ccEnd;

    channelIndex = (pitch.linlin(
      pitchMap.first,
      pitchMap.last,
      0,
      channelCount - 1
    )).asInteger;

    ccStart = (i * 128 / channelCount).asInteger;
    ccEnd = ((i + 1) * 128 / channelCount).asInteger;

    ccStart..(ccEnd-1).do({ |cc|
      ~samples[channelIndex][cc] = ~sampleBuffers[i];
    });
  });
};
)

(
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
)

(
16.do({ |channel|
  var ccNum = channel + 32;

  MIDIdef.cc(("cc_" ++ channel).asSymbol, { |val|
    var buffer = ~samples[channel][val];
    var currentSynth = ~currentSynths[channel];

    // Fallback mechanism if no samples in this channel
    if(~samples[channel].any({ |buf| buf.notNil }), {
      buffer = ~samples[channel][val];
      currentSynth = ~currentSynths[channel];

      if(buffer.notNil, {
        // Release current synth with fadeout
        if(currentSynth.notNil, {
          currentSynth.set(\gate, 0);
        });
        ~currentSynths[channel] = Synth(\loopPlayer, [
          \buf, buffer,
          \amp, 0.5,
          \fadeTime, 0.1,
          \loopLen, 0.25
        ]);
      });
    });
  }, ccNum);
});
)

~printSampleDistribution = {
  "Sample Distribution:".postln;
  16.do({ |channel|
    var samplesInChannel = ~samples[channel].select({ |buf| buf.notNil });
    ("Channel " ++ channel ++ ": " ++ samplesInChannel.size ++ " samples").postln;
  });
};

MIDIClient.init;
MIDIIn.connectAll;

// Example usage:
// ~loadSamples.("/path/to/samples");
// ~printSampleDistribution.();
