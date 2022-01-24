



import 'dart:async';

import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:mapas_app/helpers/debouncer.dart';
import 'package:mapas_app/models/reverse_query_response.dart';

import 'package:mapas_app/models/search_response.dart';
import 'package:mapas_app/models/traffic_response.dart';

class TrafficService { 

  //singleton 
  TrafficService._privateConstructor();
  static TrafficService _instance = TrafficService._privateConstructor();
  factory TrafficService(){
    return _instance;
  }

  final _dio = new Dio();
  final debouncer = Debouncer<String>(duration: Duration(milliseconds: 400 ));

  final StreamController<SearchResponse>  _sugerenciasStreamController = new StreamController<SearchResponse>.broadcast();
  Stream<SearchResponse> get sugerenciaStream =>this._sugerenciasStreamController.stream;

  final _baseUrlDir = 'https://api.mapbox.com/directions/v5';
  final _baseUrlGeo = 'https://api.mapbox.com/geocoding/v5';
  final _apiKey = 'pk.eyJ1IjoiZXJpY2thbGRhaXIiLCJhIjoiY2tyd2I2dXVmMGVybDJ4bjFkd2NsMzN2ZyJ9.ONBdjyhdj8AV_zUbWMGLmQ';

  Future<DrivingResponse> getCoordsInicioYDestino(LatLng inicio, LatLng destino) async {

    final coordString = '${ inicio.longitude }, ${ inicio.latitude}; ${destino.longitude}, ${destino.latitude} ';
    final url = '${this._baseUrlDir}/mapbox/driving/$coordString';

    final resp = await this._dio.get(url, queryParameters:{

      'alternatives' : 'true',
      'geometries' : 'polyline6',
      'steps' : 'false',
      'access_token' : this._apiKey,
      'language' : 'es'

    });

    final data = DrivingResponse.fromJson(resp.data);

    return data;

  }


  Future<SearchResponse> getResultadosPorQuery(String busqueda, LatLng proximidad) async{

    print('buscando!!!');

    final url = '${ this._baseUrlGeo }/mapbox.places/$busqueda.json';

    try {

      final resp = await this._dio.get(url, queryParameters: {
      'access_token' : this._apiKey,
      'autocomplete' : 'true',
      'proximity'    : '${proximidad.longitude}, ${proximidad.latitude}',
      'language'     : 'es'

    });
    final searchResponse = searchResponseFromJson(resp.data);
    return searchResponse;
      
    } catch (e) {
      return SearchResponse(features: []);
    }

    
  }

  void getSugerenciasPorQuery( String busqueda, LatLng proximidad ) {

  debouncer.value = '';
  debouncer.onValue = ( value ) async {
    final resultados = await this.getResultadosPorQuery(value, proximidad);
    this._sugerenciasStreamController.add(resultados);
  };

  final timer = Timer.periodic(Duration(milliseconds: 200), (_) {
    debouncer.value = busqueda;
  });

  Future.delayed(Duration(milliseconds: 201)).then((_) => timer.cancel()); 

}

  void dispose() {
    _sugerenciasStreamController?.close();
  }
  
  Future<ReverseQueryResponse> getCoordenadasInfo(LatLng destinoCoords) async{

    final url = '${this._baseUrlGeo}/mapbox.places/${destinoCoords.longitude}, ${destinoCoords.latitude}.json';

    final resp = await this._dio.get(url, queryParameters:{

      'access_token' : this._apiKey,
      'language' : 'es'

    });
    
    final data = reverseQueryResponseFromJson(resp.data);
    //final data = DrivingResponse.fromJson(resp.data);

    return data;
  }
}

