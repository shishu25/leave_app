import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double width;
  const BrandLogo({super.key, this.width = 180});
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Zenov BPO',
        image: true,
        child: SizedBox(
          width: width,
          height: width,
          child: ClipRect(
              child: OverflowBox(
            maxWidth: width * 2.4,
            maxHeight: width * 2.4,
            child: Image.asset('assets/data/images/image.png',
                width: width * 2.4, height: width * 2.4, fit: BoxFit.contain),
          )),
        ),
      );
}
