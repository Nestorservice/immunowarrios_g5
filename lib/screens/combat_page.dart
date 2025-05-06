import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Importe les providers nécessaires
import '../state/auth_state_provider.dart'; // userProfileProvider (dont dépend playerBaseProvider)
import '../models/base_virale.dart'; // Importe le modèle BaseVirale
// baseDetailsProvider.family est défini dans base_details_page.dart, donc on l'importe pour l'utiliser.
import 'base_details_page.dart'; // Nécessaire pour baseDetailsProvider
// Importe le service de combat que tu viens de créer
import '../services/combat_service.dart';
import 'bio_forge_page.dart';


// Cette page affiche les informations des deux bases pour le combat et gère la simulation.
// On utilise un ConsumerStatefulWidget pour gérer l'état du résultat de la simulation ET utiliser ref.
class CombatPage extends ConsumerStatefulWidget { // <-- CORRECTION : CHANGE ICI
  // La page a besoin de l'ID de la base ennemie
  final String enemyBaseId;

  // Le constructeur peut rester constant si les propriétés sont finales
  const CombatPage({super.key, required this.enemyBaseId});

  @override
  // Crée l'état associé à ce ConsumerStatefulWidget. Utilise ConsumerState.
  _CombatPageState createState() => _CombatPageState();
}

// La classe d'état pour la page de combat. Elle gère les variables qui changent (comme le résultat du combat).
// Elle hérite de ConsumerState<CombatPage>
class _CombatPageState extends ConsumerState<CombatPage> {

  // Variable d'état pour stocker le résultat du combat une fois la simulation lancée.
  // Elle est initialisée à null. setState() mettra à jour cette variable et reconstruira le widget.
  CombatResult? _combatResult;

  // TODO: Peut-être une variable booléenne pour afficher un indicateur pendant la simulation si elle était longue
  // bool _isSimulating = false;


  // Méthode pour lancer la simulation de combat. Elle est appelée par le bouton.
  void _runSimulation({
    required BaseVirale playerBase, // On a besoin de l'objet BaseVirale du joueur
    required BaseVirale enemyBase, // On a besoin de l'objet BaseVirale de l'ennemi
  }) {
    // On pourrait mettre _isSimulating à true ici et appeler setState() si la simulation prenait du temps.
    // setState(() { _isSimulating = true; });

    // Obtient une instance du service de combat. Pas besoin de Riverpod ici pour instancier le service lui-même.
    final combatService = CombatService(); // Crée une instance du service

    // Lance la simulation en appelant la méthode du service.
    final result = combatService.simulateCombat(
      playerBase: playerBase, // Passe la base du joueur
      enemyBase: enemyBase, // Passe la base ennemie
    );

    // Une fois la simulation terminée, met à jour la variable d'état et force Flutter à reconstruire le widget
    // pour afficher le résultat. setState() est nécessaire pour les variables d'état dans un StatefulWidget.
    setState(() { // <-- setState est crucial pour que l'interface se mette à jour
      _combatResult = result;
      // _isSimulating = false; // Si on gérait l'état de simulation
    });

    // Optionnel : imprimer le log complet dans la console pour débogage.
    print('\n--- Log Complet du Combat ---');
    for (var logEntry in result.combatLog) {
      print(logEntry);
    }
    print('---------------------------\n');
  }


