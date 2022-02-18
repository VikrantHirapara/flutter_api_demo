import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        // Remove the debug banner
        debugShowCheckedModeBanner: false,
        title: 'Users',
        theme: ThemeData(
          primarySwatch: Colors.lightBlue,
        ),
        home: const HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // We will fetch data from this Rest api
  final _baseUrl = 'http://sd2-hiring.herokuapp.com/api/users';
  late List<dynamic> items = [];

  // At the beginning, we fetch the first 20 posts
  int _page = 0;
  final int _limit = 10;

  // There is next page or not
  bool _hasNextPage = true;

  // Used to display loading indicators when _firstLoad function is running
  bool _isFirstLoadRunning = false;

  // Used to display loading indicators when _loadMore function is running
  bool _isLoadMoreRunning = false;

  // This holds the posts fetched from the server
  final List<dynamic> _posts = [];

  // This function will be called when the app launches (see the initState function)
  Future _firstLoad() async {
    setState(() {
      _isFirstLoadRunning = true;
    });
    try {
      final res =
          await http.get(Uri.parse("$_baseUrl?offset=$_page&limit=$_limit"));
      setState(() {
        Map<String, dynamic> map = jsonDecode(res.body);
        Map<String, dynamic> data = map["data"];
        _hasNextPage = data["has_more"];
        List<dynamic> list = data["users"];
        _posts.addAll(list);

        for (int i = 0; i < _posts.length; i++) {
          items.add(_posts[i]["items"]);
        }
      });
    } catch (err) {
      if (kDebugMode) {
        print('Something went wrong');
      }
    }

    setState(() {
      _isFirstLoadRunning = false;
    });
  }

  // This function will be triggered whenver the user scroll
  // to near the bottom of the list view
  Future _loadMore() async {
    if (_hasNextPage == true &&
        _isFirstLoadRunning == false &&
        _isLoadMoreRunning == false &&
        _controller.position.extentAfter < 300) {
      setState(() {
        _isLoadMoreRunning = true; // Display a progress indicator at the bottom
      });
      _page += 10; // Increase _page by 10
      try {
        final res =
            await http.get(Uri.parse("$_baseUrl?offset=$_page&limit=$_limit"));

        Map<String, dynamic> map = jsonDecode(res.body);
        Map<String, dynamic> data = map["data"];
        List<dynamic> fetchedPosts = data["users"];

        if (fetchedPosts.isNotEmpty) {
          setState(() {
            _posts.addAll(fetchedPosts);
            for (int i = 0; i < _posts.length; i++) {
              items.add(_posts[i]["items"]);
            }
          });
        } else {
          // This means there is no more data
          // and therefore, we will not send another GET request
          setState(() {
            _hasNextPage = false;
          });
        }
      } catch (err) {
        print('Something went wrong!');
      }

      setState(() {
        _isLoadMoreRunning = false;
      });
    }
  }

  // The controller for the ListView
  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _firstLoad();
    _controller = ScrollController()..addListener(_loadMore);
  }

  @override
  void dispose() {
    _controller.removeListener(_loadMore);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int count = 5;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
      ),
      body: _isFirstLoadRunning
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    controller: _controller,
                    itemCount: _posts.length,
                    itemBuilder: (_, index) => Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ListTile(
                            title: Text(_posts[index]["name"]),
                            leading: CircleAvatar(
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                      image:
                                          NetworkImage(_posts[index]["image"]),
                                      fit: BoxFit.fill),
                                ),
                              ),
                            ),
                          ),
                          StaggeredGridView.countBuilder(
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              physics: ScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              crossAxisCount: 2,
                              itemCount: items[index].length,
                              itemBuilder: (BuildContext context, int i) =>
                                  Center(
                                      child: ClipRRect(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(15)),
                                    child: Image.network(
                                        items[index][i].toString()),
                                  )),
                              staggeredTileBuilder: (int staggeredIndex) {
                                if ((items[index].length) % 2 != 0 && staggeredIndex == 0) {
                                  return  const StaggeredTile.count(2, 2);
                                }
                                return const StaggeredTile.count(1, 1);
                              }),
                        ],
                      ),
                    ),
                  ),
                ),

                // when the _loadMore function is running
                if (_isLoadMoreRunning == true)
                  const Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 40),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // When nothing else to load
                if (_hasNextPage == false)
                  Container(
                    padding: const EdgeInsets.only(top: 30, bottom: 40),
                    color: Colors.amber,
                    child: const Center(
                      child: Text('You have fetched all of the content'),
                    ),
                  ),
              ],
            ),
    );
  }
}
