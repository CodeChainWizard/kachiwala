import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class JsonProvider with ChangeNotifier {

  Map<String, dynamic> _jsonData = {
    "name": "",
    "age": 22,
    "city": ""
  };

  Map<String, dynamic> get jsonData => _jsonData;

  void updateJsonData(String key, dynamic value) {
    _jsonData = {..._jsonData, key: value};
    notifyListeners();
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => JsonProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter JSON Update',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: JsonUpdateScreen(),
    );
  }
}

class JsonUpdateScreen extends StatefulWidget {
  @override
  _JsonUpdateScreenState createState() => _JsonUpdateScreenState();
}

class _JsonUpdateScreenState extends State<JsonUpdateScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final jsonProvider = Provider.of<JsonProvider>(context, listen: false);
    _nameController.text = jsonProvider.jsonData["name"];
    _cityController.text = jsonProvider.jsonData["city"];
  }

  @override
  Widget build(BuildContext context) {
    final jsonProvider = Provider.of<JsonProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("ChangeNotifier JSON Update")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Name: ${jsonProvider.jsonData['name']}"),
            Text("Age: ${jsonProvider.jsonData['age']}"),
            Text("City: ${jsonProvider.jsonData['city']}"),
            SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Enter Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),


            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: "Enter City",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                jsonProvider.updateJsonData("name", _nameController.text);
                jsonProvider.updateJsonData("city", _cityController.text);
              },
              child: Text("Update"),
            ),
          ],
        ),
      ),
    );
  }
}
