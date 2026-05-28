import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_masonry_view/flutter_masonry_view.dart';
import 'package:prompt_space/routes.dart';
import 'package:prompt_space/screens/prompt_detail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANONKEY'),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (context) => HomePage(),
        AppRoutes.prompt_detail: (context) => PromptDetail(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoaded = false;
  final imgs = [];

  void loadQouta() {
    for (int i = 41; i < 131; i++) {
      imgs.add('assets/${i}.jpg');
    }
    isLoaded = true;
  }

  @override
  void initState() {
    super.initState();
    loadQouta();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MASI DI SHAADI')),
      backgroundColor: Colors.pink,
      body: SingleChildScrollView(
        child: MasonryView(
          listOfItem: imgs,
          numberOfColumn: 2,
          itemBuilder: (item) {
            return GestureDetector(
              child: Image.asset(item),
              onTap: () {
                // route to detail page
                Navigator.pushNamed(
                  context,
                  AppRoutes.prompt_detail,
                  arguments: {
                    'fn':item as String
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
