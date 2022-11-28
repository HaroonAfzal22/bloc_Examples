import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'dart:math' as math show Random;

void main() {
  runApp(const MyApp());
}

const names = ['Foo', 'Bar', 'Baz'];

extension RandomElement<T> on Iterable<T> {
  T getRandomElement() => elementAt(math.Random().nextInt(length));
}

// Cubit Class
class NamesCubits extends Cubit<String?> {
  NamesCubits() : super(null);
  void pickRandamName() {
    emit(names.getRandomElement());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late NamesCubits cubit;
  @override
  void initState() {
    // TODO: implement initState

    cubit = NamesCubits();
  }

  void dispose() {
    // TODO: implement dispose
    super.dispose();
    cubit.close();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(),
          body: StreamBuilder<String?>(
            stream: cubit.stream,
            builder: (context, snapshot) {
              final button = TextButton(
                onPressed: () {
                  cubit.pickRandamName();
                },
                child: const Text('Pick a random name'),
              );
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return button;
                case ConnectionState.waiting:
                  return button;
                  break;
                case ConnectionState.active:
                  // TODO: Handle this case.
                  return Column(
                    children: [Text(snapshot.data ?? ''), button],
                  );
                case ConnectionState.done:
                  // TODO: Handle this case.
                  return const SizedBox();
              }
            },
          )),
    );
  }
}
