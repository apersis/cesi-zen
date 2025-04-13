import 'dart:convert';

import 'package:cesi_zen/utils/helper.dart';
import 'package:cesi_zen/widgets/appbar_screen.dart';
import 'package:cesi_zen/widgets/drawer_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FunCatPage extends StatefulWidget{
  @override
  const FunCatPage({super.key});

  @override
  State<FunCatPage> createState() => _FunCatPageState();
}

class _FunCatPageState extends State<FunCatPage>{

  final apiURL = Uri.https("cataas.com", "cat/gif", {"json" : "true"});
  String imageURL = "";
  bool isQueryProcess = false;

  @override
  void initState() {
    fetchCat();
    super.initState();
  }

  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(0,60), 
        child: AppBarScreen(pageName: "Page fun du chat",)
      ),
      
      drawer: DrawerMenuWidget(
        pageType: PageType.funcat,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: fetchCat,
        isExtended: true,
        label: Text(
          "Rafraichir"
        ),
        icon: const Icon(
          Icons.refresh,
          size: 32,
        ),
      ),
      body: SafeArea(
        child: isQueryProcess
          ? _SpinnerDelegate()
          : _ImageDelegate(url: imageURL)
      )
        
    );
  }

  Future<void> fetchCat() async{
    setState(() {
      isQueryProcess = true;
    });
    var response = await http.get(apiURL);
    final responseMapping = jsonDecode(response.body);
    setState(() {
      imageURL = responseMapping["url"];
      isQueryProcess = false;
    });
  }
}

class _SpinnerDelegate extends StatelessWidget {
  @override
  const _SpinnerDelegate();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(),
    );
  }
}

 class _ImageDelegate extends StatelessWidget {
  @override
  const _ImageDelegate({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.network(
        url,
        width: MediaQuery.of(context).size.width,
        fit: BoxFit.cover,
      ),
    );
  }
 }