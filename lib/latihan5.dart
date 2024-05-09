import 'package:flutter/material.dart'; // Melakukan import library material.dart
import 'package:http/http.dart' as http; // Melakukan import library http.dart dengan alias http
import 'dart:convert'; // Melakukan import library convert.dart
import 'package:flutter_bloc/flutter_bloc.dart'; // Melakukan import library flutter.bloc.dart

// Fungsi utama yang akan dijalankan
void main() {
  runApp(const MyApp());
}

// Class yang merepresentasikan universitas.
class University {
  String name; // String nama universitas.
  String website; // String alamat situs web universitas.

  University({required this.name, required this.website}); // Konstruktor untuk membuat objek University.

  // Method untuk membuat objek University dari data JSON.
  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'], // Mengambil nama universitas dari data JSON.
      website: json['web_pages'][0], // Mengambil alamat situs web dari data JSON.
    );
  }
}

// Class yang merepresentasikan daftar universitas.
class UniversitiesList {
  List<University> universities; // Daftar universitas.

  UniversitiesList({required this.universities}); // Konstruktor untuk membuat objek UniversitiesList.

  // Method untuk membuat objek UniversitiesList dari data JSON.
  factory UniversitiesList.fromJson(List<dynamic> json) {
    List<University> universities = []; // Inisialisasi daftar universitas.
    universities = json.map((uni) => University.fromJson(uni)).toList(); // Mengisi daftar universitas dengan objek University yang dibuat dari data JSON.
    return UniversitiesList(universities: universities); // Mengembalikan objek UniversitiesList.
  }
}

// Cubit untuk mengelola negara yang dipilih
class CountryCubit extends Cubit<String> {
  CountryCubit() : super('Indonesia');

  void updateCountry(String newCountry) => emit(newCountry);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CountryCubit(),
      child: MaterialApp(
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<UniversitiesList> futureUniversities;

  @override
  void initState() {
    super.initState();
    final CountryCubit countryCubit = BlocProvider.of<CountryCubit>(context);
    futureUniversities = fetchUniversities(context, countryCubit.state);
  }

  @override
Widget build(BuildContext context) {
  final CountryCubit countryCubit = BlocProvider.of<CountryCubit>(context);

  return Scaffold(
    appBar: AppBar(
      title: const Text('List of universities in ASEAN'),
      backgroundColor: Colors.blueAccent,
    ),
    body: Column( // Ubah widget body menjadi Column
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center( // Pusatkan dropdown di dalam Column
          child: BlocBuilder<CountryCubit, String>(
            builder: (context, state) {
              return DropdownButton<String>(
                value: state, // Nilai DropdownButton yang dipilih.
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    countryCubit.updateCountry(newValue); // Memperbarui negara yang dipilih.
                    setState(() {
                      futureUniversities = fetchUniversities(context, newValue); // Memuat ulang daftar universitas saat negara berubah.
                    });
                  }
                },
                items: <String>['Indonesia', 'Malaysia', 'Singapore']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value), // Menampilkan nama negara di dalam DropdownButton.
                  );
                }).toList(),
              );
            },
          ),
        ),
        Expanded( // Expanded untuk memastikan FutureBuilder mengisi ruang yang tersedia
          child: FutureBuilder<UniversitiesList>(
            future: futureUniversities,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) { // Jika data telah tersedia ketika terkoneksi
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              } else if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data!.universities.length, // Jumlah item dalam daftar.
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(snapshot.data!.universities[index].name), // Nama universitas.
                      subtitle: Text(snapshot.data!.universities[index].website), // Alamat situs web universitas.
                    );
                  },
                );
              }
              return const Text("No data found");
            },
          ),
        ),
      ],
    ),
  );
}

  // Mengambil daftar universitas dari API berdasarkan negara yang dipilih
  Future<UniversitiesList> fetchUniversities(BuildContext context, String selectedCountry) async {
    const String baseUrl = "http://universities.hipolabs.com/search?country="; // URL dasar untuk API
    final response = await http.get(Uri.parse(baseUrl + selectedCountry)); // Melakukan request ke API berdasarkan negara yang dipilih

    // Jika status code adalah 200 (berhasil), parse data JSON
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return UniversitiesList.fromJson(jsonResponse);
    } 
    // Jika gagal, lempar error
    else {
      throw Exception('Failed to load universities');
    }
  }
}