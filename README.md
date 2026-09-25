# 🎵 Real-Time Music Identification System

A Shazam-style audio pattern recognition system built entirely from scratch in MATLAB. 

This project was developed as a Complex Engineering Project (CEP) for the Signals and Systems course[cite: 2]. It is designed to identify a song from a short, live microphone recording in real-time, even in the presence of background noise[cite: 1, 2]. 

Alongside core identification, the system features a custom Graphical User Interface (GUI) with live microphone feedback and a content-based recommendation engine that suggests acoustically similar tracks[cite: 1, 5].

---

## 🚀 Key Features

* **Robust Live Matching:** Captures audio via microphone and accurately matches it against a local database using spectral peak hashing[cite: 2].
* **Noise Filtering:** Utilizes an RMS-based noise gate and a time-offset histogram voting system to filter out random background noise and coincidental hash collisions[cite: 2, 4].
* **Content-Based Recommendations:** Recommends 3 similar tracks instantly using a Euclidean distance search over extracted acoustic features (no internet genre tags needed)[cite: 2, 4].
* **Automated Database Builder:** Includes automated scripts to ingest `.wav` files, process them, extract constellation peaks, and build a massive 64-bit hash map[cite: 2, 3].
* **Sleek MATLAB GUI:** Features an interactive, dark-mode GUI with a live real-time mic-level meter and direct audio playback capabilities[cite: 5].

---

## 🧠 How It Works (The Core Algorithm)

The system relies on the **Spectral Peak-Constellation Method** to generate unique fingerprints for audio files, bypassing the limitations of simple time-domain analysis[cite: 2]. The pipeline operates in 5 stages:

### 1. Preprocessing & Downsampling
Audio is converted to mono, and the sample rate is downsampled to `8000 Hz`[cite: 2]. 
* **Why?** The most perceptually significant parts of music (vocals, primary melodies) exist well below the 4 kHz Nyquist limit[cite: 2]. Downsampling reduces computational overhead by a factor of 6 without losing identifying information[cite: 2].

### 2. Pre-Emphasis Filtering
We apply a first-order FIR filter to the audio signal to boost high-frequency transient details that are normally masked by loud, low-frequency bass[cite: 2].
$$y[n] = x[n] - 0.95x[n-1]$$

### 3. Spectrogram & Peak Extraction (Constellation Map)
The audio undergoes a Short-Time Fourier Transform (STFT) using a 1024-sample window[cite: 2]. The system then divides the spectrogram into blocks and extracts the highest local energy maximum ("landmark peaks") from each block[cite: 2, 3]. 

### 4. Hash Generation (Fingerprinting)
A single peak is not unique. To create a highly specific fingerprint, we pair an "anchor" peak with a "target" peak that occurs shortly after it[cite: 3]. We encode these pairs into a single 64-bit identifier using the following formula:
$$\text{Hash} = (f_1 \times 10^6) + (f_2 \times 10^3) + \Delta t$$
Where $f_1$ and $f_2$ are the frequency bin indices, and $\Delta t$ is the time difference in STFT frames[cite: 2, 3].

### 5. Time-Offset Voting
When a live query is recorded, it generates its own hashes[cite: 4]. The system checks the database for matching hashes and calculates the $\Delta t$ offset between the query peak and the database peak[cite: 4]. True matches will result in a massive spike at a single, consistent time offset, filtering out random background noise[cite: 4].

---

## 🔍 The Recommendation Engine

Instead of relying on metadata, the system computes two lightweight features for every song during the database build phase[cite: 4]:
1. **Spectral Centroid:** Measures the "brightness" or center of mass of the audio spectrum[cite: 2, 4].
2. **Zero-Crossing Rate (ZCR):** Measures the noisiness/percussiveness of the track[cite: 2, 4].

When a song is matched, the system calculates the Euclidean distance between the matched song's features and all other songs in the database, instantly returning the top 3 nearest neighbors[cite: 2, 4].

---

## 🛠️ Engineering Trade-Offs & Decisions

* **WAV over MP3:** We explicitly use uncompressed `.wav` files for our database[cite: 2]. MP3 compression utilizes psychoacoustic modeling to discard frequencies the human ear ignores; unfortunately, our algorithm relies on those exact micro-frequencies to generate accurate hash pairs.
* **Accuracy vs. Query-by-Humming:** This system does not support humming[cite: 6]. Humming is monophonic and suffers from extreme pitch/tempo variance[cite: 6]. Supporting humming requires Dynamic Time Warping (DTW) over pitch contours, which is far too computationally heavy for a real-time MATLAB application[cite: 6]. We deliberately prioritized real-time speed and polyphonic accuracy over humming support[cite: 6].

---

## ⚙️ Getting Started

### Prerequisites
* MATLAB (R2020a or newer recommended)
* Signal Processing Toolbox
* Audio Toolbox

### Setup & Usage
1. **Clone the Repository:** 
   `git clone https://github.com/faiadsarthok/MusicDetectionApp.git`
2. **Prepare Audio:** Place your `.wav` files into the `/processed/` folder.
3. **Build the Database:** Run `build_database.m` in the MATLAB console. This will process all audio files, extract peaks, generate the hash dictionary, and save it to `/database/fingerprintDB.mat`.
4. **Run the App:** Type `MusicIDApp` in the MATLAB command window to launch the GUI. Click "Start Recording", play a song near your microphone, and watch the matching engine work!

---

## 📊 Performance

* **Controlled Accuracy:** 100% accuracy (51/51 songs correctly identified) during automated direct-audio excerpt testing[cite: 2, 6].
* **Real-World Acoustics:** The system achieves high reliability matching vocal segments within 5–10 seconds of live microphone capture[cite: 2, 6].
* **Known Limitations:** Purely instrumental segments (e.g., long acoustic intros) are harder to match. This is due to commercial mixing practices prioritizing vocal frequencies, leaving less acoustic energy density for the hashing algorithm during instrumental sections[cite: 2, 6].

---
*Developed by Faiad Sarthok, Jubayer, Fardin, and Modou as a Complex Engineering Project (Signals and Systems).*
