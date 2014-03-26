part of tsp;

class AntColonyOptimization extends TSPAlgorithm {
  int _size;
  List<List<double>> _dist;   // Distances matrix
  List<List<int>> _nnList;    // Nearest neighbor list
  List<List<double>> _pheromone;
  List<List<double>> _choiceInfo;

  AlgorithmResult solve(List<List<double>> dist) {
    _dist = dist;
    _initializeData();
    while (!_terminate) {
      _constructSolutions();
      _LocalSearch();
      _updateStatistics();
      _updatePheromoneTrails();
    }
  }

  void _initializeData() {
    _size = _dist.length;
    _computeNearestNeighborLists();
    /*
    ReadInstance
    ComputeDistances
    ComputeNearestNeighborLists
    ComputeChoiceInformation
    InitializeAnts
    InitializeParameters
    InitializeStatistics
     */
  }

  void _computeNearestNeighborLists() {
    _nnList = <List<int>>[];
    for (int i = 0; i < _size; ++i) {
      List<Tuple<int, double>> list = <Tuple<int, double>>[];
      for (int j = 0; j < _size; ++j) {
        list.add(new Tuple(j, _dist[i][j]));
      }

      list.sort((a, b) => Comparable.compare(a.item2, b.item2));
      List<int> nnList = <int>[];
      for (int j = 0; j < _size; ++j) {
        nnList.add(list[j].item1);
      }
      _nnList.add(nnList);
    }
  }

  bool get _terminate => true;

  void _constructSolutions() {}

  void _LocalSearch() {}

  void _updateStatistics() {}

  void _updatePheromoneTrails() {}
}

class Tuple<T1, T2> {
  final T1 item1;
  final T2 item2;

  const Tuple(this.item1, this.item2);
}