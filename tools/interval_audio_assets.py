"""Audit offline interval samples and extend silent SoundFont register notes.

Usage: python tools/interval_audio_assets.py --ffmpeg PATH [--repair]
Only audio assets and their CSV audit are written; no application is built.
"""
import argparse
import array
import csv
import math
from pathlib import Path
import subprocess


def decode(ffmpeg, path):
    result = subprocess.run(
        [ffmpeg, '-v', 'error', '-i', str(path), '-f', 's16le',
         '-ac', '1', '-ar', '44100', 'pipe:1'],
        check=True, capture_output=True)
    samples = array.array('h', result.stdout)
    first = samples[:44100]
    rms = math.sqrt(sum(value * value for value in first) / max(1, len(first))) / 32768
    return len(samples) / 44100, rms


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ffmpeg', required=True)
    parser.add_argument('--repair', action='store_true')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
    manifest = root / 'interval_samples_audit.csv'
    prior = {}
    if manifest.exists():
        with manifest.open(encoding='utf-8', newline='') as file:
            prior = {row['asset']: int(row['source_midi']) for row in csv.DictReader(file)}
    rows = []
    for instrument in ['piano', 'guitar', 'violin', 'viola', 'cello']:
        folder = root / ('interval_' + instrument)
        measurements = {midi: decode(args.ffmpeg, folder / f'{midi}.mp3') for midi in range(21, 109)}
        valid = [midi for midi, (_, rms) in measurements.items() if rms > .0001]
        if not valid:
            raise RuntimeError(f'No audible samples in {instrument}')
        repaired = 0
        for midi in range(21, 109):
            path = folder / f'{midi}.mp3'
            asset = f'audio/interval_{instrument}/{midi}.mp3'
            duration, rms = measurements[midi]
            source = prior.get(asset, midi)
            if rms <= .0001 or duration < 2:
                if not args.repair:
                    raise RuntimeError(f'Silent sample: {path}')
                source = prior.get(asset, min(valid, key=lambda note: abs(note - midi)))
                ratio = 2 ** ((midi - source) / 12)
                subprocess.run([
                    args.ffmpeg, '-v', 'error', '-y', '-i', str(folder / f'{source}.mp3'),
                    '-af', f'asetrate={round(44100 * ratio)},aresample=44100,atempo={1 / ratio}',
                    '-codec:a', 'libmp3lame', '-q:a', '2', str(path)
                ], check=True)
                duration, rms = decode(args.ffmpeg, path)
                repaired += 1
            if duration < 2 or rms <= .0001:
                raise RuntimeError(f'Insufficient note audio: {path}, {duration=}, {rms=}')
            rows.append({'asset': asset, 'midi': midi, 'source_midi': source,
                         'pitch_shift_semitones': midi - source,
                         'duration_seconds': f'{duration:.6f}', 'first_second_rms': f'{rms:.8f}'})
        print(f'{instrument}: 88 audible notes; {repaired} extended-register samples repaired', flush=True)
    with manifest.open('w', encoding='utf-8', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
    print(f'Audited {len(rows)} samples; every note has at least 2 seconds of audio', flush=True)


if __name__ == '__main__':
    main()
