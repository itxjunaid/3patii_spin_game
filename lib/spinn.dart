import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';

class GameScreenSpin extends StatefulWidget {
  @override
  _GameScreenSpinState createState() => _GameScreenSpinState();
}

class _GameScreenSpinState extends State<GameScreenSpin>
    with TickerProviderStateMixin {
  final int timeLeft = 30;
  final int currentRound = 1916;
  bool _isSoundOn = true;
  final int myCoins = 248950;
  int _spinStepCount = 0;
  final int todayWins = 12500;
  int selectedBet = 100;
  int? selectedFoodIndex;
  List<Map<String, dynamic>> selections =
      []; // Will store {index: foodIndex, bet: betAmount}
  bool isAutoPlaying = false;
  int lastSelectedIndex = 0;
  List<FoodItem> recentSpinResults = [];

  int currentSelectionIndex = -1;
  late AnimationController _spinController;

  late AnimationController _parallaxController;
  late AnimationController _floatingController;
  late AnimationController _timerController;
  late AnimationController _glowController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<FoodItem> foodItems = [
    FoodItem('Cabbage', 5, Colors.green, 'assets/cabbage.png'),
    FoodItem('Orange Crab', 45, Colors.orange, 'assets/crab.png'),
    FoodItem('Blue Fish', 25, Colors.blue, 'assets/fish.png'),
    FoodItem('Mushroom', 5, Colors.brown, 'assets/mushroom.png'),
    FoodItem('Pumpkin', 5, Colors.deepOrange, 'assets/pumpkin.png'),
    FoodItem('Tomato', 5, Colors.red, 'assets/tomato.png'),
    FoodItem('Shrimp', 15, Colors.pinkAccent, 'assets/shrimp.png'),
    FoodItem('Steak', 10, Colors.redAccent, 'assets/steak.png'),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize all controllers first
    _parallaxController = AnimationController(
      vsync: this,
      duration: Duration(minutes: 5),
    )..repeat();

    _floatingController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat(reverse: true);

    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 30),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Then initialize the spin controller
    _spinController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    )..addListener(_handleSpinUpdate);
  }

  int _lastPlayedIndex = -1; // Add this in your state

  // Add these class-level variables to _SpinGameScreenState

  // Add these methods to _SpinGameScreenState

  void _handleFoodSelection(int index) {
    setState(() {
      selectedFoodIndex = index;
    });
  }

  void _showSoundSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.indigo.shade300.withOpacity(0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.purple.shade400, Colors.indigo.shade700],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Setting',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(color: Colors.white30),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sound',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    Container(
                      width: 80,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade800,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              _isSoundOn ? 'On' : 'Off',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          Align(
                            alignment:
                                _isSoundOn
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSoundOn = !_isSoundOn;
                                });
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.pink.shade300,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.purple.shade400, Colors.indigo.shade700],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rule',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(color: Colors.white30),
                const SizedBox(height: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. Choose your bet amount and select the food to bet;',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '2. There\'re 30 seconds for betting each round, the result will be announced instantly afterwards;',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '3. If the result announced matches the food you have selected, you will rewards relative to the respective odds;',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '4. The official prize pool will increase as more users participate in game, there will be a chance for "PIZZA" or "SALAD" reward as prize pool reaches a certain amount;',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '5. If "SALAD" was announced, then all vegetables will be rewarded;',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '6. If "PIZZA" was announced, then all meats will be rewarded.',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.purple.shade400, Colors.indigo.shade700],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(color: Colors.white30),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Play Time',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Text(
                      'Play Details',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Text(
                      'Result',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Text(
                      'Revenue',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 200,
                  // History list would go here, empty for now
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRankingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 320,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.purple.shade400, Colors.indigo.shade700],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Today\'s Revenue Rank',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(color: Colors.white30),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ranking',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Text(
                      'Profile',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Text(
                      'Name',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Text(
                      'Revenue',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Sample entries for the ranking list
                _buildRankEntry(1, 'Happy☆', 228900),
                _buildRankEntry(2, 'Angel', 196750),
                _buildRankEntry(3, 'DilNasheen', 93050),
                _buildRankEntry(4, 'Khamosh👑', 10500),
                _buildRankEntry(5, 'ŢYR-মন শাখি', 5150),
                _buildRankEntry(6, 'ali', 3050),
                _buildRankEntry(7, 'Revad', 2050),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankEntry(int rank, String name, int revenue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            rank.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            // This would be where the profile image would go
          ),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                revenue.toString(),
                style: const TextStyle(color: Colors.amber, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showWinPopup(FoodItem item, {int? bet, int? wonAmount}) {
    final isWinner = wonAmount != null && bet != null;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.deepPurple.shade900.withOpacity(0.95),
            title: Column(
              children: [
                Icon(_getFoodIcon(item.name), size: 60, color: item.color),
                SizedBox(height: 10),
                Text(
                  item.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                if (isWinner) ...[
                  Text(
                    "Bet: $bet × ${item.multiplier}",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "You won $wonAmount coins!",
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else
                  Text(
                    "Better luck next time!",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
              ],
            ),
            content: Container(
              height: 100,
              child: Center(child: isWinner ? _buildFireworks() : SizedBox()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  void _handleSpinUpdate() {
    final progress = _spinController.value;
    final easedProgress = Curves.easeOut.transform(progress);
    final totalSteps = _spinStepCount;
    final index =
        (lastSelectedIndex + (easedProgress * totalSteps).floor()) %
        foodItems.length;

    if (index != _lastPlayedIndex) {
      _audioPlayer.play(AssetSource('tick.mp3')); // play sound
      _lastPlayedIndex = index;
    }

    setState(() {
      currentSelectionIndex = index;
    });
  }

  void _startAutoPlay() {
    setState(() {
      isAutoPlaying = true;

      currentSelectionIndex = -1;
    });

    final random = math.Random();

    final randomDuration = Duration(seconds: 2 + random.nextInt(4));
    _spinController.duration = randomDuration;

    _spinStepCount = 24 + random.nextInt(16);

    _spinController.reset();
    _spinController.forward().then((_) => _handleSpinResult());

    _timerController.reset();
    _timerController.duration = randomDuration;
    _timerController.forward();
  }

  Future<void> _handleSpinResult() async {
    final winningItem = foodItems[currentSelectionIndex];
    final matched = selections.firstWhere(
      (s) => s['index'] == currentSelectionIndex,
      orElse: () => {},
    );

    setState(() {
      isAutoPlaying = false;
      selectedFoodIndex = currentSelectionIndex;
      lastSelectedIndex = selectedFoodIndex!;

      recentSpinResults.insert(0, winningItem);
      if (recentSpinResults.length > 5) {
        recentSpinResults.removeLast();
      }
    });

    await Future.delayed(Duration(milliseconds: 600)); // wait before popup

    if (matched.isNotEmpty) {
      final bet = matched['bet'];
      final totalWin = bet * winningItem.multiplier;
      _showWinPopup(winningItem, bet: bet, wonAmount: totalWin);
    } else {
      _showWinPopup(winningItem);
    }

    await Future.delayed(Duration(milliseconds: 400)); // wait before clearing
    setState(() {
      selections.clear();
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _glowController.dispose();
    _timerController.dispose();
    _floatingController.dispose();
    _parallaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // Deep space background with parallax effect
            SpaceBackground(controller: _parallaxController),

            // Main game content
            SafeArea(
              child: Column(
                children: [
                  // Top navigation bar - responsive height
                  SizedBox(
                    height:
                        isPortrait ? screenHeight * 0.08 : screenHeight * 0.07,
                    child: _buildTopNavBar(),
                  ),

                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Food item pods in radial pattern
                        _buildFoodItemCircle(),

                        // Central astronaut in pod
                        _buildCentralAstronaut(),
                      ],
                    ),
                  ),

                  // Bottom game controls - responsive height
                  SizedBox(
                    height:
                        isPortrait ? screenHeight * 0.20 : screenHeight * 0.25,
                    child: _buildBottomControls(),
                  ),
                ],
              ),
            ),

            // Menu options at bottom corners - responsive positioning
            Positioned(
              left: screenWidth * 0.03,
              bottom: screenHeight * 0.235,
              child: _buildMenuButton("Salad", Icons.eco),
            ),
            Positioned(
              right: screenWidth * 0.03,
              bottom: screenHeight * 0.235,
              child: _buildMenuButton("Pizza", Icons.local_pizza),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return Container(
          height: 225,

          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF6A3093).withOpacity(0), // Purple
                Color(0xFFA044FF).withOpacity(0), // Lighter purple
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
            // border: Border.all(
            //   color: Colors.white.withOpacity(0.3),
            //   width: 1.5,
            // ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Row(
                  children: [
                    // Back button
                    Container(
                      height: 38,
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: isWide ? 25 : 20,
                        ),
                        onPressed: () {},
                      ),
                    ),
                    SizedBox(width: 10),
                    // Sound toggle
                    Container(
                      height: 38,
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isSoundOn ? Icons.volume_up : Icons.volume_off,
                          color: Colors.white,
                          size: isWide ? 25 : 20,
                        ),
                        onPressed: () {
                          _showSoundSettingsDialog();
                        },
                      ),
                    ),

                    Spacer(),
                    Container(
                      height: 38,
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.question_mark,
                          color: Colors.white,
                          size: isWide ? 25 : 20,
                        ),
                        onPressed: () {
                          _showRulesDialog();
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      height: 38,
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: isWide ? 25 : 20,
                        ),
                        onPressed: () {
                          _showHistoryDialog();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isWide) ...[
                    // _buildProfileWithCrown(isWide),
                    SizedBox(width: constraints.maxWidth * 0.02),
                  ],

                  // Round counter - hides on very small screens
                  if (constraints.maxWidth > 400)
                    Container(
                      height: 23,

                      padding: EdgeInsets.symmetric(
                        horizontal: constraints.maxWidth * 0.02,
                        vertical: constraints.maxHeight * 0.01,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(
                        "Round: $currentRound",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isWide ? 14 : 10,
                        ),
                      ),
                    ),
                  SizedBox(width: 10),
                  // Today Rank button - adjusts size
                  Flexible(
                    child: Container(
                      height: 23,
                      margin: EdgeInsets.only(left: isWide ? 0 : 8),
                      child: ElevatedButton(
                        onPressed: () {
                          _showRankingDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF08D9D6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: Colors.white, width: 1.5),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 20 : 10,
                            vertical: isWide ? 10 : 5,
                          ),
                          elevation: 5,
                          shadowColor: Color(0xFF08D9D6).withOpacity(0.5),
                        ),
                        child: Text(
                          "Today Rank",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isWide ? 10 : 9,
                            color: Color(0xFF2A1B3D),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileWithCannon(bool isWide) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.all(isWide ? 8 : 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFA044FF), Color(0xFF6A3093)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: isWide ? 20 : 15,
            backgroundColor: Colors.purple[300],
            child: Text(
              "JP",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isWide ? 16 : 12,
              ),
            ),
          ),
        ),
        Positioned(
          top: -5,
          right: -5,
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Color(0xFFFFD700),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Icon(
              Icons.star,
              color: Color(0xFF6A3093),
              size: isWide ? 16 : 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCentralAstronaut() {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingController.value * 10 - 5),
          child: Container(
            width: 95,
            height: 95,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF08D9D6).withOpacity(0.7),
                  blurRadius: 25,
                  spreadRadius: 5,
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Astronaut image
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.white, Colors.white70],
                      stops: [0.7, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF2A1B3D),
                    ),
                  ),
                ),

                // Timer ring
                AnimatedBuilder(
                  animation: _timerController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: TimerRingPainter(
                        progress: _timerController.value,
                        color: Color(0xFFFF2E63),
                      ),
                      size: Size(120, 120),
                    );
                  },
                ),

                // Timer text at bottom
                Positioned(
                  bottom: 15,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      "Select Time: ${timeLeft}s",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFoodItemCircle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final circleSize = constraints.maxWidth * 1;
        final radius = circleSize * 0.30;
        final podSize = circleSize * 0.09; // Reduced pod size

        return Container(
          width: circleSize,
          height: circleSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Light beam paths connecting to center
              CustomPaint(
                painter: LightBeamsPainter(
                  itemCount: foodItems.length,
                  color: Colors.white.withOpacity(0.2),
                ),
                size: Size(circleSize, circleSize),
              ),

              // Food items in radial pattern
              ...List.generate(foodItems.length, (index) {
                final angle = 2 * math.pi * index / foodItems.length;
                final x = radius * math.cos(angle);
                final y = radius * math.sin(angle);

                return Positioned(
                  left: circleSize / 2 + x - 50,
                  top: circleSize / 2 + y - 50,
                  child: _buildFoodItemPod(foodItems[index], index),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFoodItemPod(FoodItem item, int index) {
    final isSpinning = isAutoPlaying && index == currentSelectionIndex;
    final isUserSelected = selections.any((s) => s['index'] == index);
    final isCurrentlySelected = isSpinning || isUserSelected;

    final selection = selections.firstWhere(
      (s) => s['index'] == index,
      orElse: () => {'bet': 0},
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_floatingController, _spinController]),
      builder: (context, child) {
        // Create a floating effect with different phases for each item
        final floatOffset =
            math.sin(_floatingController.value * math.pi * 2 + index * 0.5) * 8;

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: GestureDetector(
            onTap: () {
              _handleFoodSelection(index);
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isSpinning
                          ? [Colors.yellow.shade800, Colors.orange.shade400]
                          : isUserSelected
                          ? [Color(0xFFA044FF), Color(0xFF6A3093)]
                          : [
                            Color(0xFF2A1B3D).withOpacity(0.8),
                            Color(0xFF1A1A40).withOpacity(0.8),
                          ],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        isCurrentlySelected
                            ? item.color.withOpacity(0.8)
                            : item.color.withOpacity(0.5),
                    blurRadius: isCurrentlySelected ? 25 : 15,
                    spreadRadius: isCurrentlySelected ? 5 : 2,
                  ),
                ],
                border: Border.all(
                  color:
                      isCurrentlySelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                  width: isCurrentlySelected ? 3 : 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Food item icon
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      return Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.color.withOpacity(
                            selectedFoodIndex == index
                                ? 0.5
                                : 0.3 + _glowController.value * 0.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: item.color.withOpacity(
                                selectedFoodIndex == index
                                    ? 0.6
                                    : _glowController.value * 0.3,
                              ),
                              blurRadius: selectedFoodIndex == index ? 30 : 20,
                              spreadRadius:
                                  selectedFoodIndex == index
                                      ? 10
                                      : _glowController.value * 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _getFoodIcon(item.name),
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),

                  // Multiplier indicator
                  Positioned(
                    bottom: 5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Multiplier
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white,
                              width: selectedFoodIndex == index ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            "×${item.multiplier}",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        // Bet Amount (only show if user selected)
                        if (isUserSelected)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${selection['bet']}',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // NEW tag if applicable
                  if (index == 2) // For demonstration, showing on Blue Fish
                    Positioned(
                      top: 5,
                      right: 5,
                      child: AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFF2E63), Color(0xFFFF5E8A)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(
                                    0xFFFF2E63,
                                  ).withOpacity(_glowController.value * 0.7),
                                  blurRadius: 10,
                                  spreadRadius: _glowController.value * 3,
                                ),
                              ],
                            ),
                            child: Text(
                              "NEW",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth * 0.04,
            vertical: constraints.maxHeight * 0.06,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF6A3093).withOpacity(0.95),
                Color(0xFFA044FF).withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 15,
                offset: Offset(0, -5),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Results display - responsive height
              SizedBox(
                height: constraints.maxHeight * 0.22,
                child: _buildResultsDisplay(isWide),
              ),

              SizedBox(height: constraints.maxHeight * 0.01),

              // Betting options and controls
              Expanded(
                child: Row(
                  children: [
                    // Betting options
                    Expanded(
                      flex: isWide ? 3 : 2,
                      child: _buildBetOptions(isWide),
                    ),

                    SizedBox(width: constraints.maxWidth * 0.03),

                    // Auto Play button
                    Expanded(flex: 1, child: _buildAutoPlayButton(isWide)),
                  ],
                ),
              ),

              SizedBox(height: constraints.maxHeight * 0.01),

              // Coin counters
              _buildCoinCounters(isWide),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultsDisplay(bool isWide) {
    return Container(
      margin: EdgeInsets.only(bottom: isWide ? 16 : 8),
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A1B3D), Color(0xFF1A1A40)],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('Result ', style: TextStyle(color: Colors.white, fontSize: 12)),
          ...recentSpinResults
              .map(
                (item) => _buildResultItem(
                  _getFoodIcon(item.name),
                  item.color,
                  isWide,
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildResultItem(IconData icon, Color color, bool isWide) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Container(
          width: isWide ? 50 : 44,
          height: isWide ? 50 : 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withOpacity(0.4), color.withOpacity(0.1)],
            ),
            border: Border.all(color: color.withOpacity(0.8), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, size: isWide ? 28 : 24, color: Colors.white),
        );
      },
    );
  }

  Widget _buildBetOptions(bool isWide) {
    final betAmounts = [10, 100, 1000, 10000];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          betAmounts.map((amount) {
            return GestureDetector(
              onTap: () {
                if (selectedFoodIndex == null) return;

                setState(() {
                  final existingIndex = selections.indexWhere(
                    (s) => s['index'] == selectedFoodIndex,
                  );
                  if (existingIndex != -1) {
                    selections[existingIndex]['bet'] = amount;
                  } else if (selections.length < 5) {
                    selections.add({'index': selectedFoodIndex, 'bet': amount});
                  }
                  selectedBet = 0; // Reset after placing the bet
                });
              },
              child: Container(
                width: isWide ? 60 : 50,
                height: isWide ? 60 : 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        selectedBet == amount
                            ? [Color(0xFFA044FF), Color(0xFF6A3093)] // Selected
                            : [
                              Color(0xFF2A1B3D).withOpacity(0.8),
                              Color(0xFF1A1A40).withOpacity(0.8),
                            ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color:
                        selectedBet == amount
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                    width: selectedBet == amount ? 2.5 : 1.5,
                  ),
                  boxShadow:
                      selectedBet == amount
                          ? [
                            BoxShadow(
                              color: Color(0xFFA044FF).withOpacity(0.6),
                              blurRadius: 10,
                              spreadRadius: 3,
                              offset: Offset(0, 4),
                            ),
                          ]
                          : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color:
                          selectedBet == amount
                              ? Colors.white
                              : Color(0xFFFFD700),
                      size: isWide ? 20 : 16,
                    ),
                    SizedBox(height: 2),
                    Text(
                      amount >= 1000 ? "${amount ~/ 1000}K" : "$amount",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isWide ? 14 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildAutoPlayButton(bool isWide) {
    return GestureDetector(
      onTap: isAutoPlaying ? null : _startAutoPlay,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isAutoPlaying
                    ? [Colors.grey, Colors.grey.shade700]
                    : [Color(0xFFFF2E63), Color(0xFFFF5E8A)],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isAutoPlaying ? Colors.grey : Colors.white,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            isAutoPlaying ? "Spinning..." : "Auto\nPlay",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isWide ? 14 : 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoinCounters(bool isWide) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCoinCounter("Mine", '0', isWide),
        _buildCoinCounter("Today Win", '1', isWide),
      ],
    );
  }

  Widget _buildFireworks() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.5, end: 1),
      duration: Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Icon(
            Icons.celebration,
            color: Colors.pinkAccent.shade100,
            size: 80,
          ),
        );
      },
    );
  }

  Widget _buildCoinCounter(String label, String amount, bool isWide) {
    ;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 14 : 10,
        vertical: isWide ? 8 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A1B3D), Color(0xFF1A1A40)],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: isWide ? 12 : 10),
          ),
          SizedBox(width: isWide ? 8 : 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.monetization_on,
                color: Color(0xFFFFD700),
                size: isWide ? 20 : 16,
              ),
              SizedBox(width: 5),
              Text(
                amount,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isWide ? 12 : 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        // Add menu button logic here
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A3093), Color(0xFFA044FF)],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFoodIcon(String name) {
    switch (name.toLowerCase()) {
      case 'cabbage':
        return Icons.eco;
      case 'orange crab':
        return Icons.set_meal;
      case 'blue fish':
        return Icons.water;
      case 'mushroom':
        return Icons.spa;
      case 'pumpkin':
        return Icons.cruelty_free;
      case 'tomato':
        return Icons.egg_alt;
      case 'shrimp':
        return Icons.lunch_dining;
      case 'steak':
        return Icons.fastfood;
      default:
        return Icons.food_bank;
    }
  }
}

