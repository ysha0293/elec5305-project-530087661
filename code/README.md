# ELEC5305 Project Code

## Purpose

This codebase supports the complete project:

**MFCCs versus Pretrained Audio Embeddings: Robustness of Environmental Sound Classification**

The current implementation completes the clean preliminary stage and is organised so later robustness experiments can be added without rewriting the existing pipeline.

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
└── results/      # created automatically
```

The code contains no absolute `/Users/...` path. Move the whole project folder to another computer and keep the relative structure unchanged.

## Run order

1. Run `test_setup.m`.
2. Run `main.m`.

## Current outputs

### Dataset inspection
- total files/classes/folds
- class counts
- official fold counts
- sample-rate counts
- duration statistics
- mono/multichannel statistics
- waveform examples
- magnitude-spectrum examples
- spectrogram examples
- MFCC examples

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
- all held-out predictions

### Frozen YAMNet + SVM
The same evaluation outputs as the MFCC system.

### MFCC vs YAMNet comparison
- clean summary table
- fold-by-fold table
- Accuracy mean ± SD figure
- Macro-F1 mean ± SD figure
- fold-level comparison figures
- per-class recall comparison

## Results

All generated output is stored under:

```text
results/
├── cache/
├── figures/
└── tables/
```

## Future extensions

The directory already contains reusable modules for:
- controlled background noise
- reverberation
- channel filtering
- representation distance

Later experiments should be added under `experiments/`, while keeping feature extraction and evaluation modules unchanged.
