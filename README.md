# CepterEFX-helpers

Helper engines and models that the [Cepter EFX](https://intercepth.dev/CepterEFX) After Effects panel
downloads on first use. The panel itself is not distributed here.

| Folder / release | What | Licence |
|---|---|---|
| `ffmpeg/` | Build script + CI for a small static Windows `ffmpeg.exe` | GPL-3.0+ (x264) |
| Release `models-v1` | Voice Isolation GPU models (`cepter_htdemucs_dml.onnx`, `cepter_htdemucs_6s_dml.onnx`) | see model notes |

Releases are immutable: a changed file gets a new tag, never an edit to an old one.

Everything is built on GitHub Actions from the scripts in this repo, so the build is reproducible
and the source offer for GPL components is satisfied by the sources attached to each release.