// Custom Painters (unchanged from original)
class SpaceBackground extends StatelessWidget {
  final AnimationController controller;

  const SpaceBackground({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F0B21), Color(0xFF1A1A40), Color(0xFF2A1B3D)],
            ),
          ),
          child: Stack(
            children: [
              // Far stars (slowest movement)
              _buildParallaxLayer(
                context,
                'assets/stars_far.png',
                controller.value * 0.1,
                0.5,
              ),

              // Nebula effect
              Opacity(
                opacity: 0.4,
                child: _buildParallaxLayer(
                  context,
                  'assets/nebula.png',
                  controller.value * 0.15,
                  0.8,
                ),
              ),

              // Close stars (fastest movement)
              _buildParallaxLayer(
                context,
                'assets/stars_close.png',
                controller.value * 0.25,
                0.7,
              ),

              // Overlay gradient for depth
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Color(0xFF0F0B21).withOpacity(0.6),
                    ],
                    stops: [0.6, 1.0],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParallaxLayer(
    BuildContext context,
    String assetPath,
    double offset,
    double opacity,
  ) {
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(
          MediaQuery.of(context).size.width *
              offset %
              MediaQuery.of(context).size.width,
          0,
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 2,
          height: MediaQuery.of(context).size.height,
          child: CustomPaint(
            painter: StarsPainter(seed: assetPath.hashCode),
            size: Size(
              MediaQuery.of(context).size.width * 2,
              MediaQuery.of(context).size.height,
            ),
          ),
        ),
      ),
    );
  }
}

class TimerRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  TimerRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round
          ..shader = RadialGradient(
            colors: [color, color.withOpacity(0.5)],
          ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Draw background ring
    canvas.drawCircle(
      center,
      radius,
      paint..color = Colors.white.withOpacity(0.2),
    );

    // Draw progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2, // Start from top
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class LightBeamsPainter extends CustomPainter {
  final int itemCount;
  final Color color;

  LightBeamsPainter({required this.itemCount, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;

    for (int i = 0; i < itemCount; i++) {
      final angle = 2 * math.pi * i / itemCount;
      final x = radius * math.cos(angle);
      final y = radius * math.sin(angle);
      final point = Offset(center.dx + x, center.dy + y);

      // Draw a dashed line
      final double dashWidth = 5;
      final double dashSpace = 3;
      double distance = (point - center).distance;

      for (double d = 0; d < distance; d += dashWidth + dashSpace) {
        final double ratio = d / distance;
        final double nextRatio = (d + dashWidth) / distance;
        final start = Offset(center.dx + x * ratio, center.dy + y * ratio);
        final end = Offset(
          center.dx + x * nextRatio,
          center.dy + y * nextRatio,
        );
        canvas.drawLine(start, end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class StarsPainter extends CustomPainter {
  final int seed;
  final math.Random random;

  StarsPainter({required this.seed}) : random = math.Random(seed);

  @override
  void paint(Canvas canvas, Size size) {
    final starCount = 300;

    for (int i = 0; i < starCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2 + 0.5;
      final opacity = random.nextDouble() * 0.8 + 0.2;

      final paint =
          Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..style = PaintingStyle.fill;

      // Add twinkling effect to some stars
      if (random.nextDouble() > 0.7) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.8);
      }

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class FoodItem {
  final String name;
  final int multiplier;
  final Color color;
  final String imagePath;

  FoodItem(this.name, this.multiplier, this.color, this.imagePath);
}
