# sc-concat

This is a concatenative multi-sampler written in [SuperCollider](https://docs.supercollider.online/). You can load in sampels (and folders of samples); it then uses the Fluid Corpus Manipulation ([FluCoMa](https://github.com/flucoma/flucoma-sc)) machine learning library in order to organize similar slices of these samples into clusters based on spectral features. It receives MIDI note messages, which will play a random sample from one of the clusters.

## audio_query_with_scaler

This is a patch by [tedmoore](https://discourse.flucoma.org/u/tedmoore), which is in in a similar and which I want to keep here for reference.
