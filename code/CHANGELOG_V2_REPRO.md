# v2 reproducibility / extensibility changes

The scientific clean benchmark is unchanged. The following infrastructure was added:

1. Deterministic global seed in `main.m`.
2. Automatic YAMNet detection and one-time official MathWorks download.
3. Project-local `models/yamnet/` path.
4. Reproducibility manifest with MATLAB/toolbox/config information.
5. `ClipID` and file path stored in feature caches.
6. `ClipID` and correctness stored in held-out prediction CSV files.
7. Legacy v2 feature caches can be upgraded instead of recomputed.
8. Feature extractors support `alreadyPreprocessed=true` for future controlled perturbation experiments.
9. Noise generation uses a local deterministic random stream.
10. `make_condition_seed` supports different but reproducible per-clip perturbations.
11. `run_robustness_10fold_svm` enforces clean-train / perturbed-test evaluation.
12. `compute_representation_shift_table` provides clip-level clean-to-perturbed distances.
13. Logical future output folders are created for robustness and representation analysis.
