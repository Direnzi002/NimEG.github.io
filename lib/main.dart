import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(NimGame());
}

class NimGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jogo NIM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: InitialScreen(),
    );
  }
}

// Tela Inicial - Solicita o nome do jogador
class InitialScreen extends StatefulWidget {
  @override
  _InitialScreenState createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  final _controller = TextEditingController();

  // Salva o nome do jogador e navega para a tela de seleção de palitos
  Future<void> _saveName() async {
    String name = _controller.text.trim();
    if (name.isEmpty) {
      // Exibe mensagem se o nome não for inserido
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, insira seu nome.')),
      );
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('playerName', name);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SelectSticksScreen()),
    );
  }

  // Navega para a tela de placar
  Future<void> _navigateToScores() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScoreScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jogo NIM'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Digite seu nome para começar:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Nome do Jogador',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveName,
              child: Text('Iniciar Jogo'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _navigateToScores,
              child: Text('Ver Placar Geral'),
            ),
          ],
        ),
      ),
    );
  }
}

// Tela de Seleção de Palitos
class SelectSticksScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escolha os Palitos'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Quantos palitos você vai começar?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              children: List.generate(7, (index) {
                int stickCount = index + 7;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameScreen(sticks: stickCount),
                        ),
                      );
                    },
                    child: Text('$stickCount'),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// Tela do Jogo
class GameScreen extends StatefulWidget {
  final int sticks;

  GameScreen({required this.sticks});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late int remainingSticks; // Palitos restantes
  late int playerWins; // Vitórias do jogador
  late int computerWins; // Vitórias do computador
  String playerName = ''; // Nome do jogador

  @override
  void initState() {
    super.initState();
    remainingSticks = widget.sticks; // Inicializa palitos restantes
    playerWins = 0; // Inicializa vitórias do jogador
    computerWins = 0; // Inicializa vitórias do computador
    _loadData(); // Carrega dados do jogador
  }

  // Carrega o nome do jogador e placares do SharedPreferences
  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      playerName = prefs.getString('playerName') ?? 'Jogador';
      playerWins = prefs.getInt('playerWins_$playerName') ?? 0;
      computerWins = prefs.getInt('computerWins') ?? 0;
    });
  }

  // Atualiza o placar após cada vitória
  Future<void> _updateScore(String winner) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (winner == 'player') {
      playerWins++;
      await prefs.setInt('playerWins_$playerName', playerWins);
    } else {
      computerWins++;
      await prefs.setInt('computerWins', computerWins);
    }
  }

  // Função para o jogador retirar palitos
  void _takeSticks(int taken) {
    setState(() {
      // Verifica se a quantidade de palitos a serem retirados não resulta em um número negativo
      remainingSticks -= taken;
      if (remainingSticks < 0) {
        remainingSticks = 0; // Garante que não haja palitos negativos
      }

      if (remainingSticks == 0) {
        _showResult('Você venceu!'); // Jogador vence
        _updateScore('player'); // Atualiza placar do jogador
      } else {
        int computerTake = _calculateComputerTake(remainingSticks);
        remainingSticks -= computerTake;

        // Garante que o número de palitos não fique negativo após a jogada do computador
        if (remainingSticks < 0) {
          remainingSticks = 0;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Computador retirou $computerTake palitos')),
        );

        if (remainingSticks == 0) {
          _showResult('Computador venceu!'); // Computador vence
          _updateScore('computer'); // Atualiza placar do computador
        }
      }
    });
  }

  // Cálculo do número de palitos que o computador deve retirar
  int _calculateComputerTake(int remaining) {
    if (remaining <= 0) return 0;
    return remaining >= 3 ? 3 : remaining; // O computador retira até 3 palitos
  }

  // Exibe o resultado ao final do jogo
  void _showResult(String result) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(result),
          content: Text(
              'Palitos restantes: $remainingSticks\nVitórias dos Jogadores: $playerWins\nVitórias do Computador: $computerWins'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    ).then((_) {
      if (result == 'Você venceu!' || result == 'Computador venceu!') {
        _showReturnButton(); // Exibe opções para retornar
      }
    });
  }

  // Método para mostrar botão de voltar ao início
  void _showReturnButton() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Fim de Jogo'),
          content: Text('Deseja voltar ao início ou escolher os palitos novamente?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => InitialScreen())); // Retorna à tela inicial
              },
              child: Text('Voltar ao Início'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Apenas fecha o diálogo
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SelectSticksScreen()), // Volta para seleção de palitos
                );
              },
              child: Text('Escolher Palitos'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jogo NIM'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Palitos restantes: $remainingSticks',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Vitórias dos Jogadores: $playerWins',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Vitórias do Computador: $computerWins',
              style: TextStyle(fontSize: 16),
            ),
            // Botões para o jogador escolher quantos palitos retirar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      _takeSticks(index + 1); // Jogador retira palitos
                    },
                    child: Text('${index + 1}'),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// Tela de Placar Geral
class ScoreScreen extends StatefulWidget {
  @override
  _ScoreScreenState createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  List<PlayerScore> topScores = [];

  // Carrega os 5 melhores placares
  Future<void> _loadScores() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<PlayerScore> scores = [];

    // Carrega placares de jogadores
    for (int i = 0; i < 5; i++) {
      String? name = prefs.getString('playerName_$i');
      int score = prefs.getInt('playerScore_$i') ?? 0;
      if (name != null) {
        scores.add(PlayerScore(name: name, score: score));
      }
    }

    // Ordena e seleciona os 5 melhores
    scores.sort((a, b) => b.score.compareTo(a.score));
    setState(() {
      topScores = scores.take(5).toList();
    });
  }

  // Método para navegar à tela inicial
  void _navigateToInitialScreen() {
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    _loadScores(); // Carrega os placares ao iniciar a tela
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Placar Geral'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: topScores.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(topScores[index].name),
                  trailing: Text(topScores[index].score.toString()),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _navigateToInitialScreen,
            child: Text('Voltar ao Início'),
          ),
        ],
      ),
    );
  }
}

// Classe para armazenar pontuação do jogador
class PlayerScore {
  final String name; // Nome do jogador
  final int score; // Pontuação do jogador

  PlayerScore({required this.name, required this.score});
}
