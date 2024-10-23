import 'package:flutter/material.dart';

class EndButton extends StatelessWidget {
  final Function()? onTap;

  final String texxt;

  const EndButton({
    super.key,
    required this.onTap,
    required this.texxt,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
            color: Color.fromARGB(255, 2, 37, 97),
            borderRadius: BorderRadius.circular(6)),
        child: Center(
          child: Text(
            texxt,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ),
    );
  }
}