import 'package:flutter/material.dart';
import 'package:luddo_2/old3pati.dart';
import 'spinn.dart'; // Your spin game widget

class HomeScreen extends StatelessWidget {
  void _showSpinGameBottomSheet(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      // Remove any default constraints from the bottom sheet
      constraints: BoxConstraints(
        maxWidth: width, // Explicitly set to screen width
      ),
      builder: (context) {
        return Container(
          height: height * 0.70, // 85% of screen height
          width: 800, // Full screen width
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          // Use Center widget to ensure proper alignment
          child: SizedBox(width: double.infinity, child: GameScreenSpin()),
        );
      },
    );
  }

  void _show3PatiGameBottomSheet(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      constraints: BoxConstraints(maxWidth: width),
      builder: (context) {
        return Container(
          height: height * 0.58, // 85% of screen height
          width: width, // Full screen width
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          // Use Center widget to ensure proper alignment
          child: SizedBox(width: double.infinity, child: NewTeenPatti()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text('Game Launcher')),
      body: Center(
        child: Row(
          children: [
            ElevatedButton(
              onPressed: () => _showSpinGameBottomSheet(context),
              child: Text('Open Spin Game'),
            ),
            ElevatedButton(
              onPressed: () => _show3PatiGameBottomSheet(context),
              child: Text('Open 3 Patti Game'),
            ),
          ],
        ),
      ),
    );
  }
}
