# ELEC5305 Project — MFCCs versus Pretrained Audio Embeddings

**Student:** Yunzhe Shao (SID: 530087661)
**Topic:** Robustness of Environmental Sound Classification

## Research Questions

**RQ1.** How robust are conventional MFCC features and pretrained deep audio embeddings to realistic acoustic and recording-channel perturbations in environmental sound classification?

**RQ2.** Can changes in the audio representation predict when classification performance will fail?

The project compares two controlled representation pipelines using the same simple downstream classifier:

- **MFCC statistics + linear ECOC SVM**
- **Frozen pretrained YAMNet embeddings + linear ECOC SVM**

The goal is not only to compare clean benchmark accuracy, but to measure how classification and representation stability change under noise, reverberation and channel distortion.

---

## Dataset and official evaluation protocol

The project uses **UrbanSound8K** (8732 clips, 10 classes, 10 predefined official folds).

The official folds are always preserved. No new random train/test split is created. For each fold:

```text
9 official folds -> CLEAN training data
1 official fold  -> held-out test data
```

For robustness experiments the held-out test waveform is perturbed, while the nine training folds stay clean:

```text
CLEAN training folds -> fixed SVM
PERTURBED held-out fold -> test only
```

Normalization parameters (`mu`, `sigma`) are estimated from the clean training folds only. The held-out fold never participates in model fitting or normalization fitting.

---

## Clean benchmark

| Method | Mean Accuracy | Mean Macro-F1 |
|---|---:|---:|
| MFCC + SVM | **63.43 ± 4.82%** | **0.642 ± 0.047** |
| YAMNet + SVM | **78.37 ± 3.19%** | **0.792 ± 0.037** |

The clean benchmark reports accuracy, Macro-F1, per-class recall, confusion matrices and mean ± standard deviation across the official ten folds.

---

## Final robustness experiments

The formal experiment uses three perturbation families and three fixed severity levels.

### 1. External environmental noise

Unrelated external environmental-noise recordings are added to the held-out test clips at:

- **20 dB SNR**
- **10 dB SNR**
- **0 dB SNR**

The exact noise file and segment used for each clip are selected deterministically from a fixed seed. The same perturbed waveform is used for both MFCC and YAMNet.

### 2. Reverberation

A fixed deterministic room impulse response is generated for each planned severity:

- **mild:** RT60 ≈ 0.20 s
- **moderate:** RT60 ≈ 0.50 s
- **strong:** RT60 ≈ 0.80 s

The same RIR for a given severity is reused across representations and reruns.

### 3. Channel / frequency-response distortion

Controlled zero-phase band-limiting is used:

- **mild:** 100–7000 Hz
- **moderate:** 200–5000 Hz
- **strong:** 300–3400 Hz

All parameters are defined in `code/config.m` before evaluation.

---

## Controlled comparison and leakage prevention

The implementation enforces the following rules:

- official UrbanSound8K folds only;
- clean training data only;
- perturbations applied only to the held-out test recordings;
- no perturbed sample is used to fit the SVM;
- training-only feature normalization;
- YAMNet is frozen and used only as a feature extractor;
- the same perturbed waveform is used for MFCC and YAMNet;
- clean and perturbed rows are matched by `ClipID`;
- no test-set hyperparameter tuning is performed;
- clean fold models are trained once and cached, then reused by all perturbation conditions;
- deterministic per-clip/per-condition seeds are used;
- external noise filenames and SHA-256 hashes are recorded in the reproducibility manifest.

---

## Representation-shift analysis

For every clean clip and corresponding perturbed clip, the representation distance is measured.

- **MFCC:** Euclidean distance between 130-D summary vectors
- **YAMNet:** cosine distance between 2048-D embedding summaries

Distances are interpreted **within each representation**; MFCC and YAMNet raw distance magnitudes are not directly compared because the metrics/scales differ.

For each condition, the project compares:

```text
mean representation shift
        versus
Macro-F1 drop from the clean reference
```

Pearson and Spearman correlations are reported separately for MFCC and YAMNet.

Class-level representation shift is also joined with class-level recall drop.

---

## Class-level and confusion analysis

The project reports per-class recall degradation under each perturbation. For the strongest severity in each family, the code also identifies the off-diagonal confusion whose count increased most relative to clean evaluation.

For selected clean-correct / perturbed-incorrect examples, the code generates a diagnostic figure containing:

- waveform;
- spectrum;
- spectrogram;
- MFCC representation;

for both clean and perturbed versions of the same clip.

---

## Repository structure

```text
code/
├── main.m
├── config.m
├── test_setup.m
├── dataset/
├── features/
├── evaluation/
├── experiments/
├── perturbations/
├── analysis/
├── plots/
└── utils/

assets/
└── noise/
    └── README.txt

results/
├── tables/
├── figures/
├── cache/
├── robustness/
├── representation/
└── reproducibility/
```

---

## Setup and reproduction

### 1. Download UrbanSound8K

Download and extract UrbanSound8K, then place the `UrbanSound8K` folder either **inside the repository** or **one directory above it**.

Recommended structure:

```text
elec5305-project-530087661/
├── code/
├── assets/
├── results/
├── UrbanSound8K/
│   ├── audio/
│   │   ├── fold1/
│   │   ├── ...
│   │   └── fold10/
│   └── metadata/
│       └── UrbanSound8K.csv
└── README.md
```

The code also supports the user's current local structure:

```text
project/
├── UrbanSound8K/
└── elec5305-project-530087661/
```

### 2. Add the external environmental-noise bank

Before the formal noise robustness experiment, place one or more **unrelated external environmental-noise recordings** in:

```text
assets/noise/
```

Supported formats are WAV, FLAC, MP3 and M4A. Do not use UrbanSound8K evaluation clips as the noise bank. Record the source/license of the noise recordings in the final report.

### 3. MATLAB requirements

- Audio Toolbox
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox
- Deep Learning Toolbox
- pretrained YAMNet support

The project automatically checks/loads YAMNet using the MATLAB installation or the project-local model helper.

### 4. Run the setup check first

From MATLAB:

```matlab
cd code
test_setup
```

This checks the dataset, official folds, required functions, YAMNet, the external noise bank and deterministic perturbation generation.

### 5. Run the complete experiment

```matlab
main
```

If the clean benchmark already exists, it is reused. On a fresh project copy, the clean benchmark is generated first.

The first robustness run trains and caches the ten clean-fold SVM models for MFCC and YAMNet. Noise, reverb and channel experiments then reuse those exact clean models; they do not retrain on perturbed data.

---

## Output structure

The final version deliberately separates **report results** from **working caches**.
Large per-clip feature matrices are not report deliverables and are therefore kept under `work/`, which is ignored by Git. After a fully successful run and integrity audit, large perturbed-feature caches are removed automatically.

Small condition-level metrics remain separated for clear analysis:

```text
results/robustness/
├── noise/
│   ├── 20db/
│   ├── 10db/
│   └── 0db/
├── reverb/
│   ├── mild/
│   ├── moderate/
│   └── strong/
└── channel/
    ├── mild/
    ├── moderate/
    └── strong/
```

Each condition stores only compact fold metrics, summary statistics and per-class metrics for MFCC and YAMNet. Clip-level predictions and full perturbed feature matrices are used in memory for auditing/analysis but are not written to the final `results/` directory by default.

Core report tables are:

```text
results/tables/clean_summary.csv
results/tables/clean_fold_comparison.csv
results/tables/clean_per_class_recall_comparison.csv
results/tables/mfcc_aggregate_confusion.csv
results/tables/yamnet_aggregate_confusion.csv
results/tables/robustness_summary.csv
results/tables/robustness_fold_metrics.csv
results/tables/class_robustness.csv
results/tables/confusion_change_summary.csv
results/representation/condition_summary.csv
results/representation/correlation.csv
results/representation/class_shift_vs_recall_drop.csv
```

Core report figures are:

```text
results/figures/clean_accuracy_mean_std.png
results/figures/clean_macro_f1_mean_std.png
results/figures/clean_accuracy_fold_comparison.png
results/figures/clean_macro_f1_fold_comparison.png
results/figures/clean_per_class_recall_comparison.png
results/figures/mfcc_aggregate_confusion.png
results/figures/yamnet_aggregate_confusion.png
results/figures/robustness_noise_macro_f1.png
results/figures/robustness_reverb_macro_f1.png
results/figures/robustness_channel_macro_f1.png
results/figures/class_recall_drop_noise_strong.png
results/figures/class_recall_drop_reverb_strong.png
results/figures/class_recall_drop_channel_strong.png
results/figures/representation_shift_vs_f1_drop_mfcc.png
results/figures/representation_shift_vs_f1_drop_yamnet.png
results/figures/confusion_*_strong_*.png
results/figures/signal_example_*.png
```

The working directory is:

```text
work/
├── cache/
└── robustness_temp/
```

`work/` is not intended for submission. It exists only to support restartable and reproducible computation.

---

## Reproducibility record

`results/reproducibility/experiment_manifest.txt` records:

- MATLAB release and platform;
- random seed and RNG algorithm;
- MFCC parameters;
- SVM parameters;
- YAMNet configuration;
- noise SNR levels;
- noise-file SHA-256 hashes;
- reverb RT60 settings;
- channel bandwidth settings;
- dataset metadata path;
- cache versions and experiment-control flags.

---

## References and resources

1. J. Salamon, C. Jacoby, and J. P. Bello, *A Dataset and Taxonomy for Urban Sound Research*, ACM Multimedia, 2014.
2. UrbanSound8K dataset: https://zenodo.org/records/1203745
3. K. J. Piczak, *Environmental Sound Classification with Convolutional Neural Networks*, MLSP, 2015.
4. J. F. Gemmeke et al., *Audio Set: An Ontology and Human-Labeled Dataset for Audio Events*, ICASSP, 2017.
5. S. Srivastava et al., *A Study on Robustness to Perturbations for Representations of Environmental Sound*, EUSIPCO, 2022.
6. MATLAB Audio Toolbox pretrained models: https://www.mathworks.com/help/audio/pretrained-models.html
7. MATLAB transfer learning with pretrained audio networks: https://www.mathworks.com/help/audio/ug/transfer-learning-with-pretrained-audio-networks.html
