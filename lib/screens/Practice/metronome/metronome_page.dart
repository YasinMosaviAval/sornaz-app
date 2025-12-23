import 'package:flutter/material.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/screens/Practice/metronome/Components/labeled_slider.dart';
import 'package:sornaz/screens/Practice/metronome/metronome_controller.dart';

class MetronomePage extends StatefulWidget {
  const MetronomePage({super.key});

  @override
  State<MetronomePage> createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage> {
  final MetronomeController _controller = MetronomeController();

  int bpm = 120;
  int timeSignature = 4;

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Metronome')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('BPM: $bpm', style: Theme.of(context).textTheme.headlineMedium),
            Slider(
              value: bpm.toDouble(),
              min: 40,
              max: 200,
              onChanged: (v) {
                setState(() => bpm = v.toInt());
                _controller.setBpm(bpm);
              },
            ),

            const SizedBox(height: 24),

            // Text('Time Signature: $timeSignature/4'),
            Text('Beats: $timeSignature'),
            Slider(
              value: timeSignature.toDouble(),
              min: 2,
              max: 8,
              divisions: 6,
              onChanged: (v) {
                setState(() => timeSignature = v.toInt());
                _controller.setTimeSignature(timeSignature);
              },
            ),

            // const SizedBox(height: 32),

            // LabeledSlider(
            //   label: 'Swing',
            //   value: _controller.swingPercent,
            //   min: 0,
            //   max: 75,
            //   divisions: 15,
            //   unit: '%',
            //   onChanged: (v) => setState(() {
            //     _controller.swingPercent = v;
            //   }),
            // ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: LabeledSlider(
                    label: Icon(Icons.volume_up),
                    value: _controller.volume * 100,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    unit: '%',
                    onChanged: (v) {
                      setState(() {
                        _controller.setVolume(v / 100);
                      });
                    },
                  ),
                ),
              ],
            ),




            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _controller.tapTempo();
                  bpm = _controller.bpm;
                });
              },
              child: const Text('TAP'),
            ),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _controller.isPlaying
                          ? _controller.stop()
                          : _controller.start();
                    });
                  },
                  child: Text(
                    _controller.isPlaying ? 'Stop' : 'Play',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }
}
