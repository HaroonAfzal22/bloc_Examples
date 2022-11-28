import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as devtools show log;
// 00:30 to 01:25

void main() {
  runApp(const Myapp());
}

extension Log on Object {
  void log() => devtools.log(toString());
}
// abstrct
@immutable
abstract class LoadAction {
  const LoadAction();
}

// Load pesrson
@immutable
class LoadPersonsAction implements LoadAction {
  const LoadPersonsAction({required this.url}) : super();
  final PersonUrl url;
}

// enums
enum PersonUrl { persons1, persons2 }

// urls
extension UrlString on PersonUrl {
  String get urlString {
    switch (this) {
      case PersonUrl.persons1:
        return 'http://192.168.100.54:5500/api/persons1.json';
      case PersonUrl.persons2:
        return 'http://192.168.100.54:5500/api/persons2.json';
    }
  }
}

// person modal
@immutable
class Person {
  final String name;
  final int age;

  const Person({required this.name, required this.age});
  Person.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        age = json['age'] as int;
  @override
  String toString() => 'Person(name = $name, age=$age)';
}

// api call function
Future<Iterable<Person>> getPerson(String url) => HttpClient()
    .getUrl(Uri.parse(url))
    .then((req) => req.close())
    .then((res) => res.transform(utf8.decoder).join())
    .then((str) => json.decode(str) as List<dynamic>)
    .then((list) => list.map((e) => Person.fromJson(e)));

@immutable
class FetchResult {
  final Iterable<Person> persons;
  final bool isRetrievedFromCache;

  const FetchResult(
      {required this.persons, required this.isRetrievedFromCache});
  @override
  String toString() =>
      'FetchResult (isRetrievedFromCache = $isRetrievedFromCache, persons = $persons)';
}

class PersonsBloc extends Bloc<LoadAction, FetchResult?> {
  
  final Map<PersonUrl, Iterable<Person>> _cache = {};
  PersonsBloc() : super(null) {
    on<LoadPersonsAction>((event, emit) async {
      final url = event.url;
      if (_cache.containsKey(url)) {
        final cachedPesons = _cache[url]!;
        final result =
            FetchResult(persons: cachedPesons, isRetrievedFromCache: true);
        emit(result);
      } else {
        final persons = await getPerson(url.urlString);
        _cache[url] = persons;
        final result =
            FetchResult(persons: persons, isRetrievedFromCache: false);
        emit(result);
      }
    });
  }
}

extension Subscript<T> on Iterable<T> {
  T? operator [](int index) => length > index ? elementAt(index) : null;
}

class Myapp extends StatelessWidget {
  const Myapp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    late final Bloc myBlock;
    return MaterialApp(
      home: BlocProvider(
        create: (context) => PersonsBloc(),
        child: HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Row(
            children: [
              TextButton(
                onPressed: () {
                  context
                      .read<PersonsBloc>()
                      .add(const LoadPersonsAction(url: PersonUrl.persons1));
                },
                child: const Text('Load json #1'),
              ),
              TextButton(
                onPressed: () {
                  context
                      .read<PersonsBloc>()
                      .add(const LoadPersonsAction(url: PersonUrl.persons2));
                },
                child: const Text('Load json #2'),
              ),
            ],
          ),
          BlocBuilder<PersonsBloc, FetchResult?>(
              buildWhen: (previousResults, currentResults) {
            return previousResults?.persons != currentResults?.persons;
          }, builder: ((context, fetchResult) {
            fetchResult?.log();
            final persons = fetchResult?.persons;
            if (persons == null) {
              return const SizedBox();
            }
            return Expanded(
              child: ListView.builder(
                  itemCount: persons.length,
                  itemBuilder: (context, index) {
                    final person = persons[index];
                    return ListTile(
                      title: Text(person!.name.toString()),
                      trailing: Text(person.age.toString()),
                    );
                  }),
            );
          }))
        ],
      ),
    );
  }
}

