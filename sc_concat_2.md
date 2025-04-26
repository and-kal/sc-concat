I asked ChatGPT for a way of building a pipeline of the functions I call in `sc_concat_2.md`, and it suggested using a `Routine`:

```supercollider
(
~pipeline = Routine({
    var buffers, grainsList, clusters, outputBuf;

    // 1. Load Buffers
    buffers = ~sourcePaths.collect { |path|
        Buffer.read(s, path).yield;  // 👈 wait for each Buffer to load
    };
    ~sourceBuffers = buffers;

    // 2. Analyze all buffers
    grainsList = buffers.collect { |buf|
        var defer = { |done| ~analyzeBuffer.(buf, 0.1, done) };
        defer.yield;  // 👈 wait for analyze to finish
    };
    ~sourceGrains = grainsList;

    // 3. Cluster all grains
    clusters = grainsList.collect { |grains|
        var defer = { |done| ~clusterGrains.(grains, done) };
        defer.yield;
    };
    ~clusteredGrains = clusters;

    // 4. Concatenative synthesis
    outputBuf = { |done| ~concatenativeSynth.(~inputBuffer, clusters.flat, done) }.yield;
    ~outputBuffer = outputBuf;

    "✅ All Done!".postln;
});
)
```
