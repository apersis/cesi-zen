
import 'package:cesi_zen/utils/helper.dart';
import 'package:cesi_zen/widgets/appbar_screen.dart';
import 'package:cesi_zen/widgets/drawer_menu_widget.dart';
import 'package:flutter/material.dart';

class InfoPage extends StatefulWidget {
  @override
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage>{
  @override
  Widget build(BuildContext context){
    return Scaffold(
      drawer: DrawerMenuWidget(pageType: PageType.info),
      appBar: PreferredSize(
        preferredSize: Size(0, 60),
        child: AppBarScreen(pageName: "Informations"),
      ),
      body: Center(
        child: Text('Hello World!'),
      ),
      
    );
  }
}