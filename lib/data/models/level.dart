import 'arrow.dart';

enum OrphanDotType { up, down, left, right, neutral }

class OrphanDot {
  final int row, col;
  final OrphanDotType type;
  const OrphanDot({required this.row, required this.col, required this.type});

  String get key => '$row,$col';

  Map<String, dynamic> toJson() => {
    'row': row,
    'col': col,
    'type': type.index,
  };

  factory OrphanDot.fromJson(Map<String, dynamic> json) => OrphanDot(
    row: json['row'] as int,
    col: json['col'] as int,
    type: OrphanDotType.values[json['type'] as int],
  );
}

enum MaskShape {
  
  square,
  circle,
  
  heart,
  star,
  diamond,
  hexagon,
  blob,
  
  cat,
  dog,
  frog,
  fox,
  tiger,
  panda,
  fish,
  bird,
  butterfly,
  
  guitar,
  tree,
  house,
  crown,
}

class LevelModel {
  final int levelNumber;
  final int gridSize;
  final List<ArrowModel> arrows;
  final MaskShape maskShape;
  final Set<String> mask;
  final List<OrphanDot> orphanDots;

  LevelModel({
    required this.levelNumber,
    required this.gridSize,
    required this.arrows,
    this.maskShape = MaskShape.square,
    this.mask = const {},
    this.orphanDots = const [],
  });

  LevelModel copyWith({
    int? levelNumber,
    int? gridSize,
    List<ArrowModel>? arrows,
    MaskShape? maskShape,
    Set<String>? mask,
    List<OrphanDot>? orphanDots,
  }) => LevelModel(
    levelNumber: levelNumber ?? this.levelNumber,
    gridSize: gridSize ?? this.gridSize,
    arrows: arrows ?? this.arrows,
    maskShape: maskShape ?? this.maskShape,
    mask: mask ?? this.mask,
    orphanDots: orphanDots ?? this.orphanDots,
  );

  Map<String, dynamic> toJson() => {
    'levelNumber': levelNumber,
    'gridSize': gridSize,
    'arrows': arrows.map((a) => a.toJson()).toList(),
    'maskShape': maskShape.index,
    'mask': mask.toList(),
    'orphanDots': orphanDots.map((d) => d.toJson()).toList(),
  };

  factory LevelModel.fromJson(Map<String, dynamic> json) => LevelModel(
    levelNumber: json['levelNumber'] as int,
    gridSize: json['gridSize'] as int,
    arrows: (json['arrows'] as List)
        .map((a) => ArrowModel.fromJson(a as Map<String, dynamic>))
        .toList(),
    maskShape: json['maskShape'] != null
        ? MaskShape.values[(json['maskShape'] as int)
            .clamp(0, MaskShape.values.length - 1)]
        : MaskShape.square,
    mask: json['mask'] != null
        ? Set<String>.from((json['mask'] as List).cast<String>())
        : const {},
    orphanDots: json['orphanDots'] != null
        ? (json['orphanDots'] as List)
            .map((d) => OrphanDot.fromJson(d as Map<String, dynamic>))
            .toList()
        : const [],
  );
}