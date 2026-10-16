"""Prepare offline 24-TET half-semitone samples with duration compensation.

python tools/interval_quarter_assets.py --ffmpeg PATH
Produces audio source assets only; no application build.
"""
import argparse
import array
import csv
import math
from pathlib import Path
import subprocess

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ffmpeg', required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
    ratio = 2 ** (1 / 24)
    rate = round(176400 * ratio)
    cents_error = 1200 * math.log2(rate / 176400) - 50
    rows = []
    for instrument in ['piano', 'guitar', 'violin', 'viola', 'cello']:
        folder = root / f'interval_{instrument}_quarter'
        folder.mkdir(exist_ok=True)
        for midi in range(21, 108):
            destination = folder / f'{2 * midi + 1}.mp3'
            source = root / f'interval_{instrument}' / f'{midi}.mp3'
            subprocess.run([args.ffmpeg, '-v','error','-y','-i',str(source), '-af',
                f'aresample=176400,asetrate={rate},aresample=44100,atempo={176400/rate},apad=whole_dur=3',
                '-t','3','-codec:a','libmp3lame','-q:a','2',str(destination)], check=True)
            decoded = subprocess.run([args.ffmpeg,'-v','error','-i',str(destination),'-f','s16le','-ac','1','-ar','44100','pipe:1'], check=True, capture_output=True)
            samples = array.array('h', decoded.stdout)
            first = samples[:44100]
            rms = math.sqrt(sum(x*x for x in first)/len(first))/32768
            if rms < .0001 or len(samples) < 88200:
                raise RuntimeError(f'Invalid quarter sample: {destination}')
            rows.append({'asset':f'audio/{folder.name}/{destination.name}','quarter_midi':2*midi+1,
                'source_midi':midi,'pitch_cents':50,'rate_cents_error':f'{cents_error:.8f}',
                'duration_seconds':f'{len(samples)/44100:.6f}','first_second_rms':f'{rms:.8f}'})
        print(f'{instrument}: 87 quarter-tone assets prepared and decoded',flush=True)
    with (root/'interval_quarter_audit.csv').open('w',encoding='utf-8',newline='') as file:
        writer = csv.DictWriter(file,fieldnames=rows[0].keys()); writer.writeheader(); writer.writerows(rows)
    print(f'435 samples; nominal shift 50 cents; rate error {cents_error:.8f} cents',flush=True)

if __name__ == '__main__':
    main()
