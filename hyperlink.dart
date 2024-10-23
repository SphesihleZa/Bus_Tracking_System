import 'package:flutter/material.dart';

class MylinkText extends StatelessWidget {
// ontap function is used for a button to respond , this my be button bofore it is initialised in the gesturedetector
  final Function()? onTap;
  final String texxt;

  const MylinkText({super.key, required this.onTap, required this.texxt});

  @override
  Widget build(BuildContext context) {
    //gesture detector repsonf when you touch the screen in the app/mobile app
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Text(
          texxt,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
