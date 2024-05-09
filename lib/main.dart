import 'package:flutter/material.dart'; // Melakukan import library material.dart
import 'package:http/http.dart' as http; // Melakukan import library http.dart dengan alias http
import 'dart:convert'; // Melakukan import library convert.dart
import 'package:provider/provider.dart'; // Melakukan import library provider.dart

// Fungsi utama yang akan dijalankan
void main() {
  // Membungkus aplikasi dengan ChangeNotifierProvider untuk mendukung manajemen state.
  runApp(
    ChangeNotifierProvider<ActivityModel>(
      // Membuat ActivityModel dan memberikannya ke ChangeNotifierProvider.
      create: (context) => ActivityModel(),
      // Membuat instance dari MyApp dan melewatkan ActivityModel ke dalamnya.
      child: const MyApp(),
    ),
  );
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

// Class model yang mengatur aktivitas di aplikasi.
class ActivityModel extends ChangeNotifier {
  String selectedCountry = "Indonesia"; // Negara yang dipilih.

  // Method untuk memperbarui negara yang dipilih.
  void updateCountry(String newCountry) {
    selectedCountry = newCountry;
    notifyListeners(); // Memberitahu pendengar tentang perubahan dalam model.
  }
}

// Class utama aplikasi Flutter.
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  late Future<UniversitiesList> futureUniversities; // Future dari daftar universitas.
  final String baseUrl = "http://universities.hipolabs.com/search?country="; // URL dasar untuk permintaan HTTP.

  @override
  void initState() {
    super.initState();
    futureUniversities = fetchUniversities(context); // Memuat daftar universitas saat aplikasi diinisialisasi.
  }

  // Method untuk mengambil daftar universitas dari server.
  Future<UniversitiesList> fetchUniversities(BuildContext context) async {
    final activityModel = Provider.of<ActivityModel>(context, listen: false); // Mendapatkan model Activity dari Provider.
    final response = await http.get(Uri.parse(baseUrl + activityModel.selectedCountry)); // Mengirim permintaan GET ke server.

    if (response.statusCode == 200) { // Jika permintaan berhasil,
      List jsonResponse = json.decode(response.body); // Mendekode respons JSON.
      return UniversitiesList.fromJson(jsonResponse); // Mengembalikan objek UniversitiesList.
    } else { // Jika terjadi kesalahan,
      throw Exception('Failed to load universities'); // Melontarkan pengecualian.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('List of universities in ASEAN'), 
          backgroundColor: Colors.blueAccent, 
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Consumer<ActivityModel>(
                builder: (context, activityModel, child) {
                  return DropdownButton<String>(
                    value: activityModel.selectedCountry, // Nilai DropdownButton yang dipilih.
                    onChanged: (String? newValue) {
                      activityModel.updateCountry(newValue!); // Memperbarui negara yang dipilih.
                      setState(() {
                        futureUniversities = fetchUniversities(context); // Memuat ulang daftar universitas saat negara berubah.
                      });
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
              SizedBox(height: 20), // Spacer
              Expanded(
                child: FutureBuilder<UniversitiesList>(
                  future: futureUniversities,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) { // Jika data sudah tersedia,
                      return ListView.builder(
                        itemCount: snapshot.data!.universities.length, // Jumlah item dalam daftar.
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(snapshot.data!.universities[index].name), // Nama universitas.
                            subtitle: Text(snapshot.data!.universities[index].website), // Alamat situs web universitas.
                          );
                        },
                      );
                    } else if (snapshot.hasError) { // Jika terjadi kesalahan saat memuat data,
                      return Text("${snapshot.error}"); // Tampilkan pesan kesalahan.
                    }
                    return CircularProgressIndicator(); // Tampilkan indikator loading saat menunggu data.
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}