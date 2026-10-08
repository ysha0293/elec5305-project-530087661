# ELEC5305 Project Code — v2 Reproducible Extension

## Purpose

This codebase supports:

**MFCCs versus Pretrained Audio Embeddings: Robustness of Environmental Sound Classification**

The current implementation keeps the original v2 clean benchmark unchanged in scientific design, while adding reproducibility and future-robustness infrastructure.

## What is implemented now

- UrbanSound8K dataset inspection
- Official UrbanSound8K 10-fold evaluation
- MFCC + linear SVM clean baseline
- Frozen pretrained YAMNet embeddings + linear SVM clean baseline
- Accuracy, Macro-F1, per-class Recall/F1, confusion matrices, mean ± SD
- Clip-level held-out predictions with `ClipID`
- Deterministic experiment seed
- Reproducibility manifest
- YAMNet automatic detection and one-time download when absent
- Feature caches with clip identity and configuration metadata

## Portable directory structure

```text
project/
├── code/
│   ├── main.m
│   ├── config.m
│   ├── test_setup.m
│   ├── dataset/
│   ├── features/
│   ├── evaluation/
│   ├── experiments/
│   ├── plots/
│   ├── perturbations/
│   ├── analysis/
│   └── utils/
│
├── UrbanSound8K/
│   ├── audio/
│   │   ├── fold1/
│   │   ├── ...
│   │   └── fold10/
│   └── metadata/
│       └── UrbanSound8K.csv
│
├── models/               # created automatically; do not commit model weights
│   └── yamnet/
│
└── results/              # created automatically
    ├── cache/
    ├── figures/
    ├── tables/
    ├── reproducibility/
    ├── robustness/
    └── representation/
```

No absolute `/Users/...` or Windows drive path is stored in the code.

## Run order

1. Run `test_setup.m`.
2. Run `main.m`.

`test_setup.m` checks the dataset, required MATLAB functions and YAMNet. If YAMNet is not available, the project downloads the official MathWorks pretrained model once into `models/yamnet/` and reuses it on later runs.

## Reproducibility

The project fixes the global seed in `config.m` and writes:

```text
results/reproducibility/experiment_manifest.mat
results/reproducibility/experiment_manifest.txt
```

The manifest records MATLAB release, platform, toolbox versions, seed, MFCC settings, SVM settings, YAMNet source URL and cache version.

Legacy v2 feature caches are upgraded with `ClipID` and metadata when possible, so clean features do not need to be recomputed unnecessarily.

## Current clean outputs

### MFCC + SVM
- official 10-fold evaluation
- Accuracy for every fold
- Macro-F1 for every fold
- mean Accuracy ± SD
- mean Macro-F1 ± SD
- per-class Recall ± SD
- per-class F1 ± SD
- per-fold confusion matrices
- aggregate out-of-fold confusion matrix
- held-out predictions with clip identity

### Frozen YAMNet + SVM
The same evaluation outputs as the MFCC system.

### MFCC vs YAMNet comparison
- clean summary table
- fold-by-fold table
- Accuracy mean ± SD figure
- Macro-F1 mean ± SD figure
- fold-level comparison figures
- per-class recall comparison

## Future robustness protocol

The future experiment infrastructure encodes the required controlled design:

```text
clean training folds
        ↓
train SVM and fit normalization on clean training data only
        ↓
perturbed held-out test fold
        ↓
MFCC / YAMNet evaluation
```

The same perturbed waveform must be generated once and then passed to both MFCC and YAMNet. To preserve the perturbation exactly, the feature extractors now support an `alreadyPreprocessed=true` mode so the perturbed waveform is not peak-normalized again.

`evaluation/run_robustness_10fold_svm.m` is provided as the future controlled evaluator.

`analysis/compute_representation_shift_table.m` is provided for clip-level clean-to-perturbed representation distances.

## Future experiment sequence

1. Controlled background noise: 20, 10 and 0 dB SNR
2. Reverberation: controlled mild / moderate / strong conditions
3. Channel/frequency-response distortion: controlled severity levels
4. Robustness curves: Macro-F1 versus perturbation severity
5. Class-level Recall degradation
6. Clean-to-perturbed representation distance
7. Representation shift versus classification-performance degradation
8. Correlation analysis

## Important Git note

Keep `models/` and generated caches/results out of Git unless specifically required. The source code can reproduce/download them.
