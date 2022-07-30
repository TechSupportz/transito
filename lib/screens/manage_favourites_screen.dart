import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:transito/models/favourite.dart';
import 'package:transito/providers/favourites_provider.dart';
import 'package:transito/widgets/favourite_name_card.dart';

import '../models/app_colors.dart';
import '../models/arrival_info.dart';
import '../models/secret.dart';
import 'edit_favourite_screen.dart';

class ManageFavouritesScreen extends StatefulWidget {
  const ManageFavouritesScreen({Key? key}) : super(key: key);

  @override
  State<ManageFavouritesScreen> createState() => _ManageFavouritesScreenState();
}

class _ManageFavouritesScreenState extends State<ManageFavouritesScreen> {
  bool isFabVisible = true;

  // api headers
  Map<String, String> requestHeaders = {
    'Accept': 'application/json',
    'AccountKey': Secret.LtaApiKey
  };

  // fetch arrival into to retrieve what buses are available if user wants to edit a favourite
  Future<BusArrivalInfo> fetchArrivalTimings(String busStopCode) async {
    debugPrint("Fetching arrival timings");
    // gets response from api
    final response = await http.get(
        Uri.parse(
            'http://datamall2.mytransport.sg/ltaodataservice/BusArrivalv2?BusStopCode=$busStopCode'),
        headers: requestHeaders);

    // if response is successful, parse the response and return it as a BusArrivalInfo object
    if (response.statusCode == 200) {
      debugPrint("Timing fetched");
      return BusArrivalInfo.fromJson(jsonDecode(response.body));
    } else {
      debugPrint("Error fetching arrival timings");
      throw Exception('Failed to load data');
    }
  }

  // function to get the list of bus services that are currently operating at that bus stop
  // this is used to display the bus stops in the edit favourites screen
  Future<List<String>> getBusServiceNumList(String busStopCode) async {
    List<String> busServicesList = await fetchArrivalTimings(busStopCode).then(
      (value) {
        List<String> _busServicesList = [];
        for (var service in value.services) {
          _busServicesList.add(service.serviceNum);
          // debugPrint('$_busServicesList');
        }
        return _busServicesList;
      },
    );
    // debugPrint('$busServicesList');
    return busServicesList;
  }

  // function to get the list of bus stops that are currently operating at that bus service and route to edit favourites screen
  Future<void> goToEditFavouritesScreen(BuildContext context, Favourite favourite) async {
    List<String> busServicesList = await getBusServiceNumList(favourite.busStopCode);
    // debugPrint('$busServicesList');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFavouritesScreen(
          busStopCode: favourite.busStopCode,
          busStopName: favourite.busStopName,
          busStopAddress: favourite.busStopAddress,
          busStopLocation: favourite.busStopLocation,
          busServicesList: busServicesList,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavouritesProvider>(
      builder: (context, value, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Manage Favourites'),
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Drag and drop to reorder your favourites",
                        style: TextStyle(fontSize: 16, color: AppColors.kindaGrey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Click the edit button to add/remove your favourited bus services",
                        style: TextStyle(fontSize: 16, color: AppColors.kindaGrey),
                      ),
                      SizedBox(height: 18),
                    ],
                  ),
                ),
                ReorderableListView.builder(
                  itemBuilder: (context, index) {
                    return Padding(
                      key: Key(value.favouritesList[index].busStopCode),
                      padding: const EdgeInsets.only(bottom: 18),
                      child: FavouriteNameCard(
                          busStopName: value.favouritesList[index].busStopName,
                          onTap: () =>
                              goToEditFavouritesScreen(context, value.favouritesList[index])),
                    );
                  },
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shrinkWrap: true,
                  buildDefaultDragHandles: true,
                  itemCount: value.favouritesList.length,
                  // calls reorder function in FavouritesProvider to reorder the favourites list
                  onReorder: (oldIndex, newIndex) => value.reorderFavourite(oldIndex, newIndex),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: "manageFavFAB",
            child: const Icon(Icons.done_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        );
      },
    );
  }
}
