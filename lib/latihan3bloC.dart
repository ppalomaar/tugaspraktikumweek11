
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
  final String name; // String nama universitas.
  final String website; // String alamat situs web universitas.

  University({required this.name, required this.website}); // Konstruktor untuk membuat objek University.

  // Method untuk membuat objek University dari data JSON.
  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'] ?? '', // Mengambil nama universitas dari data JSON.
      website: json['web_pages'].isNotEmpty ? json['web_pages'][0] : '', // Mengambil alamat situs web dari data JSON.
    );
  }
}

// Class yang merepresentasikan daftar universitas.
class UniversityList {
  final List<University> universities; // Daftar universitas.

  UniversityList({required this.universities}); // Konstruktor untuk membuat objek UniversitiesList.

  // Method untuk membuat objek UniversitiesList dari data JSON.
  factory UniversityList.fromJson(List<dynamic> json) {
    return UniversityList(
      universities: json.map((e) => University.fromJson(e)).toList(), // Mengembalikan objek UniversitiesList.
    );
  }
}

// Deklarasi Class UniversityBloc untuk extend Cubit dengan tipe data UniversityList
class UniversityBloc extends Cubit<UniversityList> {
  UniversityBloc() : super(UniversityList(universities: []));

  // Method untuk mengambil daftar universitas berdasarkan negara
  Future<void> fetchUniversities(String country) async {
    final response = await http.get(
      Uri.parse('http://universities.hipolabs.com/search?country=$country'),
    );

    // Periksa apakah respon berhasil
    if (response.statusCode == 200) {
      // Decode respons JSON dan emit ke UniversityList
      final List<dynamic> data = json.decode(response.body);
      emit(UniversityList.fromJson(data));
    } else {
      // Jika respon gagal, lemparkan exception
      throw Exception('Failed to load universities');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => UniversityBloc()..fetchUniversities('Indonesia'), // Inisialisasi UniversityBloc dan panggil fetchUniversities dengan negara Indonesia
          ),
        ],
        child: const HalamanUtama(),
      ),
    );
  }
}

class HalamanUtama extends StatefulWidget {
  const HalamanUtama({Key? key}) : super(key: key);

  @override
  _HalamanUtamaState createState() => _HalamanUtamaState();
}

class _HalamanUtamaState extends State<HalamanUtama> {
  String selectedCountry = 'Indonesia'; // Variabel untuk menyimpan negara yang dipilih

  @override
  Widget build(BuildContext context) {
    final UniversityBloc universityBloc = BlocProvider.of<UniversityBloc>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('List of universities in ASEAN'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: BlocBuilder<UniversityBloc, UniversityList>(
              builder: (context, state) {
                return DropdownButton<String>(
                  value: selectedCountry, // Set nilai default menjadi Indonesia
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedCountry = newValue; // Perbarui nilai negara yang dipilih
                      });
                      universityBloc.fetchUniversities(newValue); // Memuat ulang daftar universitas saat negara berubah.
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
          Expanded(
            child: BlocBuilder<UniversityBloc, UniversityList>(
              builder: (context, state) {
                return ListView.builder(
                  itemCount: state.universities.length, // Jumlah item dalam daftar.
                  itemBuilder: (context, index) {
                    final university = state.universities[index];
                    return ListTile(
                      title: Text(university.name), // Tampilkan nama universitas
                      subtitle: Text(university.website), // Tampilkan website universitas
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
