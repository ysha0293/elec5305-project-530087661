# Experiments

## Implemented

`run_clean_benchmark.m`

Runs the official UrbanSound8K 10-fold clean benchmark for:

- MFCC + linear SVM
- frozen YAMNet embeddings + linear SVM

## Future robustness experiments

Future experiment runners should be added here without changing the clean benchmark.

Every robustness experiment must follow this protocol:

1. Read one raw UrbanSound8K clip.
2. Apply the common clean preprocessing once.
3. Generate one controlled perturbed waveform.
4. Extract MFCC and YAMNet from that exact same perturbed waveform using `alreadyPreprocessed=true`.
5. Build a row-aligned perturbed representation matrix.
6. Evaluate using `run_robustness_10fold_svm` so training remains clean and only the held-out test fold is perturbed.
7. Save clip-level representation distances using `compute_representation_shift_table`.

Recommended order:

- noise first (20 / 10 / 0 dB SNR)
- reverberation
- channel filtering
- representation-shift / performance correlation
