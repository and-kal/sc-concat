// Initialize server with higher memory for audio analysis
s.options.memSize = 8192 * 64;
s.boot;

// store clusters of slices
~clusters = Dictionary.new;
~currentCluster = 0;

// load and analyze samples
~loadAndAnalyze = { |path|
  var buffer, onsets, features, clusterer;
  
  buffer = Buffer.read(s, path);
  
  onsets = FluidBufOnsetSlice.process(
    server: s,
    source: buffer,
    threshold: 0.3,
    filterSize: 5,
    windowSize: 1024
  );
  
  // extract MFCC features for each slice
  features = FluidBufMFCC.process(
    server: s,
    source: buffer,
    numCoeffs: 13,
    numBands: 40,
    startCoeff: 1
  );
  
  // cluster the features
  clusterer = FluidKMeans(s, 
    maxIter: 100,
    numClusters: 5
  );
  
  clusterer.fit(features);
  
  // store slices in their respective clusters
  clusterer.predict(features).do { |cluster, index|
    ~clusters[cluster] = ~clusters[cluster].add((
      buffer: buffer,
      startFrame: onsets[index],
      duration: onsets[index + 1] - onsets[index]
    ));
  };
};

// MIDI responder
MIDIdef.noteOn(\sampleTrigger, { |vel, note|
  var cluster, slice;
  
  // random slice from current cluster
  cluster = ~clusters[~currentCluster];
  slice = cluster.choose;
  
  Synth(\grainPlayer, [
    \buf, slice.buffer,
    \startPos, slice.startFrame,
    \dur, slice.duration,
    \rate, note.midicps / 60.midicps // middle C as reference
  ]);
});

SynthDef(\grainPlayer, { |buf, startPos, dur, rate = 1, amp = 0.5|
  var sig = PlayBuf.ar(
    2, // assume stereo
    buf,
    rate * BufRateScale.kr(buf),
    startPos: startPos,
    loop: 0
  ) * EnvGen.kr(Env.perc(0.01, dur), doneAction: 2);
  
  Out.ar(0, sig * amp);
}).add;

~loadFolder = { |folderPath|
  PathName(folderPath).files.do { |file|
    if(file.extension.toLower == "wav", {
      ~loadAndAnalyze.(file.fullPath);
    });
  };
};

// switch active cluster
~switchCluster = { |num|
  ~currentCluster = num;
};

MIDIClient.init;
MIDIIn.connectAll;

// usage:
// ~loadFolder.("/path/to/samples");
// ~switchCluster.(0); // switch to first cluster
