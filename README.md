# TTS Server

Just a simple service to test text-to-speech.

```bash
# To build locally
docker compose build

# To bring things online
docker compose up -d
```

Tried curl and got frustrated with Windows. So I made a python script to make it easier to write text and make it easier to read.

```python
import requests
text = "This is a sample. Just testing things."
data = {
   "text": text,
   "lengthScale": 0.9,
   "noiseScale": 0.6,
   "noiseW": 0.84
}

requests.post(
  url="http://localhost:3000/synthesize",
  json=options
)
```
