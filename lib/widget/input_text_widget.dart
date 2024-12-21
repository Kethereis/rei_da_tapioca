import 'package:flutter/material.dart';

class InputTextWidget extends StatelessWidget {
  final TextEditingController controller;
  final String item;
  final bool? readOn;
  final int? maxLine;
  final bool? isNumber;

  const InputTextWidget({super.key,this.isNumber, required this.controller, required this.item, this.readOn, this.maxLine});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: Colors.grey,
          width: 0.5,
        ),
      ),
      child: TextFormField(
        enabled: readOn ?? true,
        controller: controller,
        keyboardType: isNumber == true ? TextInputType.number: TextInputType.text,
        textCapitalization: TextCapitalization.words,
        maxLines: maxLine ?? 1,
        decoration: InputDecoration(
          hintText: item,
          labelText:item,
          hintStyle: const TextStyle(
            color: Colors.grey,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto, // Deixa o label flutuar ao digitar

          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(5.0),
        ),
      ),
    );
  }
}