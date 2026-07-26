import 'dart:math';

enum ArrowDirection {
  up,
  down,
  left,
  right;

  List<int> get delta {
    switch (this) {
      case ArrowDirection.up:    return [-1, 0];
      case ArrowDirection.down:  return [1, 0];
      case ArrowDirection.left:  return [0, -1];
      case ArrowDirection.right: return [0, 1];
    }
  }

  double get rotationRadians {
    switch (this) {
      case ArrowDirection.right: return 0;
      case ArrowDirection.down:  return pi / 2;
      case ArrowDirection.left:  return pi;
      case ArrowDirection.up:    return -pi / 2;
    }
  }

  ArrowDirection get opposite {
    switch (this) {
      case ArrowDirection.up:    return ArrowDirection.down;
      case ArrowDirection.down:  return ArrowDirection.up;
      case ArrowDirection.left:  return ArrowDirection.right;
      case ArrowDirection.right: return ArrowDirection.left;
    }
  }

  ArrowDirection get turnRight {
    switch (this) {
      case ArrowDirection.up:    return ArrowDirection.right;
      case ArrowDirection.right: return ArrowDirection.down;
      case ArrowDirection.down:  return ArrowDirection.left;
      case ArrowDirection.left:  return ArrowDirection.up;
    }
  }

  ArrowDirection get turnLeft {
    switch (this) {
      case ArrowDirection.up:    return ArrowDirection.left;
      case ArrowDirection.left:  return ArrowDirection.down;
      case ArrowDirection.down:  return ArrowDirection.right;
      case ArrowDirection.right: return ArrowDirection.up;
    }
  }
}

enum ArrowState {
  idle,       
  sliding,    
  blocked,    
}

class ArrowModel {
  final String id;
  int row;
  int col;
  ArrowDirection direction;
  ArrowState state;

  final List<List<int>> path;

  ArrowModel({
    required this.id,
    required this.row,
    required this.col,
    required this.direction,
    this.state = ArrowState.idle,
    List<List<int>>? path,
  }) : path = path ?? [[row, col]];

  ArrowModel copyWith({
    String? id,
    int? row,
    int? col,
    ArrowDirection? direction,
    ArrowState? state,
    List<List<int>>? path,
  }) {
    return ArrowModel(
      id: id ?? this.id,
      row: row ?? this.row,
      col: col ?? this.col,
      direction: direction ?? this.direction,
      state: state ?? this.state,
      path: path ?? this.path,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'row': row,
    'col': col,
    'direction': direction.index,
    'state': state.index,
    'path': path,
  };

  factory ArrowModel.fromJson(Map<String, dynamic> json) => ArrowModel(
    id: json['id'] as String,
    row: json['row'] as int,
    col: json['col'] as int,
    direction: ArrowDirection.values[json['direction'] as int],
    state: ArrowState.values[json['state'] as int],
    path: (json['path'] as List<dynamic>?)
        ?.map((e) => (e as List<dynamic>).map((x) => x as int).toList())
        .toList(),
  );

  @override
  String toString() => 'Arrow($id @ [$row,$col] ${direction.name}, path: $path)';
}