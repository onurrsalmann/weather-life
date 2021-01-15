import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  runApp(WeatherLife());
}

class WeatherLife extends StatefulWidget {
  @override
  _WeatherLifeState createState() => _WeatherLifeState();
}

class _WeatherLifeState extends State<WeatherLife> {
  String temp = '';
  String location = "istanbul";
  String lon = '';
  String lat = '';
  String weather = 'clear';
  String currentIcon = '13n';
  String errorString = '';
  var minTempForecast = new List(8);
  var maxTempForecast = new List(8);
  var iconTempForecast = new List(8);

  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

  String currentApiUrl = "http://api.openweathermap.org/data/2.5/weather?units=metric&lang=tr&appid=b3c7974ab6849271439bd12248c8c0a4&q=";
  String forecastApiUrl = "https://api.openweathermap.org/data/2.5/onecall?exclude=current,minutely,hourly&lang=tr&units=metric&appid=b3c7974ab6849271439bd12248c8c0a4&";
  String myLocalApiUrl = "http://api.openweathermap.org/data/2.5/weather?units=metric&lang=tr&appid=b3c7974ab6849271439bd12248c8c0a4&";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeDateFormatting('tr');
    onTextFieldSubmitted(location);
  }

  void fetchCurrent(String input) async {
    try{
      var currentResult = await http.get(currentApiUrl + input);
      var result = json.decode(currentResult.body);

      setState(() {
        location = result['name'];
        temp = result['main']['temp'].toString();
        lat = result['coord']['lat'].toString();
        lon = result['coord']['lon'].toString();
        weather = result['weather'].first['description'];
        currentIcon = result['weather'].first['icon'];
        errorString = '';
      });
    }catch(error){
      setState(() {
        location = 'istanbul';
        errorString = "Lütfen geçerli bir şehir girin" ;
      });
    }
    fetchForecast();
  }

  void myLocationCurrent(double localLat, double localLon) async {
    try{
      var currentResult = await http.get(myLocalApiUrl + "lat=" + localLat.toString() + "&lon=" + localLon.toString());
      var result = json.decode(currentResult.body);

      setState(() {
        location = result['name'];
        temp = result['main']['temp'].toString();
        lat = result['coord']['lat'].toString();
        lon = result['coord']['lon'].toString();
        weather = result['weather'].first['description'];
        currentIcon = result['weather'].first['icon'];
        errorString = '';
      });
    }catch(error){
      setState(() {
        location = 'istanbul';
        errorString = "Lütfen geçerli bir şehir girin" ;
      });
    }
    fetchForecast();
  }

  void fetchForecast() async {
    var forecastResult = await http.get(forecastApiUrl + "lat=" + lat + "&lon=" + lon);
    Map<String, dynamic> result = json.decode(forecastResult.body);
    List<dynamic> dailys = result["daily"];
    dailys.asMap().forEach((key, value) {
      setState(() {
        minTempForecast[key] = value['temp']['min'];
        maxTempForecast[key] = value['temp']['max'];
        iconTempForecast[key] = value['weather'].first['icon'];
      });
    });
  }

  void onTextFieldSubmitted(String input) async {
    fetchCurrent(input);
  }

  _getCurrentLocation() {
    geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best).then((Position position) {
      myLocationCurrent(position.latitude, position.longitude);
    }).catchError((e) {
      print(e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Container(
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: GestureDetector(
                    onTap: () {_getCurrentLocation();},
                    child: Icon( Icons.location_city , size: 32,),
                  ),
                )
              ], backgroundColor: Colors.transparent, elevation: 0.0,
            ),
            resizeToAvoidBottomInset: false,
            body:
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      children: [
                        Container(
                          child: TextField(
                            onSubmitted: (String input){
                              onTextFieldSubmitted(input);
                            },
                            style: TextStyle(color: Colors.white, fontSize: 20),
                            decoration: InputDecoration(
                                hintText: 'Konum Giriniz',
                                hintStyle:  TextStyle( color: Colors.white, fontSize: 20),
                                prefixIcon: Icon(Icons.search, color: Colors.white)
                            ),
                          ),
                        ),
                        Text(
                          errorString,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.redAccent, fontSize: 20
                          ),
                        )
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                          child: Text(
                            location,
                            style: TextStyle(color: Colors.white, fontSize: 35),
                          )
                      ),
                      Center(
                        child: Image.network("http://openweathermap.org/img/wn/" + currentIcon + "@2x.png", width: 85),
                      ),
                      Center(
                          child: Text(
                            temp + ' °C',
                            style: TextStyle(color: Colors.white, fontSize: 35),
                          )
                      ),
                    ],
                  ),
                  Text('5 Gün', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for(var i=0; i<5; i++)
                          forecastElement(i, iconTempForecast[i] ?? '13n', maxTempForecast[i] ,minTempForecast[i]),
                      ],
                    ),
                  ),
                  Text('16 Gün', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for(var i=0; i<8; i++)
                          forecastElement(i, iconTempForecast[i] ?? '13n', maxTempForecast[i] ,minTempForecast[i]),
                        for(var i=7; i>=0; i--)
                          forecastElement(16-i, iconTempForecast[i] ?? '13n', maxTempForecast[i] ,minTempForecast[i]),
                      ],
                    ),
                  )
                ],
              ),
          ),
        )
    );
  }
}

Widget forecastElement(daysFromNow, icon, maxTemp, minTemp){
  var now = new DateTime.now();
  var oneDayFromNow = now.add(new Duration(days: daysFromNow));
  return Padding(
    padding: const EdgeInsets.only(left: 16),
    child: Container(
        decoration: BoxDecoration(
            color: Color.fromRGBO(205, 212, 228, 0.2),
            borderRadius: BorderRadius.circular(10)
        ),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(new DateFormat.E('tr_TR').format(oneDayFromNow),
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
                Text(new DateFormat.MMMd('tr_TR').format(oneDayFromNow),
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                Image.network("http://openweathermap.org/img/wn/" + icon + "@2x.png", width: 70,),
                Text(maxTemp.toString()+'°C | '+minTemp.toString()+'°C',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                )
              ],
            ),
        )
    ),

  );
}