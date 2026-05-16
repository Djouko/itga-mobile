import 'package:flutter/material.dart';

class LogoTag extends StatelessWidget {
  final bool? isWhite;
  final double? width;

  const LogoTag({Key? key, this.isWhite = false, this.width = 100}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logoWidth = width ?? 100;
    return Image.asset(
      'assets/images/itga_logo.png',
      width: logoWidth,
      height: logoWidth * 0.6,
      fit: BoxFit.contain,
      color: isWhite == true ? Colors.white : null,
      colorBlendMode: isWhite == true ? BlendMode.srcIn : null,
    );
  }
}
