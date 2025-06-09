// src/piper.ts
import { exec } from 'child_process';
import { promisify } from 'util';
import * as path from 'path';

const execPromise = promisify(exec);

const PIPER_EXE = '/usr/local/bin/piper';
const MODELS_DIR = '/app/models';

export interface PiperOptions {
    text: string;
    outputFile: string;

    /**
     * Default is 1.0
     * Controls speed. If you make the scale 1.2, the speech will be 20% slower
     */
    lengthScale?: number

    /**
     * Controls the variability in the voice from one run
     * to the next. It is the stochastic part of the model.
     * Higher values can add more intonation and "character" but can also sound
     * less stable
     * default is 0.667
     */
    noiseScale?: number

    /**
     * Phoneme level noise
     * Controls noise/variation applied to the duration of each phoneme (sounds like "a", "t", "sh")
     * Fine-tuning parameter for the rhythm and speed of the speech
     * Default is 0.8
     */
    noiseW?: number


    model: string;
}

export async function createWavWithPiper(options: PiperOptions): Promise<void> {
    const { text, outputFile, noiseW=0.8, noiseScale=0.667, lengthScale=1, model="en_GB-northern_english_male-medium.onnx" } = options;
    const modelPath = path.join(MODELS_DIR, model);

    // The command pipes the text to the piper executable.
    // Ensure the text is properly escaped for the command line.
    const escapedText = text.replace(/"/g, '\\"');

    const extraArgs = [
        `--length_scale=${lengthScale}`,
        `--noise_scale=${noiseScale}`,
        `--noise_w=${noiseW}`
    ]

    const command = `echo "${escapedText}" | ${PIPER_EXE} --model ${modelPath} --output_file ${outputFile} ${extraArgs.join(' ')}`;

    console.log(`Executing: ${command}`);

    try {
        const { stderr } = await execPromise(command);
        if (stderr) {
            // Piper often logs status to stderr, so we only log it for debugging.
            console.debug(`Piper STDERR: ${stderr}`);
        }
        console.log(`Successfully created WAV file at: ${outputFile}`);
    } catch (error) {
        console.error('Failed to execute Piper command.', error);
        throw new Error('TTS generation failed.');
    }
}