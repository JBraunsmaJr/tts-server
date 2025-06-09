// src/server.ts
import express, { Request, Response } from 'express';
import * as path from 'path';
import { createWavWithPiper, PiperOptions } from './piper';

const app = express();
const PORT = 3000;

app.use(express.json());

const OUTPUT_DIR = '/app/output';

app.post('/synthesize', async (req: Request, res: Response) => {
    // We now look for 'model' instead of 'voice'
    const { text, model } = req.body;

    if (!text) {
        res.status(400).json({ error: 'Text is required.' });
        return;
    }

    const filename = `${Date.now()}_synthesis.wav`;
    const outputFilePath = path.join(OUTPUT_DIR, filename);

    const options: PiperOptions = {
        text,
        outputFile: outputFilePath,
        model,
    };

    try {
        await createWavWithPiper(options);
        res.status(201).json({
            success: true,
            message: 'WAV file created successfully.',
            filePath: `/output/${filename}`
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to generate WAV file.',
        });
    }
});

app.listen(PORT, () => {
    console.log(`TTS server with Piper is running on http://localhost:${PORT}`);
    console.log(`Mounted output directory is at: ${OUTPUT_DIR}`);
});