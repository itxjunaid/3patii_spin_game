import 'dart:io';

void main() {
  // Change this path to where your extracted PNG card files are
  final directory = Directory(
    'C:/Users/Idrees/Downloads/playing-cards-assets-master/playing-cards-assets-master/png',
  );

  final cardRenameMap = {
    'ace_of_spades': 'AS',
    '2_of_spades': '2S',
    '3_of_spades': '3S',
    '4_of_spades': '4S',
    '5_of_spades': '5S',
    '6_of_spades': '6S',
    '7_of_spades': '7S',
    '8_of_spades': '8S',
    '9_of_spades': '9S',
    '10_of_spades': '0S',
    'jack_of_spades': 'JS',
    'queen_of_spades': 'QS',
    'king_of_spades': 'KS',

    'ace_of_hearts': 'AH',
    '2_of_hearts': '2H',
    '3_of_hearts': '3H',
    '4_of_hearts': '4H',
    '5_of_hearts': '5H',
    '6_of_hearts': '6H',
    '7_of_hearts': '7H',
    '8_of_hearts': '8H',
    '9_of_hearts': '9H',
    '10_of_hearts': '0H',
    'jack_of_hearts': 'JH',
    'queen_of_hearts': 'QH',
    'king_of_hearts': 'KH',

    'ace_of_diamonds': 'AD',
    '2_of_diamonds': '2D',
    '3_of_diamonds': '3D',
    '4_of_diamonds': '4D',
    '5_of_diamonds': '5D',
    '6_of_diamonds': '6D',
    '7_of_diamonds': '7D',
    '8_of_diamonds': '8D',
    '9_of_diamonds': '9D',
    '10_of_diamonds': '0D',
    'jack_of_diamonds': 'JD',
    'queen_of_diamonds': 'QD',
    'king_of_diamonds': 'KD',

    'ace_of_clubs': 'AC',
    '2_of_clubs': '2C',
    '3_of_clubs': '3C',
    '4_of_clubs': '4C',
    '5_of_clubs': '5C',
    '6_of_clubs': '6C',
    '7_of_clubs': '7C',
    '8_of_clubs': '8C',
    '9_of_clubs': '9C',
    '10_of_clubs': '0C',
    'jack_of_clubs': 'JC',
    'queen_of_clubs': 'QC',
    'king_of_clubs': 'KC',
  };

  directory.listSync().forEach((file) {
    if (file is File) {
      final fileName = file.uri.pathSegments.last.split('.').first;
      if (cardRenameMap.containsKey(fileName)) {
        final newFileName = cardRenameMap[fileName];
        file.renameSync('${directory.path}/$newFileName.png');
        print('Renamed $fileName to $newFileName.png');
      }
    }
  });

  print('✅ All cards renamed successfully!');
}
