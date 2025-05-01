import 'dart:math' as math;

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:luddo_2/size_config.dart';

class NewTeenPatti extends StatefulWidget {
  const NewTeenPatti({Key? key}) : super(key: key);

  @override
  State<NewTeenPatti> createState() => _NewTeenPattiState();
}

int selectedPlayer = 1;
String? selectedChipText;
int selectedChipIndex = 0;
int? winningPlayerIndex;
late AnimationController _cardAnimationController;
late Animation<Offset> _cardSlideUpAnimation;
bool _isResettingCards = false;
List<HandEvaluation> playerHandEvaluations = [];
List<List<Map<String, dynamic>>> playerChips = [[], [], []];
bool isEvaluating = false;
List<int> playerWins = [0, 0, 0]; // Track wins for each player
int totalMatches = 0; // Track total matches played
bool get allPlayersHaveBet {
  return playerChips.every((playerChipList) => playerChipList.isNotEmpty);
}

enum HandRank { highCard, pair, flush, sequence, straightFlush, threeOfAKind }

class HandEvaluation {
  final HandRank rank;
  final List<int> kickers; // For tie-breaking

  HandEvaluation(this.rank, this.kickers);
}

HandEvaluation evaluateHand(List<String> cards) {
  // Extract ranks and suits
  final ranks =
      cards.map((card) {
          final rank = card.substring(0, card.length - 1);
          return rank == 'A'
              ? 14
              : rank == 'K'
              ? 13
              : rank == 'Q'
              ? 12
              : rank == 'J'
              ? 11
              : rank == '0'
              ? 10
              : int.parse(rank);
        }).toList()
        ..sort((a, b) => b.compareTo(a)); // Sort descending

  final suits = cards.map((card) => card.substring(card.length - 1)).toList();

  // Check for three of a kind
  if (ranks[0] == ranks[1] && ranks[1] == ranks[2]) {
    return HandEvaluation(HandRank.threeOfAKind, ranks);
  }

  // Check for straight flush
  final isFlush = suits[0] == suits[1] && suits[1] == suits[2];
  final isStraight =
      (ranks[0] - 1 == ranks[1] && ranks[1] - 1 == ranks[2]) ||
      // Special case for A-2-3
      (ranks[0] == 14 && ranks[1] == 3 && ranks[2] == 2);

  if (isFlush && isStraight) {
    return HandEvaluation(HandRank.straightFlush, ranks);
  }

  // Check for sequence
  if (isStraight) {
    return HandEvaluation(HandRank.sequence, ranks);
  }

  // Check for flush
  if (isFlush) {
    return HandEvaluation(HandRank.flush, ranks);
  }

  // Check for pair
  if (ranks[0] == ranks[1] || ranks[1] == ranks[2]) {
    final pairValue = ranks[0] == ranks[1] ? ranks[0] : ranks[1];
    final kicker = ranks[0] == ranks[1] ? ranks[2] : ranks[0];
    return HandEvaluation(HandRank.pair, [pairValue, kicker]);
  }

  // High card
  return HandEvaluation(HandRank.highCard, ranks);
}

String handRankToString(HandRank rank) {
  switch (rank) {
    case HandRank.threeOfAKind:
      return 'Three of a Kind';
    case HandRank.straightFlush:
      return 'Straight Flush';
    case HandRank.sequence:
      return 'Sequence';
    case HandRank.flush:
      return 'Flush';
    case HandRank.pair:
      return 'Pair';
    case HandRank.highCard:
      return 'High Card';
  }
}

bool _isPlayButtonPressed = false;

