# macOS Build Instructions

This zip contains the minimal files needed to build the macOS app/package.

## Requirements

- macOS
- Python 3.10+
- Xcode Command Line Tools

Install command line tools if needed:

```bash
xcode-select --install
```

## Build

Open Terminal in this folder, then run:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
bash build_mac.sh
```

After the build finishes, outputs will be in:

```text
dist/
```

Expected outputs:

- `dist/故事板生成器`
- `dist/StoryboardGenerator-1.0.0.pkg`

If macOS blocks the app because it is unsigned, use right-click > Open, or sign/notarize it with your Apple Developer certificate.
