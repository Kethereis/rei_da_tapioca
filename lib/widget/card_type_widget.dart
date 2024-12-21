import 'package:flutter/material.dart';

class CardTypeWidget extends StatelessWidget {
  final String title;
  final bool isCategory;


  const CardTypeWidget({super.key,required this.title, required this.isCategory,});

  @override
  Widget build(BuildContext context) {
    return isCategory ? SizedBox(
      height: 150,
        child: Card(

      color: Colors.white,
      surfaceTintColor: Colors.white,
      child: Center(
          child: Text(title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold
      ),)
    ))): Container();
  }
}