class _NewTeenPattiState extends State<NewTeenPatti>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _floatController;
  late AnimationController _confettiController;
  late AnimationController _winTextController;
  late AnimationController _coinShowerController;
  List<Offset> movingChips = [];
  List<int> movingChipValues = [];
  List<Offset> movingTargets = [];
  List<double> movingChipScales = [];
  AnimationController? _chipMoveController;
  late Animation<double> _chipMoveAnimation;
  List<bool> showCardFrontForPlayers = [false, false, false];

  bool _showCardFront = false;
  final List<String> allCards = [
    'AS',
    '2S',
    '3S',
    '4S',
    '5S',
    '6S',
    '7S',
    '8S',
    '9S',
    '0S',
    'JS',
    'QS',
    'KS',
    'AH',
    '2H',
    '3H',
    '4H',
    '5H',
    '6H',
    '7H',
    '8H',
    '9H',
    '0H',
    'JH',
    'QH',
    'KH',
    'AD',
    '2D',
    '3D',
    '4D',
    '5D',
    '6D',
    '7D',
    '8D',
    '9D',
    '0D',
    'JD',
    'QD',
    'KD',
    'AC',
    '2C',
    '3C',
    '4C',
    '5C',
    '6C',
    '7C',
    '8C',
    '9C',
    '0C',
    'JC',
    'QC',
    'KC',
  ];
  String backCardImage = 'https://deckofcardsapi.com/static/img/back.png';
  List<List<String>> frontCardImagesForPlayers = [
    ['', '', ''],
    ['', '', ''],
    ['', '', ''],
  ];

  @override
  void initState() {
    super.initState();

    // Subtle pulsing animation for glow effects
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _cardSlideUpAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -2), // slide upward
    ).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Color shifting glow animation
    _glowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // Floating animation for images
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _confettiController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _winTextController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _coinShowerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _chipMoveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _chipMoveAnimation = CurvedAnimation(
      parent: _chipMoveController!,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _floatController.dispose();
    _confettiController.dispose();
    _winTextController.dispose();
    _coinShowerController.dispose();
    _cardAnimationController.dispose();

    super.dispose();
  }

  void _transferChipsToWinner(int winnerIndex) {
    // Get the positions of all player containers
    final playerPositions = List.generate(3, (index) {
      return Offset(
        100 + index * 120, // Adjust based on your layout
        200, // Adjust based on your layout
      );
    });

    // Collect all chips from other players
    List<Offset> startPositions = [];
    List<Map<String, dynamic>> chipData = [];
    List<Offset> targetPositions = [];

    for (int i = 0; i < playerChips.length; i++) {
      if (i != winnerIndex) {
        // Calculate screen positions for each chip
        for (int j = 0; j < playerChips[i].length; j++) {
          startPositions.add(
            Offset(
              playerPositions[i].dx + 30, // Offset within player container
              playerPositions[i].dy - 20 - j * 5, // Stack chips vertically
            ),
          );
          targetPositions.add(
            Offset(
              playerPositions[winnerIndex].dx + 30,
              playerPositions[winnerIndex].dy - 20,
            ),
          );
          chipData.add(playerChips[i][j]);
        }
        playerChips[i].clear();
      }
    }

    setState(() {
      movingChips = startPositions;
      movingChipValues =
          chipData
              .map((data) => data['value'] as int)
              .toList(); // Extract values
      movingTargets = targetPositions;
    });

    _chipMoveController!.forward().then((_) {
      setState(() {
        playerChips[winnerIndex].addAll(chipData);
        movingChips = [];
        movingChipValues = [];
        movingTargets = [];
      });
    });
  }

  var height, width;
  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    SizeConfig.init(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0524), Color(0xFF1A0B3D)],
            stops: [0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // _buildTopNavBar(),
              _buildRoundIndicator(),
              _buildScoreCard(screenWidth),

              _buildPlayerPositions(isSmallScreen),

              _buildPlayerIndicators(isSmallScreen),

              _buildBottomActionBar(screenWidth, isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavBar() {
    double blockW = SizeConfig.blockWidth;
    double blockH = SizeConfig.blockHeight;
    return Padding(
      padding: EdgeInsets.all(blockW * 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left buttons
          Row(
            children: [
              _buildCustomCircleButton(
                Icons.arrow_back,
                Colors.white.withOpacity(0.7),
              ),
              SizedBox(width: blockW * 2),
              _buildCustomCircleButton(
                Icons.music_note,
                Colors.white.withOpacity(0.7),
              ),
              SizedBox(width: blockW * 2),
              _buildCustomCircleButton(
                Icons.help_outline,
                Colors.white.withOpacity(0.7),
              ),
            ],
          ),

          // Right NEW button
          _buildGlassmorphicContainer(
            width: blockW * 24, // ~90 on 375dp width
            height: blockH * 5, // ~35 on 700dp height
            borderRadius: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: blockW * 3.5,
                  ),
                ),
                SizedBox(width: blockW * 2),
                Container(
                  width: blockW * 6,
                  height: blockW * 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFC600)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    Icons.monetization_on,
                    color: Colors.amber,
                    size: blockW * 4.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCircleButton(IconData icon, Color iconColor) {
    double blockW = SizeConfig.blockWidth;

    return Container(
      width: blockW * 11,
      height: blockW * 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6A35D1), Color(0xFF4527A0)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            offset: const Offset(-2, -2),
            blurRadius: 5,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(2, 2),
            blurRadius: 5,
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: Icon(icon, color: iconColor, size: blockW * 4),
    );
  }

  Widget _buildRoundIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, top: 1.0, bottom: 0.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFFE1BEE7)],
            ).createShader(bounds);
          },
          child: const Text(
            'Round: 2133',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(double screenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // The main score card with custom shadow
          Column(
            children: [
              _buildTopScoreGlassContainer(),
              _buildGlassyScoreContainer(screenWidth, _buildScoreRow),
            ],
          ),

          // Crown positioned above the card
          Positioned(
            top: -25,
            child: Container(
              width: 50,
              height: 35,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://png.pngtree.com/png-clipart/20220125/ourmid/pngtree-3d-texture-golden-crown-png-image_4364634.png',
                  ),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String title, String points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            points,
            style: TextStyle(
              color:
                  points.contains('+') ? Colors.greenAccent : Colors.redAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 3.0,
                  color:
                      points.contains('+')
                          ? Colors.green.withOpacity(0.5)
                          : Colors.red.withOpacity(0.5),
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerPositions(bool isSmallScreen) {
    double blockW = SizeConfig.blockWidth;
    double blockH = SizeConfig.blockHeight;

    return SizedBox(
      height: isSmallScreen ? blockH * 18 : blockH * 30,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: blockW * 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                _buildTopGlassContainer('assets/drink.png'),
                _buildPlayerPosition(
                  'Orange Drink',
                  'Pot: 20',
                  'Mine: 0',
                  true,
                  isSmallScreen,
                  0,
                ),
              ],
            ),
            Column(
              children: [
                _buildTopGlassContainer('assets/drinkred.png'),
                _buildPlayerPosition(
                  'Orange Drink',
                  'Pot: 20',
                  'Mine: 0',
                  true,
                  isSmallScreen,
                  1,
                ),
              ],
            ),
            Column(
              children: [
                _buildTopGlassContainer('assets/mug.png'),
                _buildPlayerPosition(
                  'Orange Drink',
                  'Pot: 20',
                  'Mine: 0',
                  true,
                  isSmallScreen,
                  2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopGlassContainer(String imagePath) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          height: 35,
          width: 60,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(70)),
            image: DecorationImage(image: AssetImage(imagePath)),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(
                  0.3 + _pulseController.value * 0.1,
                ),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(70)),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(
                      0.2 + _pulseController.value * 0.05,
                    ),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(70),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: CustomPaint(
                painter: GlassReflectionPainter(_pulseController.value),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopScoreGlassContainer() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          height: 50,
          width: 140,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(
                  0.3 + _pulseController.value * 0.1,
                ),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(70)),
            child: Container(
              decoration: BoxDecoration(
                // image: DecorationImage(image: AssetImage('assets/crownn.png')),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(
                      0.2 + _pulseController.value * 0.05,
                    ),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(70),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Image(
                height: 30,
                width: 30,
                image: AssetImage('assets/crown2.png'),
              ),
              // child: CustomPaint(
              //   painter: GlassReflectionPainter(_pulseController.value),
              // ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerPosition(
    String drinkType,
    String pot,
    String mine,
    bool active,
    bool isSmallScreen,
    int positionIndex,
  ) {
    final isWinner = winningPlayerIndex == positionIndex;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _floatController]),
      builder: (context, child) {
        final yOffset = math.sin(_floatController.value * math.pi * 2) * 3;
        final glowIntensity =
            isWinner ? 0.5 + _pulseController.value * 0.3 : 0.3;
        if (movingChips.isNotEmpty && winningPlayerIndex != null) {
          final winnerPos = Offset(
            100 +
                winningPlayerIndex! * 120, // Adjust based on winner position x
            200, // Adjust based on winner position y
          );

          return Positioned.fill(
            child: CustomPaint(
              painter: MovingChipsPainter(
                positions: movingChips,
                values: movingChipValues,
                animation: _chipMoveAnimation,
                target: winnerPos,
              ),
            ),
          );
        }

        return Stack(
          clipBehavior: Clip.none, // Important for confetti overflow
          children: [
            // Winner effects layer
            if (isWinner) ...[
              // 3D Rotating coins effect
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _coinShowerController,
                    builder: (context, child) {
                      return _coinShowerController.value > 0
                          ? CustomPaint(
                            painter: CoinShowerPainter(
                              progress: _coinShowerController.value,
                              count: 15,
                            ),
                          )
                          : const SizedBox.shrink();
                    },
                  ),
                ),
              ),

              // Confetti effect
              Positioned.fill(
                left: -100,
                right: -100,
                top: -50,
                bottom: -50,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _confettiController,
                    builder: (context, child) {
                      return _confettiController.value > 0
                          ? CustomPaint(
                            painter: ConfettiPainter(
                              progress: _confettiController.value,
                              density: 40,
                            ),
                          )
                          : const SizedBox.shrink();
                    },
                  ),
                ),
              ),

              // 3D Winner text effect
              Positioned(
                top: -50,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _winTextController,
                  builder: (context, child) {
                    final scale = 0.7 + 0.7 * _winTextController.value;
                    final opacity = math.min(1.0, _winTextController.value * 2);

                    return _winTextController.value > 0
                        ? Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity,
                            child: Center(
                              child: Transform(
                                alignment: Alignment.center,
                                transform:
                                    Matrix4.identity()
                                      ..setEntry(3, 2, 0.001) // perspective
                                      ..rotateX(
                                        0.1 *
                                            math.sin(
                                              _winTextController.value *
                                                  math.pi *
                                                  2,
                                            ),
                                      )
                                      ..rotateY(
                                        0.1 *
                                            math.cos(
                                              _winTextController.value *
                                                  math.pi,
                                            ),
                                      ),
                                child: ShaderMask(
                                  shaderCallback:
                                      (bounds) => LinearGradient(
                                        colors: [
                                          Colors.orange.shade300,
                                          Colors.yellow.shade500,
                                          Colors.amber.shade700,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                  child: Text(
                                    'WINNER!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: isSmallScreen ? 18 : 22,
                                      letterSpacing: 1.5,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.orange.shade700
                                              .withOpacity(0.8),
                                          blurRadius: 12,
                                          offset: const Offset(0, 3),
                                        ),
                                        Shadow(
                                          color: Colors.amber.shade300,
                                          blurRadius: 4,
                                          offset: const Offset(0, -1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        : const SizedBox.shrink();
                  },
                ),
              ),

              // Golden rays background
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: CustomPaint(
                          painter: GoldenRaysPainter(
                            pulseValue: _pulseController.value,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            // Main player container (existing code)
            Container(
              width: isSmallScreen ? 110 : 120,
              height: isSmallScreen ? 129 : 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  if (isWinner)
                    BoxShadow(
                      color: Colors.yellow.withOpacity(glowIntensity),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  BoxShadow(
                    color: Colors.purple.withOpacity(
                      0.3 + _pulseController.value * 0.1,
                    ),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(
                            0.2 + _pulseController.value * 0.05,
                          ),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color:
                            isWinner
                                ? Colors.amber.withOpacity(
                                  0.6 + 0.4 * _pulseController.value,
                                )
                                : Colors.white.withOpacity(0.4),
                        width: isWinner ? 2.0 : 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          bottom:
                              isSmallScreen
                                  ? 30
                                  : 40, // Adjust position as needed
                          left: 0,
                          right: 0,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: -15,
                            children:
                                playerChips[positionIndex].map((chipData) {
                                  return Transform.translate(
                                    offset: Offset(0, -10),
                                    child: Container(
                                      width: isSmallScreen ? 20 : 25,
                                      height: isSmallScreen ? 20 : 25,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            chipData['color'], // Use the stored color
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 3,
                                            offset: Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          chipData['text'], // Use the stored text
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isSmallScreen ? 8 : 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),

                        Positioned.fill(
                          child: CustomPaint(
                            painter: GlassReflectionPainter(
                              _pulseController.value,
                            ),
                          ),
                        ),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.all(
                                SizeConfig.blockWidth * 3,
                              ),
                              child: Transform.translate(
                                offset: Offset(0, yOffset),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: SizeConfig.blockWidth * 16,
                                      height: SizeConfig.blockHeight * 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isWinner
                                                    ? Colors.amber
                                                    : Colors.purple)
                                                .withOpacity(
                                                  0.3 +
                                                      _pulseController.value *
                                                          0.2,
                                                ),
                                            blurRadius: 20,
                                            spreadRadius:
                                                5 + _pulseController.value * 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Transform.rotate(
                                      angle:
                                          math.sin(
                                            _floatController.value * math.pi,
                                          ) *
                                          0.05,
                                      child: SizedBox(
                                        width: SizeConfig.blockWidth * 19,
                                        height: SizeConfig.blockHeight * 6.5,
                                        child: Stack(
                                          children: List.generate(3, (index) {
                                            double leftOffset = 0;
                                            if (index == 1)
                                              leftOffset =
                                                  30 * 0.8; // 20% overlap
                                            if (index == 2)
                                              leftOffset =
                                                  30 * 0.8 +
                                                  30 * 0.7; // 30% over 2nd
                                            return Positioned(
                                              left: leftOffset,
                                              child: SlideTransition(
                                                position:
                                                    _isResettingCards
                                                        ? _cardSlideUpAnimation
                                                        : AlwaysStoppedAnimation(
                                                          Offset.zero,
                                                        ),
                                                child: AnimatedSwitcher(
                                                  duration: const Duration(
                                                    milliseconds: 400,
                                                  ),
                                                  transitionBuilder: (
                                                    child,
                                                    animation,
                                                  ) {
                                                    final rotate = Tween(
                                                      begin: math.pi,
                                                      end: 0.0,
                                                    ).animate(animation);
                                                    return AnimatedBuilder(
                                                      animation: rotate,
                                                      child: child,
                                                      builder: (
                                                        context,
                                                        child,
                                                      ) {
                                                        final isUnder =
                                                            (ValueKey(
                                                                  _showCardFront,
                                                                ) !=
                                                                child!.key);
                                                        var tilt =
                                                            ((animation.value -
                                                                        0.5)
                                                                    .abs() -
                                                                0.5) *
                                                            0.003;
                                                        tilt *=
                                                            isUnder
                                                                ? -1.0
                                                                : 1.0;
                                                        final value =
                                                            isUnder
                                                                ? math.min(
                                                                  rotate.value,
                                                                  math.pi / 2,
                                                                )
                                                                : rotate.value;
                                                        return Transform(
                                                          transform:
                                                              Matrix4.rotationY(
                                                                value,
                                                              )..setEntry(
                                                                3,
                                                                0,
                                                                tilt,
                                                              ),
                                                          alignment:
                                                              Alignment.center,
                                                          child: child,
                                                        );
                                                      },
                                                    );
                                                  },
                                                  child: Image.network(
                                                    showCardFrontForPlayers[positionIndex]
                                                        ? frontCardImagesForPlayers[positionIndex][index]
                                                        : backCardImage,
                                                    key: ValueKey(
                                                      showCardFrontForPlayers[positionIndex],
                                                    ),
                                                    width:
                                                        SizeConfig.blockWidth *
                                                        10,
                                                    height:
                                                        SizeConfig.blockHeight *
                                                        5,
                                                    fit: BoxFit.fill,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ClipRRect(
                            //   borderRadius: const BorderRadius.only(
                            //     bottomLeft: Radius.circular(15),
                            //     bottomRight: Radius.circular(15),
                            //   ),
                            //   child: BackdropFilter(
                            //     filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                            //     child: Container(
                            //       decoration: BoxDecoration(
                            //         gradient: LinearGradient(
                            //           begin: Alignment.topLeft,
                            //           end: Alignment.bottomRight,
                            //           colors: [
                            //             Colors.white.withOpacity(0.2),
                            //             Colors.white.withOpacity(0.05),
                            //           ],
                            //         ),
                            //         border: Border(
                            //           top: BorderSide(
                            //             color: Colors.white.withOpacity(0.4),
                            //             width: 1,
                            //           ),
                            //         ),
                            //       ),
                            //       padding: EdgeInsets.symmetric(
                            //         vertical: isSmallScreen ? 5 : 7,
                            //       ),
                            //       child: Column(
                            //         children: [
                            //           Text(
                            //             pot,
                            //             style: TextStyle(
                            //               color: Colors.white,
                            //               fontSize: SizeConfig.blockWidth * 2.0,
                            //               fontWeight: FontWeight.w500,
                            //             ),
                            //           ),

                            //           Row(
                            //             mainAxisAlignment:
                            //                 MainAxisAlignment.center,
                            //             children: [
                            Text(
                              mine,
                              style: TextStyle(
                                color: isWinner ? Colors.amber : Colors.white,
                                fontSize: SizeConfig.blockWidth * 2.1,

                                fontWeight:
                                    isWinner
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                shadows: [
                                  Shadow(
                                    color: (isWinner
                                            ? Colors.amber
                                            : Colors.white)
                                        .withOpacity(0.6),
                                    blurRadius: 3 + _pulseController.value * 3,
                                  ),
                                ],
                              ),
                            ),
                            //             ],
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //   ),
                            // ),
                            Text(
                              pot,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: SizeConfig.blockWidth * 2.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Hand rank display
            if (showCardFrontForPlayers[positionIndex])
              Positioned(
                top: -10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.blockWidth * 2.0,
                      vertical: SizeConfig.blockHeight * 0.5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          positionIndex == winningPlayerIndex
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            positionIndex == winningPlayerIndex
                                ? Colors.yellow.withOpacity(0.8)
                                : Colors.white.withOpacity(0.3),
                        width: positionIndex == winningPlayerIndex ? 2 : 1,
                      ),
                      // boxShadow:
                      //     positionIndex == winningPlayerIndex
                      //         ? [
                      //           BoxShadow(
                      //             color: Colors.amber.withOpacity(0.5),
                      //             blurRadius: 8,
                      //             spreadRadius: 2,
                      //           ),
                      //         ]
                      //         : null,
                    ),
                    child: Text(
                      handRankToString(
                        playerHandEvaluations[positionIndex].rank,
                      ),
                      style: TextStyle(
                        color:
                            positionIndex == winningPlayerIndex
                                ? Colors.black
                                : Colors.white,
                        fontSize: isSmallScreen ? 8 : 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // Trophy icon for winner
            if (isWinner)
              Positioned(
                right: -10,
                top: -10,
                child: AnimatedBuilder(
                  animation: _winTextController,
                  builder: (context, child) {
                    final scale =
                        0.7 +
                        0.3 * math.sin(_winTextController.value * math.pi);

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amber.shade600,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.7),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Color _getChipColor(int value) {
    if (value >= 10000) return Colors.orange;
    if (value >= 1000) return Colors.deepOrange;
    if (value >= 100) return Colors.purpleAccent;
    if (value >= 10) return Colors.black;
    if (value == 4) return Colors.amberAccent;
    return Colors.orange;
  }

  Widget _buildPlayerIndicators(bool isSmallScreen) {
    double blockW = SizeConfig.blockWidth;
    double blockH = SizeConfig.blockHeight;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: blockH * 2.5,
        horizontal: blockW * 3,
      ),
      child: Row(
        children: [
          SizedBox(width: isSmallScreen ? blockW * 28 : blockW * 35),
          _buildPlayerIndicator('1', selectedPlayer == 1, () {
            setState(() => selectedPlayer = 1);
          }, isSmallScreen),
          SizedBox(width: isSmallScreen ? blockW * 2 : blockW * 4),
          _buildPlayerIndicator('2', selectedPlayer == 2, () {
            setState(() => selectedPlayer = 2);
          }, isSmallScreen),
          SizedBox(width: isSmallScreen ? blockW * 2 : blockW * 4),
          _buildPlayerIndicator('3', selectedPlayer == 3, () {
            setState(() => selectedPlayer = 3);
          }, isSmallScreen),
          SizedBox(width: isSmallScreen ? blockW * 4 : blockW * 8),
          // _buildGlassmorphicContainer(
          //   width: isSmallScreen ? blockW * 12 : blockW * 14,
          //   height: isSmallScreen ? blockH * 5 : blockH * 6,
          //   borderRadius: 18,
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       Icon(
          //         Icons.groups,
          //         color: Colors.white,
          //         size: isSmallScreen ? blockW * 3 : blockW * 3.5,
          //       ),
          //       SizedBox(height: isSmallScreen ? blockH * 0.5 : blockH * 0.7),
          //       Text(
          //         'players',
          //         style: TextStyle(
          //           color: Colors.white,
          //           fontSize: isSmallScreen ? blockW * 2.5 : blockW * 3,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildPlayerIndicator(
    String number,
    bool isSelected,
    VoidCallback onTap,
    bool isSmallScreen,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isSmallScreen ? 40 : 50,
          height: isSmallScreen ? 30 : 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient:
                isSelected
                    ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                    )
                    : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6A35D1), Color(0xFF4527A0)],
                    ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: Colors.purpleAccent.withOpacity(0.6),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(2, 2),
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        offset: const Offset(-2, -2),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
            border: Border.all(
              color: Colors.white.withOpacity(isSelected ? 0.6 : 0.3),
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Text(
            number,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: isSmallScreen ? 12 : 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(double screenWidth, bool isSmallScreen) {
    double blockW = SizeConfig.blockWidth;
    double blockH = SizeConfig.blockHeight;

    return ClipPath(
      clipper: BottomBarClipper(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A0B3D).withOpacity(0.9),
              const Color(0xFF0F0524).withOpacity(0.95),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(0, -4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            blockW * 3,
            blockH * 2,
            blockW * 3,
            blockH * 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //   children: [
              //     _buildActionButton('SILENT', isSmallScreen),
              //     _buildActionButton('CALL', isSmallScreen),
              //     _buildActionButton('Good By..', isSmallScreen),
              //   ],
              // ),
              SizedBox(height: isSmallScreen ? blockH * 1 : blockH * 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    width: SizeConfig.blockWidth * 20,
                    height: SizeConfig.blockHeight * 2,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.paid, color: Colors.amber, size: 20),
                        SizedBox(width: SizeConfig.blockWidth * 5),
                        Text(
                          '2',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),

                  _buildChip('10', Colors.black, () {}, isSmallScreen),
                  _buildChip('100%', Colors.purple, () {}, isSmallScreen),
                  _buildChip('1K', Colors.orange, () {}, isSmallScreen),
                  _buildChip('10K', Colors.deepOrange, () {}, isSmallScreen),
                  buildPlayButton(isSmallScreen),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, bool isSmallScreen) {
    return _buildGlassmorphicContainer(
      width: isSmallScreen ? 80 : 100,
      height: isSmallScreen ? 27 : 20,
      borderRadius: 18,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 10 : 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildChip(
    String text,
    Color color,
    VoidCallback onTap,
    bool isSmallScreen,
  ) {
    final bool isSelected = selectedChipText == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedChipText = text;
          playerChips[selectedPlayer - 1].add({
            'value': int.tryParse(text.replaceAll('%', '')) ?? 0,
            'text': text,
            'color': color,
          });
        });
        onTap();

        // Remove selection after short delay for pulse effect
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() => selectedChipText = null);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutBack,
        width: isSelected ? 48 : 40,
        height: isSelected ? 41 : 37,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
          ),
          border: Border.all(
            color:
                isSelected
                    ? Colors.yellowAccent
                    : Colors.white.withOpacity(0.4),
            width: isSelected ? 3.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              offset: const Offset(2, 2),
              blurRadius: 5,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize:
                isSmallScreen
                    ? (text.length > 2 ? 10 : 12)
                    : (text.length > 2 ? 12 : 14),
          ),
        ),
      ),
    );
  }

  Widget buildPlayButton(bool isSmallScreen) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPlayButtonPressed = true),
      onTapUp: (_) => setState(() => _isPlayButtonPressed = false),
      onTapCancel: () => setState(() => _isPlayButtonPressed = false),
      onTap: () async {
        if (isEvaluating) return;

        if (showCardFrontForPlayers.any((show) => show)) {
          setState(() {
            _isResettingCards = true;
          });

          await _cardAnimationController.forward();
          await Future.delayed(
            Duration(milliseconds: 200),
          ); // Allow animation time

          setState(() {
            _isResettingCards = false;
            _cardAnimationController.reset();
            showCardFrontForPlayers = [false, false, false];
            winningPlayerIndex = null;
            playerChips = [[], [], []];
            movingChips = [];
            movingChipValues = [];
          });

          return;
        }

        if (!allPlayersHaveBet) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All players must place at least one bet!'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        setState(() {
          isEvaluating = true;
          winningPlayerIndex = null;
        });

        // If cards are already shown, hide them and reset
        if (showCardFrontForPlayers.any((show) => show)) {
          setState(() {
            showCardFrontForPlayers = [false, false, false];
            winningPlayerIndex = null;
            playerChips = [[], [], []]; // Reset chips when resetting game
          });
          return;
        }

        setState(() {
          isEvaluating = true;
          winningPlayerIndex = null;
        });

        final rand = math.Random();

        // Generate all players' front cards first
        for (int i = 0; i < 3; i++) {
          frontCardImagesForPlayers[i] = List.generate(3, (_) {
            final card = allCards[rand.nextInt(allCards.length)];
            return 'https://deckofcardsapi.com/static/img/$card.png';
          });
        }

        // Show all cards at once with animation
        setState(() {
          showCardFrontForPlayers = [true, true, true];
        });

        // Evaluate hands
        playerHandEvaluations =
            frontCardImagesForPlayers.map((playerCards) {
              final cardCodes =
                  playerCards.map((url) {
                    final start = url.lastIndexOf('/') + 1;
                    final end = url.lastIndexOf('.');
                    return url.substring(start, end);
                  }).toList();
              return evaluateHand(cardCodes);
            }).toList();

        // Determine winner with animation
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          winningPlayerIndex = _determineWinner(playerHandEvaluations);
          if (winningPlayerIndex != null) {
            playerWins[winningPlayerIndex!]++;
            totalMatches++;
          }
        });

        // Right after that, add these lines:
        if (winningPlayerIndex != null) {
          // Provide haptic feedback for winner
          HapticFeedback.mediumImpact();

          // Reset and start animations in sequence
          _confettiController.reset();
          _winTextController.reset();
          _coinShowerController.reset();

          Future.delayed(const Duration(milliseconds: 700), () {
            _transferChipsToWinner(winningPlayerIndex!);
          });

          // Start animations with slight delays
          _confettiController.forward();

          Future.delayed(const Duration(milliseconds: 100), () {
            _winTextController.forward().then((_) {
              _winTextController.repeat(reverse: true);
            });
          });

          Future.delayed(const Duration(milliseconds: 200), () {
            _coinShowerController.forward();
          });
        }

        setState(() {
          isEvaluating = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          0,
          _isPlayButtonPressed ? 6 : 0,
          0,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 14 : 19,
          vertical: isSmallScreen ? 6 : 9,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
          ),
          boxShadow:
              _isPlayButtonPressed
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      offset: const Offset(-4, -4),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(6, 6),
                      blurRadius: 12,
                    ),
                  ],
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        ),
        child: Text(
          showCardFrontForPlayers.any((show) => show) ? 'RESET' : 'AGAIN',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 12 : 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            shadows: const [
              Shadow(
                blurRadius: 4.0,
                color: Colors.black26,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphicContainer({
    required double width,
    required double height,
    required double borderRadius,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            offset: const Offset(-4, -4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(4, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: GlassmorphicContainer(
        width: width,
        height: height,
        borderRadius: borderRadius,
        blur: 20,
        alignment: Alignment.center,
        border: 2.5,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.05),
          ],
          stops: const [0.1, 1],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.6),
            Colors.white.withOpacity(0.1),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildGlassyScoreContainer(
    double screenWidth,
    Widget Function(String, String) buildScoreRow,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _floatController]),
      builder: (context, child) {
        return Container(
          width: screenWidth * 0.65,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(
                  0.3 + _pulseController.value * 0.1,
                ),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(
                        0.2 + _pulseController.value * 0.05,
                      ),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GlassReflectionPainter(_pulseController.value),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                      child: Column(
                        children: [
                          buildScoreRow('FLUSH', '+4'),

                          buildScoreRow('STRAIGHT', '+2'),

                          buildScoreRow('STRAIGHT FLUSH', '+10'),

                          buildScoreRow('THREE OF A KIND', '+25'),
                          const Divider(color: Colors.white30, height: 2),
                          Text(
                            '${playerWins[selectedPlayer - 1]} / $totalMatches',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int? _determineWinner(List<HandEvaluation> evaluations) {
    int? bestPlayer;
    HandEvaluation? bestHand;

    for (int i = 0; i < evaluations.length; i++) {
      final current = evaluations[i];

      if (bestHand == null ||
          current.rank.index > bestHand.rank.index ||
          (current.rank == bestHand.rank &&
              _compareKickers(current.kickers, bestHand.kickers) > 0)) {
        bestHand = current;
        bestPlayer = i;
      }
    }

    return bestPlayer;
  }

  int _compareKickers(List<int> a, List<int> b) {
    for (int i = 0; i < math.min(a.length, b.length); i++) {
      final comparison = a[i].compareTo(b[i]);
      if (comparison != 0) return comparison;
    }
    return 0;
  }
}

// Custom clipper for the bottom action bar
class BottomBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final height = size.height;
    final width = size.width;

    path.moveTo(0, 25);
    path.quadraticBezierTo(width * 0.25, 0, width * 0.5, 0);
    path.quadraticBezierTo(width * 0.75, 0, width, 25);
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class GlassReflectionPainter extends CustomPainter {
  final double animationValue;

  GlassReflectionPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Top-left to bottom-right highlight
    final paint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.3 + animationValue * 0.1),
              Colors.white.withOpacity(0.0),
            ],
            stops: const [0.0, 0.3],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path =
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width * 0.4, 0)
          ..lineTo(size.width * 0.2, size.height * 0.4)
          ..lineTo(0, size.height * 0.3)
          ..close();

    canvas.drawPath(path, paint);

    // Bottom highlight (subtle)
    final bottomPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.0),
            ],
            stops: const [0.0, 0.3],
          ).createShader(
            Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3),
          );

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3),
      bottomPaint,
    );
  }

  @override
  bool shouldRepaint(covariant GlassReflectionPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class StarBurstPainter extends CustomPainter {
  final int count;
  final double radius;
  final double pulseValue;

  StarBurstPainter({
    required this.count,
    required this.radius,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.yellow.withOpacity(0.8),
              Colors.orange.withOpacity(0.6),
              Colors.transparent,
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.fill;

    final angle = (2 * math.pi) / count;
    final currentRadius = radius * (0.8 + pulseValue * 0.2);

    for (int i = 0; i < count; i++) {
      final x = center.dx + currentRadius * math.cos(angle * i);
      final y = center.dy + currentRadius * math.sin(angle * i);

      // Draw star lines
      canvas.drawLine(
        center,
        Offset(x, y),
        paint
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke,
      );

      // Draw star points
      canvas.drawCircle(
        Offset(x, y),
        4 + pulseValue * 2,
        paint..style = PaintingStyle.fill,
      );
    }

    // Draw center circle
    canvas.drawCircle(
      center,
      10 + pulseValue * 5,
      paint
        ..shader = null
        ..color = Colors.yellow,
    );
  }

  @override
  bool shouldRepaint(covariant StarBurstPainter oldDelegate) {
    return oldDelegate.count != count ||
        oldDelegate.radius != radius ||
        oldDelegate.pulseValue != pulseValue;
  }
}

class SparklePainter extends CustomPainter {
  final double pulseValue;
  final int density;

  SparklePainter({required this.pulseValue, required this.density});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random();
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    for (int i = 0; i < density; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final radius = 1 + rand.nextDouble() * 3 * pulseValue;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint..color = Colors.white.withOpacity(0.7 * pulseValue),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SparklePainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}

class GoldenRaysPainter extends CustomPainter {
  final double pulseValue;

  GoldenRaysPainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * (0.7 + pulseValue * 0.2);
    final rayCount = 12;

    for (int i = 0; i < rayCount; i++) {
      final angle = (i * 2 * math.pi / rayCount) + (pulseValue * math.pi / 4);
      final startPoint = center;
      final endPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      final paint =
          Paint()
            ..shader = LinearGradient(
              colors: [
                Colors.amber.withOpacity(0.8),
                Colors.amber.withOpacity(0.5),
                Colors.amber.withOpacity(0),
              ],
              stops: [0.0, 0.5, 1.0],
            ).createShader(Rect.fromPoints(startPoint, endPoint))
            ..strokeWidth = 3 + pulseValue * 2
            ..style = PaintingStyle.stroke;

      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GoldenRaysPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  final int density;
  final List<ConfettiPiece> _pieces = [];

  ConfettiPainter({required this.progress, required this.density}) {
    final random = math.Random(42); // Fixed seed for consistency

    if (_pieces.isEmpty) {
      for (int i = 0; i < density; i++) {
        _pieces.add(
          ConfettiPiece(
            x: random.nextDouble() * 200 - 100,
            y: -50 - random.nextDouble() * 100,
            size: 5 + random.nextDouble() * 10,
            color:
                [
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.purple,
                  Colors.orange,
                ][random.nextInt(6)],
            speed: 2 + random.nextDouble() * 3,
            angle: random.nextDouble() * 2 * math.pi,
            rotationSpeed: random.nextDouble() * 0.2 - 0.1,
            horizontalSpeed: random.nextDouble() * 2 - 1,
          ),
        );
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    for (var piece in _pieces) {
      final paint =
          Paint()
            ..color = piece.color.withOpacity(math.max(0, 1 - progress * 0.7));

      final newY = piece.y + piece.speed * progress * size.height;
      final newX =
          centerX +
          piece.x +
          piece.horizontalSpeed * progress * size.width * 0.3;
      final angle = piece.angle + piece.rotationSpeed * progress * 10;

      canvas.save();
      canvas.translate(newX, newY);
      canvas.rotate(angle);

      if (piece.size > 8) {
        // Draw a rectangle for larger pieces
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size / 2,
          ),
          paint,
        );
      } else {
        // Draw a circle for smaller pieces
        canvas.drawCircle(Offset.zero, piece.size / 2, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class ConfettiPiece {
  final double x;
  double y;
  final double size;
  final Color color;
  final double speed;
  final double angle;
  final double rotationSpeed;
  final double horizontalSpeed;

  ConfettiPiece({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.angle,
    required this.rotationSpeed,
    required this.horizontalSpeed,
  });
}

class CoinShowerPainter extends CustomPainter {
  final double progress;
  final int count;
  final List<Coin> _coins = [];

  CoinShowerPainter({required this.progress, required this.count}) {
    final random = math.Random(123); // Fixed seed for consistency

    if (_coins.isEmpty) {
      for (int i = 0; i < count; i++) {
        _coins.add(
          Coin(
            x: random.nextDouble() * 200 - 100,
            y: -30 - random.nextDouble() * 200,
            size: 10 + random.nextDouble() * 15,
            rotationSpeed: random.nextDouble() * 0.3 - 0.15,
            fallSpeed: 2 + random.nextDouble() * 3,
            horizontalSpeed: random.nextDouble() * 2 - 1,
            depth: 0.5 + random.nextDouble() * 0.5, // 3D depth effect
          ),
        );
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    // Sort coins by depth to create 3D effect
    _coins.sort((a, b) => a.depth.compareTo(b.depth));

    for (var coin in _coins) {
      final newY = coin.y + coin.fallSpeed * progress * size.height;
      final newX =
          centerX + coin.x + coin.horizontalSpeed * progress * size.width * 0.3;
      final rotation = coin.rotationSpeed * progress * 10;

      // Adjust size and opacity based on depth for 3D effect
      final scaledSize = coin.size * coin.depth;
      final opacity = math.min(1.0, coin.depth + 0.2);

      // Make coin appear to rotate in 3D
      final perspective = math.sin(rotation) * 0.7;
      final apparentWidth = scaledSize * math.cos(rotation).abs();

      canvas.save();
      canvas.translate(newX, newY);

      // Draw coin shadow
      final shadowPaint =
          Paint()
            ..color = Colors.black.withOpacity(0.2 * opacity)
            ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(2, 2),
          width: apparentWidth,
          height: scaledSize * 0.3,
        ),
        shadowPaint,
      );

      // Draw coin base
      final coinBasePaint =
          Paint()
            ..shader = RadialGradient(
              colors: [
                Colors.amber.shade400.withOpacity(opacity),
                Colors.amber.shade700.withOpacity(opacity),
              ],
            ).createShader(
              Rect.fromCenter(
                center: Offset.zero,
                width: scaledSize,
                height: scaledSize,
              ),
            );

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: apparentWidth,
          height: scaledSize,
        ),
        coinBasePaint,
      );

      // Draw coin highlight
      if (perspective > 0) {
        final highlightPaint =
            Paint()
              ..color = Colors.white.withOpacity(0.6 * perspective * opacity)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5;

        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(-apparentWidth * 0.2, -scaledSize * 0.2),
            width: apparentWidth * 0.6,
            height: scaledSize * 0.6,
          ),
          math.pi / 4,
          math.pi,
          false,
          highlightPaint,
        );
      }

      // Draw ₹ symbol on coin
      final textStyle = TextStyle(
        color: Colors.amber.shade900.withOpacity(opacity),
        fontSize: scaledSize * 0.6,
        fontWeight: FontWeight.bold,
      );

      final textSpan = TextSpan(text: "₹", style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CoinShowerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class Coin {
  final double x;
  final double y;
  final double size;
  final double rotationSpeed;
  final double fallSpeed;
  final double horizontalSpeed;
  final double depth; // For 3D effect (0-1)

  Coin({
    required this.x,
    required this.y,
    required this.size,
    required this.rotationSpeed,
    required this.fallSpeed,
    required this.horizontalSpeed,
    required this.depth,
  });
}

class MovingChipsPainter extends CustomPainter {
  final List<Offset> positions;
  final List<int> values;
  final Animation<double> animation;
  final Offset target;

  MovingChipsPainter({
    required this.positions,
    required this.values,
    required this.animation,
    required this.target,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < positions.length; i++) {
      final start = positions[i];
      final end = target;

      // Calculate current position with arc movement
      final progress = animation.value;
      final controlPoint = Offset(
        (start.dx + end.dx) / 2,
        math.min(start.dy, end.dy) - 100 * (1 - (progress - 0.5).abs() * 2),
      );

      final x = _bezierPoint(start.dx, controlPoint.dx, end.dx, progress);
      final y = _bezierPoint(start.dy, controlPoint.dy, end.dy, progress);

      final current = Offset(
        start.dx + (end.dx - start.dx) * animation.value,
        start.dy + (end.dy - start.dy) * animation.value,
      );

      // Add bounce effect at the end
      final scale = 1.0 + (progress < 0.8 ? 0.0 : (1 - progress) * 0.5);

      // Draw a shadow
      final shadowPaint =
          Paint()
            ..color = Colors.black.withOpacity(0.3)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(
        Offset(current.dx + 2, current.dy + 2),
        12 * scale,
        shadowPaint,
      );

      // Draw the chip
      final paint =
          Paint()
            ..color = _getChipColor(values[i])
            ..style = PaintingStyle.fill;
      canvas.drawCircle(current, 12 * scale, paint);

      // Draw a highlight
      final highlightPaint =
          Paint()
            ..color = Colors.white.withOpacity(0.3)
            ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(current.dx - 4, current.dy - 4),
        4 * scale,
        highlightPaint,
      );

      // Draw chip value
      final textPainter = TextPainter(
        text: TextSpan(
          text: values[i].toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 10 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        current - Offset(textPainter.width / 2, textPainter.height / 2),
      );

      // Draw a trail for the last few positions
      if (progress > 0.1) {
        final trailPaint =
            Paint()
              ..color = _getChipColor(values[i]).withOpacity(0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2;

        final prevProgress = math.max(0, progress - 0.1).toDouble();
        ;
        final prevX = _bezierPoint(
          start.dx,
          controlPoint.dx,
          end.dx,
          prevProgress,
        );
        final prevY = _bezierPoint(
          start.dy,
          controlPoint.dy,
          end.dy,
          prevProgress,
        );

        canvas.drawLine(Offset(prevX, prevY), current, trailPaint);
      }
    }
  }

  double _bezierPoint(double a, double b, double c, double t) {
    return math.pow(1 - t, 2) * a + 2 * (1 - t) * t * b + math.pow(t, 2) * c;
  }

  @override
  bool shouldRepaint(covariant MovingChipsPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.animation.value != animation.value;
  }
}

Color _getChipColor(int value) {
  if (value >= 10000) return Colors.orange;
  if (value >= 1000) return Colors.deepOrange;
  if (value >= 100) return Colors.purpleAccent;
  if (value >= 10) return Colors.black;
  if (value == 4) return Colors.amberAccent;
  return Colors.orange;
}
