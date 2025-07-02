import 'package:flutter/material.dart';

class MyMessageButton extends StatelessWidget {
  final void Function()? onPressed;

  const MyMessageButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: MaterialButton(
          padding: EdgeInsets.all(16),
          onPressed: onPressed,
          color: Colors.blue, // Buton rengi
          child: Text(
            "Mesaj Gönder",
            style: TextStyle(
              color: Theme.of(context).colorScheme.tertiary, // Yazı rengi
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
