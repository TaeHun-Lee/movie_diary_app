import 'package:flutter/material.dart';
import 'package:movie_diary_app/component/movie_detail_modal.dart';
import 'package:movie_diary_app/data/movie.dart';
import 'package:movie_diary_app/services/api_service.dart';

class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key});

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Movie> _movies = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _searchMovies() async {
    if (_searchController.text.isEmpty) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final movies = await ApiService.searchMovies(_searchController.text);
      setState(() {
        _movies = movies;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('영화 검색')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '영화 제목',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchMovies,
                ),
              ),
              onSubmitted: (_) => _searchMovies(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : ListView.builder(
                      itemCount: _movies.length,
                      itemBuilder: (context, index) {
                        final movie = _movies[index];
                        return Card(
                          child: ListTile(
                            leading: movie.posterUrl != null
                                ? Image.network(movie.posterUrl!)
                                : Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey,
                                    child: const Center(
                                      child: Text(
                                        'No Poster',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                  ),
                                                            title: Text(movie.title),
                                                            subtitle: Text(movie.director),
                                                            onTap: () {
                                                              showMovieDetailModal(context, movie);
                                                            },
                                                          ),
                                                        );                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
