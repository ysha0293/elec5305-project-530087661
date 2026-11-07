FORMAL BACKGROUND-NOISE EXPERIMENT

Place one or more UNRELATED external environmental-noise audio recordings
(WAV/FLAC/MP3/M4A) in this folder before running the final robustness study.

Do NOT copy UrbanSound8K evaluation clips into this folder. Keeping the noise
source external avoids confounding the benchmark dataset with the perturbation
source.

For full reproducibility, record the source/license of every noise file in your
report. The experiment manifest records file names and SHA-256 checksums.

The code deterministically selects both the noise file and the segment for each
UrbanSound8K clip and then scales that segment to exactly 20, 10 or 0 dB SNR.
