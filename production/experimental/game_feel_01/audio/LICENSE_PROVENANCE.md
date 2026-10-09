# Original audio provenance and project-use grant

These 18 exported audio works, their PCM24 source renders, score and synthesis recipe were created specifically for Mutsumi Veilshift by the Owner 11 audio production process. They are procedural original compositions and sound designs, not recordings of existing music. The generation process uses mathematical oscillators, deterministic generated noise, envelopes and echo. No game, animation, commercial music, sample library, field recording, voice or external audio file was used.

The project owner is granted unrestricted use, modification, reproduction and distribution of these supplied assets and recipe within Mutsumi Veilshift, its builds, trailers and related project material. No third-party sampled-audio attribution or sample-library license is required. This project-use grant does not designate an open public sample-library license; the project owner may choose that separately.

Sources: `source/score.json` contains the original melodic notes, chord progression, timing and instrument direction. `source/synthesize.py` is the complete deterministic render recipe (seed 11012026), using Python standard library and NumPy 2.3.5. The runtime package's existing Python/NumPy software licenses remain with those software dependencies; neither dependency contributes sampled audio. The generator reads only the local score and writes only this audio namespace.

Exports: 44,100 Hz PCM16 WAV. Retained source renders: 44,100 Hz PCM24 WAV. SHA-256 values for each export and source are in `manifest.json`. No external asset downloads and no dependency installation were performed.

OGG status: NOT_PRODUCED. No available ffmpeg, soundfile/libsndfile or Vorbis encoder was found in the provided runtime. WAV is the actual delivered format, supported by Godot's AudioStreamWAV. Godot should use the explicit forward-loop frame metadata supplied in the manifest; an OGG conversion is a future production optimization, not a completed deliverable.

Human auditory listening: NOT_RUN. Numerical PCM checks are not hearing, music appreciation or Human QA. This delivery does not claim subjective listening approval, final mastering or gameplay integration PASS.
