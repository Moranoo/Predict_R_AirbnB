# Application de Prédiction des Prix Airbnb

Cette application Shiny permet de prédire le prix des logements Airbnb en fonction de plusieurs caractéristiques, telles que le nombre de chambres, salles de bain, capacité d'accueil, et la catégorie de prix du quartier.

## Fonctionnalités

### Prédiction de Prix
- Prédictions des prix basées sur deux modèles : Régression Linéaire et Random Forest.
- Les résultats incluent le prix prédit, les frais de ménage et les taxes pour obtenir un coût total.

### Évaluation du Modèle
- Résumé du modèle de Régression Linéaire.
- Importance des variables dans le modèle Random Forest.
- Calcul des métriques d'évaluation : Mean Squared Error (MSE) et Root Mean Squared Error (RMSE).

### Visualisations
- Graphique de régression entre accommodates et log_price.
- Diagramme en moustache montrant la distribution des prix par catégorie de quartier.

## Installation et Lancement

### Prérequis
- R et RStudio
- Les librairies suivantes : tidyverse, randomForest, shiny

### Installation des librairies
```R
install.packages("tidyverse")
install.packages("randomForest")
install.packages("shiny")
```

### Exécution de l'application
1. Clonez ce dépôt ou téléchargez les fichiers nécessaires.
2. Placez votre fichier de données CSV `listings.csv` dans le même dossier que le script.
3. Exécutez le script dans R ou RStudio avec la commande suivante :
```R
shiny::runApp("nom_du_fichier.R")
```
L'application s'ouvrira dans votre navigateur.

## Utilisation de l'Application

- **Prédire le Prix** : Entrez les caractéristiques du logement (accommodates, bathrooms, bedrooms) et choisissez la catégorie de quartier. Cliquez sur "Prédire le prix" pour obtenir le prix estimé pour les deux modèles, y compris les frais supplémentaires (frais de ménage et taxes).
- **Évaluation du Modèle** : Consultez les résumés et l'importance des variables.
- **Graphiques** : Visualisez la relation entre la capacité d'accueil et le prix logarithmique, ainsi que la distribution des prix selon la catégorie de quartier.

## Description des Données

- **accommodates** : Nombre de personnes que le logement peut accueillir.
- **bathrooms** : Nombre de salles de bain.
- **bedrooms** : Nombre de chambres.
- **price** : Prix du logement, nettoyé pour exclure les caractères spéciaux.
- **log_price** : Transformation logarithmique du prix.
- **price_category** : Catégorie de prix du quartier (non_populaire, proche_populaire, populaire).

## Modèles de Prédiction

- **Régression Linéaire** : Prédiction basée sur une relation linéaire entre les caractéristiques et le log du prix.
- **Random Forest** : Modèle de machine learning non-linéaire basé sur des arbres de décision, permettant de capturer des relations complexes.