  @override
  // La méthode build est maintenant définie dans la classe d'état (_CombatPageState).
  // Elle a accès à 'widget' (pour les paramètres du StatefulWidget) et 'ref' (pour Riverpod via ConsumerState).
  Widget build(BuildContext context) { // <-- build NE PREND PLUS WidgetRef direct, utilise la propriété 'ref'

    // Regarde la base du joueur via le provider existant (défini dans auth_state_provider.dart).
    // playerBaseProvider retourne un AsyncValue<BaseVirale?>
    final playerBaseAsyncValue = ref.watch(playerBaseProvider); // <-- Utilise ref ici

    // Regarde la base ennemie via le provider Family existant, en lui passant l'ID reçu via 'widget'.
    // enemyBaseId est accessible via 'widget.enemyBaseId' dans l'état.
    // baseDetailsProvider(widget.enemyBaseId) retourne un AsyncValue<BaseVirale?>
    final enemyBaseAsyncValue = ref.watch(baseDetailsProvider(widget.enemyBaseId)); // <-- Utilise ref et widget.enemyBaseId


    // On utilise des .when() imbriqués pour gérer l'état des deux AsyncValue (attendre que les deux bases soient chargées).
    // Le body du Scaffold gère l'état de chargement/erreur de la base du joueur.
    return Scaffold(
      appBar: AppBar(title: const Text('Simulation de Combat')),
      body: playerBaseAsyncValue.when(
        // État de chargement de la base du joueur
        loading: () => const Center(child: Text('Chargement de votre base pour le combat...')),
        // État d'erreur de la base du joueur
        error: (err, stack) => Center(child: Text('Erreur de chargement de votre base : $err')),
        // Quand la base du joueur est chargée (playerBase est BaseVirale? ou null)
        data: (playerBase) {
          // Si la base du joueur est null (pas trouvée ou pas connectée - même si auth checker doit l'empêcher)
          if (playerBase == null) {
            return const Center(child: Text('Votre base n\'est pas disponible pour le combat.'));
          }

          // Si la base du joueur est chargée, on gère maintenant l'état de la base ennemie.
          // L'appel à enemyBaseAsyncValue.when() est imbriqué dans le bloc 'data' de playerBaseAsyncValue.when().
          return enemyBaseAsyncValue.when(
            // État de chargement de la base ennemie
            loading: () => const Center(child: Text('Chargement de la base ennemie...')),
            error: (err, stack) => Center(child: Text('Erreur de chargement de la base ennemie : $err')),
            // Quand la base ennemie est chargée (enemyBase est BaseVirale? ou null)
            data: (enemyBase) {
              // Si la base ennemie est null (pas trouvée - ID incorrect ou permissions)
              if (enemyBase == null) {
                return const Center(child: Text('Base ennemie introuvable pour le combat.'));
              }

              // **Si les deux bases (joueur ET ennemie) sont chargées, affiche les informations et le contenu du combat.**
              return SingleChildScrollView( // Permet de scroller si le contenu devient long
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Étire les éléments horizontalement
                  children: [
                    // Titre principal
                    const Text('Combat Imminent !', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 30),

                    // --- Votre Base ---
                    Text('Votre Base : ${playerBase.nom ?? 'Base sans nom'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Pathogènes (${playerBase.pathogenes.length}) :', style: const TextStyle(fontSize: 14)),
                    // TODO: Afficher une liste sommaire ou des statistiques de la base du joueur

                    const SizedBox(height: 20),

                    // --- Séparateur Contre ---
                    const Text('CONTRE', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),


                    // --- Base Ennemie ---
                    Text('Base Ennemie : ${enemyBase.nom ?? 'Base sans nom'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Pathogènes (${enemyBase.pathogenes.length}) :', style: const TextStyle(fontSize: 14)),
                    // TODO: Afficher une liste sommaire ou des statistiques de la base ennemie

                    const SizedBox(height: 30),

                    // **BOUTON POUR LANCER LA SIMULATION :**
                    ElevatedButton(
                      // Le bouton est actif seulement si _combatResult est null (simulation pas encore lancée)
                      // Une fois lancée et le résultat stocké, on peut le désactiver ou changer son texte.
                      // Si _combatResult est null, onPressed sera la fonction _runSimulation. Sinon, onPressed sera null (bouton désactivé).
                      onPressed: _combatResult == null ? () {
                        print('Lancement de la simulation...');
                        // Appelle la fonction pour lancer la simulation, en passant les bases chargées.
                        _runSimulation(playerBase: playerBase, enemyBase: enemyBase);
                      } : null, // Désactive le bouton si simulation est déjà lancée/terminée (_combatResult n'est plus null)

                      child: const Text('Lancer la Simulation'),
                    ),

                    const SizedBox(height: 30),

                    // **AFFICHAGE DU RÉSULTAT DE LA SIMULATION :**
                    // Si _combatResult n'est pas null (la simulation a été lancée et s'est terminée), affiche les détails.
                    if (_combatResult != null) // Affiche cette section seulement si _combatResult a une valeur
                      Column( // Utilise un Column pour organiser l'affichage du résultat
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Résultat du Combat :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          // Utilise ! pour accéder aux propriétés de _combatResult car on sait qu'il n'est pas null ici (grâce au 'if')
                          Text('Vainqueur : ${_combatResult!.winner}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Votre équipe restante : ${_combatResult!.playerPathogensRemaining} pathogènes'),
                          Text('Équipe ennemie restante : ${_combatResult!.enemyPathogensRemaining} pathogènes'),
                          const SizedBox(height: 20),
                          const Text('Log du Combat :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          // Affiche le log (utilise un map().toList() et un spread operator pour mettre chaque entrée du log dans un Text Widget)
                          ..._combatResult!.combatLog.map((logEntry) => Text(logEntry)).toList(),
                        ],
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}