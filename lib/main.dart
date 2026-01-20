import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AttendanceHome(),
    );
  }
}

class AttendanceHome extends StatefulWidget {
  const AttendanceHome({super.key});

  @override
  State<AttendanceHome> createState() => _AttendanceHomeState();
}

class _AttendanceHomeState extends State<AttendanceHome> {
  final TextEditingController _controller = TextEditingController();
  String statusMessage = "Enter name to mark attendance";

  // TODO: CHANGE THIS IP
  // Use "10.0.2.2" for Android Emulator
  // Use Your PC IP (e.g., 192.168.1.X) for Physical Device
  static const String serverIp = "172.20.155.30"; 
  static const int serverPort = 65432;

  Future<void> markAttendance() async {
    final name = _controller.text.trim();

    if (name.isEmpty) {
      setState(() => statusMessage = "Please enter a student name");
      return;
    }

    setState(() => statusMessage = "Connecting...");

    try {
      // 1. Connect
      final socket = await Socket.connect(
        serverIp,
        serverPort,
        timeout: const Duration(seconds: 5),
      );

      // 2. Send Data
      socket.write("ADD:$name");
      await socket.flush(); // Ensure data leaves the phone

      // 3. Listen for Response
      // We use a broadcast stream approach to listen for the server response
      socket.listen(
        (List<int> event) {
          final response = String.fromCharCodes(event).trim();
          setState(() {
            statusMessage = response;
          });
        },
        onError: (error) {
          setState(() => statusMessage = "Error: $error");
          socket.destroy();
        },
        onDone: () {
          // Server closed connection (expected behavior)
          socket.destroy();
        },
      );
    } catch (e) {
      setState(() {
        statusMessage = "Connection Failed.\nCheck IP & Firewall.";
      });
      print("Connection Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Smart Attendance")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Student Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: markAttendance,
              child: const Text("Mark Attendance"),
            ),
            const SizedBox(height: 20),
            Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}