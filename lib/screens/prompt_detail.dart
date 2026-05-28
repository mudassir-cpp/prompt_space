import 'package:flutter/material.dart';

class PromptDetail extends StatefulWidget {
  const PromptDetail({super.key});

  @override
  State<PromptDetail> createState() => _PromptDetailState();
}

class _PromptDetailState extends State<PromptDetail> {

  // get data from text 

  @override
  Widget build(BuildContext context) {
    final data =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final fn = data['fn'];




    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text(fn),
      ),
    );
  }
}
