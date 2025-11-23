import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class RecorderPage extends StatefulWidget {
  const RecorderPage({super.key});

  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  final AudioRecorder recorder = AudioRecorder();   // ✅ Correct class
  bool isRecording = false;
  String? recordedPath;

  Future<String> _getFilePath() async {
    Directory dir = await getApplicationDocumentsDirectory();
    return "${dir.path}/medicine_voice_${DateTime.now().millisecondsSinceEpoch}.m4a";
  }

  Future<void> startRecording() async {
    final hasPermission = await recorder.hasPermission();   // ✅ Updated

    if (hasPermission) {
      final filePath = await _getFilePath();

      await recorder.start(                               // ✅ Updated API
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      setState(() {
        isRecording = true;
        recordedPath = filePath;
      });
    }
  }

  Future<void> stopRecording() async {
    await recorder.stop();   // ✅ Updated API
    setState(() {
      isRecording = false;
    });
  }

  @override
  void dispose() {
    recorder.dispose();     // ✅ Required
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Voice Recorder"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRecording ? Icons.mic : Icons.mic_none,
              size: 120,
              color: isRecording ? Colors.red : Colors.grey,
            ),

            const SizedBox(height: 20),

            Text(
              isRecording ? "Recording..." : "Tap to Record",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                if (isRecording) {
                  stopRecording();
                } else {
                  startRecording();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isRecording ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text(
                isRecording ? "Stop Recording" : "Start Recording",
                style: const TextStyle(fontSize: 18),
              ),
            ),

            const SizedBox(height: 40),

            if (recordedPath != null)
              Text(
                "Saved at:\n$recordedPath",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}
