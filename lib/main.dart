import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DatabaseProvider>(
          create: (_) => DatabaseProvider(),
        ),
        ChangeNotifierProvider<FormDataProvider>(
          create: (_) => FormDataProvider(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class DatabaseProvider extends ChangeNotifier {
  late Database database;

  Future<void> open() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'database.db');
    database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
    CREATE TABLE formData (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      phoneNo TEXT,
      email TEXT,
      dob TEXT,
      motherName TEXT,
      fatherName TEXT,
      motherOccupation TEXT,
      fatherOccupation TEXT
    )
  ''');
      },
    );
  }

  Future<int> insertFormData(Map<String, dynamic> formData) async {
    final result = await database.insert('formData', formData,
        conflictAlgorithm: ConflictAlgorithm.replace);
    // After inserting data, notify listeners
    notifyListeners();
    return result;
  }

  Future<List<Map<String, dynamic>>> getAllFormData() async {
    return await database.query('formData');
  }

  Future<Map<String, dynamic>> getFormDataById(int id) async {
    final List<Map<String, dynamic>> result = await database.query(
      'formData',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      throw Exception("Data not found");
    }
  }

  Future<void> deleteFormData(int id) async {
    await database.delete(
      'formData',
      where: 'id = ?',
      whereArgs: [id],
    );
    // Notify listeners after deleting data
    notifyListeners();
  }
}

class FormData {
  int? id;
  String? name;
  String? phoneNo;
  String? email;
  String? dob;
  String? motherName;
  String? fatherName;
  String? motherOccupation;
  String? fatherOccupation;

  FormData({
    this.id,
    this.name,
    this.phoneNo,
    this.email,
    this.dob,
    this.motherName,
    this.fatherName,
    this.motherOccupation,
    this.fatherOccupation,
  });
}

class FormDataProvider with ChangeNotifier {
  List<FormData> formDataList = [];

  void addFormData(FormData formData) {
    formDataList.add(formData);
    notifyListeners();
  }

// Other methods as needed...
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Form Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => FirstFormPage(),
        '/secondForm': (context) => SecondFormPage(),
        '/displayData': (context) => DisplayFormDataPage(),
        '/editForm': (context) {
          // Extract the ID from the route arguments
          final int id = ModalRoute.of(context)!.settings.arguments as int;
          return EditFormPage(id);
        },
      },
    );
  }
}

class FirstFormPage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneNoController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('First Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextFormField(
              controller: phoneNoController,
              decoration: InputDecoration(labelText: 'Phone No.'),
            ),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextFormField(
              controller: dobController,
              decoration: InputDecoration(
                labelText: 'Date of Birth',
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () async {
                    final DateTime? selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (selectedDate != null &&
                        selectedDate != dobController.text) {
                      dobController.text =
                      selectedDate.toLocal().toString().split(' ')[0];
                    }
                  },
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final formData = FormData(
                  name: nameController.text,
                  phoneNo: phoneNoController.text,
                  email: emailController.text,
                  dob: dobController.text,
                );

                // Save data to the database
                final databaseProvider =
                Provider.of<DatabaseProvider>(context, listen: false);

                try {
                  await databaseProvider.open();
                  final id = await databaseProvider.insertFormData({
                    'name': formData.name,
                    'phoneNo': formData.phoneNo,
                    'email': formData.email,
                    'dob': formData.dob,
                    'motherName': null,
                    'fatherName': null,
                    'motherOccupation': null,
                    'fatherOccupation': null,
                  });

                  // Add the form data to the list with the assigned ID
                  formData.id = id;
                  Provider.of<FormDataProvider>(context, listen: false)
                      .addFormData(formData);

                  // Navigate to the second form page
                  Navigator.pushNamed(context, '/secondForm');
                } catch (error) {
                  print('Error saving data to the database: $error');
                }
              },
              child: Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondFormPage extends StatelessWidget {
  final TextEditingController motherNameController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();
  final TextEditingController motherOccupationController =
  TextEditingController();
  final TextEditingController fatherOccupationController =
  TextEditingController();

  @override
  Widget build(BuildContext context) {
    final formDataFromFirstPage =
        Provider.of<FormDataProvider>(context).formDataList.first;

    return Scaffold(
      appBar: AppBar(
        title: Text('Second Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: motherNameController,
              decoration: InputDecoration(labelText: "Mother's Name"),
            ),
            TextFormField(
              controller: fatherNameController,
              decoration: InputDecoration(labelText: "Father's Name"),
            ),
            TextFormField(
              controller: motherOccupationController,
              decoration: InputDecoration(labelText: "Mother's Occupation"),
            ),
            TextFormField(
              controller: fatherOccupationController,
              decoration: InputDecoration(labelText: "Father's Occupation"),
            ),
            ElevatedButton(
              onPressed: () async {
                final formData = FormData(
                  motherName: motherNameController.text,
                  fatherName: fatherNameController.text,
                  motherOccupation: motherOccupationController.text,
                  fatherOccupation: fatherOccupationController.text,
                );

                // Save the data to the database
                final databaseProvider =
                Provider.of<DatabaseProvider>(context, listen: false);

                try {
                  await databaseProvider.open();
                  await databaseProvider.insertFormData({
                    'id': formDataFromFirstPage.id, // Include the ID when updating
                    'name': formDataFromFirstPage.name,
                    'phoneNo': formDataFromFirstPage.phoneNo,
                    'email': formDataFromFirstPage.email,
                    'dob': formDataFromFirstPage.dob,
                    'motherName': formData.motherName,
                    'fatherName': formData.fatherName,
                    'motherOccupation': formData.motherOccupation,
                    'fatherOccupation': formData.fatherOccupation,
                  });

                  // Add the second form data to the list
                  Provider.of<FormDataProvider>(context, listen: false)
                      .addFormData(formData);

                  // Navigate to the display data page
                  Navigator.pushNamed(context, '/displayData');
                } catch (error) {
                  print('Error saving data to the database: $error');
                }
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class EditFormPage extends StatefulWidget {
  final int id; // Receive the ID as an argument

  EditFormPage(this.id);

  @override
  _EditFormPageState createState() => _EditFormPageState();
}

class _EditFormPageState extends State<EditFormPage> {
  late TextEditingController nameController;
  late TextEditingController phoneNoController;
  late TextEditingController emailController;
  late TextEditingController dobController;
  late TextEditingController motherNameController;
  late TextEditingController fatherNameController;
  late TextEditingController motherOccupationController;
  late TextEditingController fatherOccupationController;

  _EditFormPageState() {
    // Initialize the controllers in the constructor
    nameController = TextEditingController();
    phoneNoController = TextEditingController();
    emailController = TextEditingController();
    dobController = TextEditingController();
    motherNameController = TextEditingController();
    fatherNameController = TextEditingController();
    motherOccupationController = TextEditingController();
    fatherOccupationController = TextEditingController();
  }

  // Create a separate method to perform asynchronous initialization
  Future<void> initializeFormData() async {
    // Fetch data from the database using the provided ID
    final databaseProvider =
    Provider.of<DatabaseProvider>(this.context, listen: false);
    final formDataFromDatabase =
    await databaseProvider.getFormDataById(widget.id);

    // Initialize the controllers with the fetched data
    setState(() {
      nameController = TextEditingController(text: formDataFromDatabase['name']);
      phoneNoController =
          TextEditingController(text: formDataFromDatabase['phoneNo']);
      emailController =
          TextEditingController(text: formDataFromDatabase['email']);
      dobController = TextEditingController(text: formDataFromDatabase['dob']);
      motherNameController =
          TextEditingController(text: formDataFromDatabase['motherName']);
      fatherNameController =
          TextEditingController(text: formDataFromDatabase['fatherName']);
      motherOccupationController =
          TextEditingController(text: formDataFromDatabase['motherOccupation']);
      fatherOccupationController =
          TextEditingController(text: formDataFromDatabase['fatherOccupation']);
    });
  }

  @override
  void initState() {
    super.initState();
    // Call the asynchronous initialization method
    initializeFormData();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneNoController.dispose();
    emailController.dispose();
    dobController.dispose();
    motherNameController.dispose();
    fatherNameController.dispose();
    motherOccupationController.dispose();
    fatherOccupationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextFormField(
                controller: phoneNoController,
                decoration: InputDecoration(labelText: 'Phone No.'),
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: dobController,
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      final DateTime? selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (selectedDate != null &&
                          selectedDate != dobController.text) {
                        dobController.text =
                        selectedDate.toLocal().toString().split(' ')[0];
                      }
                    },
                  ),
                ),
              ),
              TextFormField(
                controller: motherNameController,
                decoration: InputDecoration(labelText: "Mother's Name"),
              ),
              TextFormField(
                controller: fatherNameController,
                decoration: InputDecoration(labelText: "Father's Name"),
              ),
              TextFormField(
                controller: motherOccupationController,
                decoration: InputDecoration(labelText: "Mother's Occupation"),
              ),
              TextFormField(
                controller: fatherOccupationController,
                decoration: InputDecoration(labelText: "Father's Occupation"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final formData = {
                    'id': widget.id,
                    'name': nameController.text,
                    'phoneNo': phoneNoController.text,
                    'email': emailController.text,
                    'dob': dobController.text,
                    'motherName': motherNameController.text,
                    'fatherName': fatherNameController.text,
                    'motherOccupation': motherOccupationController.text,
                    'fatherOccupation': fatherOccupationController.text,
                  };

                  // Update the form data in the database
                  final databaseProvider =
                  Provider.of<DatabaseProvider>(context, listen: false);

                  try {
                    await databaseProvider.open();
                    await databaseProvider.insertFormData(formData);

                    // Update the form data in the provider
                    Provider.of<FormDataProvider>(context, listen: false)
                        .formDataList
                        .firstWhere((data) => data.id == widget.id)
                        .name = formData['name'] as String?;
                    // Repeat for other properties...

                    // Navigate back to the display page with updated data
                    Navigator.pop(context);
                  } catch (error) {
                    print('Error updating data in the database: $error');
                  }
                },
                child: Text('Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DisplayFormDataPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final databaseProvider = Provider.of<DatabaseProvider>(context);
    final formDataProvider = Provider.of<FormDataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Display Form Data'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: databaseProvider.getAllFormData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text('No data available.');
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final data = snapshot.data![index];
                final formData = FormData(
                  id: data['id'],
                  name: data['name'],
                  phoneNo: data['phoneNo'],
                  email: data['email'],
                  dob: data['dob'],
                  motherName: data['motherName'],
                  fatherName: data['fatherName'],
                  motherOccupation: data['motherOccupation'],
                  fatherOccupation: data['fatherOccupation'],
                );

                // Check if any properties are null and remove them
                // ... implement your logic here ...

                return ListTile(
                  title: Text('Name: ${formData.name ?? ''}'),
                  subtitle: Text('Phone: ${formData.phoneNo ?? ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          // Navigate to the EditFormPage with the selected data
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditFormPage(formData.id!),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          // Implement delete functionality here
                          await databaseProvider.deleteFormData(formData.id!);

                          // Remove data from the provider
                          formDataProvider.formDataList
                              .removeWhere((item) => item.id == formData.id);

                          // Refresh the data displayed on this page
                          // ... implement your logic here ...

                          // Show a snackbar or a message to confirm the deletion
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Data deleted.'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
