# sc-concat

This is a concatenative multi-sampler written in [SuperCollider](https://docs.supercollider.online/). You can load in sampels (and folders of samples); it then uses the Fluid Corpus Manipulation ([FluCoMa](https://github.com/flucoma/flucoma-sc)) machine learning library in order to organize similar slices of these samples into clusters based on spectral features. It receives MIDI note messages, which will play a random sample from one of the clusters.

# sc-concat_2

This is an attempt to rebuild something like DataMind Audio's Concatenator VST in SuperCollider with the help of Anthropic's Claude 3.5 Sonnet (new).

Prompt:

> I want to build something like DataMind Audio's Concatenator VST (https://datamindaudio.ai/shop) in SuperCollider, It's a software that uses concatenative sound synthesis algorithms in order to "instantly transform your collection of recordings and samples into a playable instrument". So you load a bunch of samples into a buffer. These samples get granularized into grains of samples and clustered based on their pitch, amplitude and timbre using machine learning (this part could be done using the FluCoMa (https://github.com/flucoma/flucoma-sc) library). I can then input sounds and the SuperCollider patch will reconstruct this sounds by intelligently concatenating sample grains that are similar to the input signal's pitch, amplitude, and timbre. For now, I don't need a real-time input processing routine. It's okay, if this implementation only returns an audio file that is like the input audio file, but composed out of the concatenated grains. It doesn't need to run here in the browser, just show me what the SuperCollider code for something like this would look like.

# 16n-fadersampler

This is a sample player that loads a bunch of samples and plays 16 of them at the same time, in a loop of a specified length. The sample per channel can be changed with a [16n faderbank](https://github.com/16n-faderbank) (or other devices using MIDI CC channels 32-47). Again I used Anthropic's Claude 3.5 Sonnet for the initial implementation.

# audio_query_with_scaler

This is a patch by [tedmoore](https://discourse.flucoma.org/u/tedmoore), which is in in a similar and which I want to keep here for reference.
