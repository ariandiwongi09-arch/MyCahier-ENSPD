# MyCahier ENSPD

**Application mobile de gestion du cahier de texte de l'ENSPD**

## 1. Présentation du projet

MyCahier ENSPD est une application mobile développée pour faciliter la gestion et la consultation des informations pédagogiques. Elle permet aux utilisateurs d'accéder aux fonctionnalités prévues selon leur rôle, notamment la consultation des cours et des séances.

Le projet repose sur une architecture composée d'une application mobile Flutter et d'une API backend Laravel.

## 2. Technologies utilisées

* **Frontend mobile :** Flutter et Dart.
* **Backend :** Laravel 12 et PHP.
* **Base de données :** MySQL.
* **Communication :** API REST au format JSON.
* **Authentification :** API Laravel avec gestion des utilisateurs et des rôles.

## 3. Organisation des dossiers

Le projet est organisé comme suit :

* `mycahier_mobile/` : code source de l'application Flutter.
* `mycahier-backend/` : API Laravel, routes, contrôleurs, modèles et migrations.
* `README.md` : documentation d'installation et d'utilisation.

## 4. Prérequis

Avant de lancer le projet, installer et configurer :

* PHP 8.2 ou une version compatible avec le projet.
* Composer.
* MySQL, par exemple avec XAMPP.
* Flutter et le SDK Dart compatible.
* Google Chrome pour exécuter la version Web de l'application.
* Git Bash et Visual Studio Code.

## 5. Installation et lancement du backend Laravel

### Étape 1 : ouvrir le dossier du backend

Dans Git Bash :


cd ~/Documents/MyCahier-ENSPD/mycahier-backend


### Étape 2 : installer les dépendances


composer install


### Étape 3 : configurer l'environnement

Créer le fichier `.env` à partir du modèle fourni :


cp .env.example .env


Générer la clé de l'application :


php artisan key:generate


### Étape 4 : configurer MySQL

Démarrer le service MySQL dans XAMPP ou dans le système utilisé.

Créer une base de données nommée `mycahier_ensp`, puis configurer les paramètres correspondants dans le fichier `.env` :


DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=mycahier_ensp
DB_USERNAME=root
DB_PASSWORD=


Les valeurs ci-dessus correspondent à une configuration locale courante. Adapter le nom d'utilisateur et le mot de passe à l'installation MySQL utilisée.

### Étape 5 : créer les tables

Exécuter les migrations :

php artisan migrate

Cette commande crée les tables définies par les migrations Laravel. Elle ne crée pas automatiquement les comptes de démonstration, sauf si le projet prévoit également leur création par un mécanisme adapté.

### Étape 6 : démarrer le serveur API


php artisan serve


Le backend est alors accessible à l'adresse :

**http://127.0.0.1:8000**

L'adresse de base de l'API utilisée par l'application est :

**http://127.0.0.1:8000/api**

Laisser ce terminal ouvert pendant l'utilisation de l'application.

## 6. Installation et lancement de l'application Flutter

### Étape 1 : ouvrir un deuxième terminal Git Bash

cd ~/Documents/MyCahier-ENSPD/mycahier_mobile

### Étape 2 : configurer Flutter dans Git Bash

Sur l'ordinateur de développement utilisé pour ce projet, le SDK Flutter est installé dans le dossier suivant :

/c/Users/FTAB TECH/Downloads/flutter_windows_3.47.7-stable/flutter


Ajouter Flutter au PATH de la session Git Bash :

export PATH="/c/Users/FTAB TECH/Downloads/flutter_windows_3.47.7-stable/flutter/bin:$PATH"

Sur un autre ordinateur, adapter ce chemin au dossier d'installation réel de Flutter.

Vérifier l'installation :

flutter --version


### Étape 3 : installer les dépendances Flutter

flutter pub get

### Étape 4 : lancer l'application dans Google Chrome

flutter run -d chrome

Cette commande lance la version Web de l'application dans Chrome. Pour ce mode d'exécution local, l'adresse de l'API configurée dans l'application doit correspondre à :

http://127.0.0.1:8000/api

Le backend Laravel doit être démarré avant de tester les fonctionnalités qui communiquent avec l'API.

## 7. Comptes de démonstration

Les identifiants de test utilisés pendant la validation du projet sont les suivants :

| Rôle       | Adresse e-mail                           | Mot de passe |
| ---------- | ----------------------------------------- | ------------ |
| Étudiant   | [student@ensp.cm](mailto:student@ensp.cm) | password     |
| Enseignant | [prof@ensp.cm](mailto:prof@ensp.cm)       | password     |

Ces identifiants permettent de tester les rôles correspondants lorsque les comptes existent dans la base de données utilisée.

**Important :** les migrations créent la structure de la base de données, mais ne garantissent pas la présence de ces utilisateurs. Sur une nouvelle installation, il faut également disposer des données de démonstration ou créer les comptes selon les mécanismes d'inscription prévus par le projet.

## 8. Vérifications réalisées

Les vérifications effectuées pendant le développement comprennent notamment :

* L'analyse du code Flutter avec `flutter analyze`.
* L'exécution des tests Flutter avec `flutter test`.
* Le lancement de l'application dans Google Chrome.
* Le démarrage et la vérification des routes de l'API Laravel.
* Les essais de connexion et la consultation des cours et des séances.

## 9. Dépannage

**Si la commande `flutter` n'est pas reconnue :**

Réexécuter la commande d'ajout de Flutter au PATH présentée à la section 6.

**Si l'application ne communique pas avec le backend :**

Vérifier que Laravel est démarré, que MySQL fonctionne et que l'adresse de l'API est correcte.

**Si la connexion échoue :**

Vérifier que les comptes de démonstration existent dans la base de données et que leurs mots de passe correspondent.

## 10. Auteur et livraison

Projet académique réalisé dans le cadre du devoir de développement mobile à l'ENSPD.

Le dépôt GitHub, le rapport PDF et la vidéo de démonstration accompagnent la livraison du projet.
