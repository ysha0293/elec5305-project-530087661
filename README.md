# Elec5305-project-530087661
Student: Yunzhe Shao (SID: 530087661)

**GitHub Repository:** [View Repository](https://github.com/ysha0293/elec5305-project-530087661)

**GitHub Pages:** [View Project Website](https://ysha0293.github.io/elec5305-project-530087661/)

## MFCCs versus Pretrained Audio Embeddings: Robustness of Environmental Sound Classification
This project studies the classification of the environmental sound classification based on the Urbansound8K dataset

This project initially focuses on comparing different audio features and machine learning methods by classification accuracy.

Based on the project feedback one, The main research focus of the current project has been adjusted to:

Study the robustness of different audio representation methods when the acoustic environment or recording conditions change.

The current project mainly compares:
- traditional MFCC features
- pretrained YAMNet audio embedding

These two representation methods are evaluated using a simple SVM classifier.

The goal of this project only only compares the classification performance under the condition of clean data, and further studies how do noise, reverb and channel effects affect audio representation and final classification performance.

---
## Research question

### main research probelm:
**How robust are conventional MFCC features and pretrained deep audio embeddings to realistic acoustic and recording-channel perturbations in environmental sound classification?**
### secondary question:
**Can changes in the audio representation predict when classification performance will fail?**


## Dataset

This project uses the UrbanSound8K dataset.

UrbanSound8K includes:

- 8732 labeled audio segments;
- 10 environmental sound categories;
Each audio segment is approximately 4 seconds long.
- 10 pre-defined official folds.

The 10 categories are respectively:

1. Air Conditioner
2. Car Horn
3. Children Playing
4. Dog Bark
5. Drilling
6. Engine Idling
7. Gun Shot
8. Jackhammer
9. Siren
10. Street Music

The UrbanSound8K dataset can be downloaded from Zenodo:

[Download UrbanSound8K Dataset](https://zenodo.org/records/1203745)

The expected directory structure of the dataset is as follows:
```text
UrbanSound8K/
├── audio/
│ ├── fold1/
│ ├── fold2/
│ ├──...
│ └── fold10/
│
└── metadata/
    └── UrbanSound8K.csv
```
The original audio file of UrbanSound8K will not be uploaded to this GitHub.

---
## The connection with ELEC 5305

  ## Methods

  This project will explore the different audio feature extraction and machine learning methods and category the environmental sounds in the UrbanSound8k.

  The main process includes that:
  1. audio data pre-processing
  2. audio feature extraction
  3. Training of environmental sound classification models
  4. Performance evaluation is conducted using test data
  5. Compare the classfication performance of different methods
## Evaluation metrics

- Classification Accuracy
- F1-score
- Confusion Matrix

## Project Documents

[Project Proposal (PDF)](ELEC5305_Project_Proposal(Yunzhe%20Shao-530087661).pdf)
