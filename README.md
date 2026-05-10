# TexTures 2026

TexTures 2026 est un site local de consultation pour une collection de textures, de vignettes et de musiques. Le projet sert a parcourir les contenus presents sur la machine sous forme de pages HTML simples, navigables et utilisables hors ligne.

## Objectif du projet

Ce depot versionne uniquement les fichiers utiles a la structure du site :

- documentation ;
- pages HTML ;
- feuilles de style CSS ;
- scripts JavaScript ;
- scripts de generation ;
- fichiers de configuration Git.

Les fichiers lourds ou binaires restent dans le dossier local, mais ils ne sont pas envoyes dans GitHub.

## Contenu local

Les dossiers locaux contiennent principalement des textures classees par taille, format et couleur de fond.

| Dossier | Role | Contenu local |
| --- | --- | --- |
| `2048-JPG-242424` | Galerie haute resolution sur fond sombre. | Images JPG locales ignorees par Git. |
| `2048-JPG-FFFFFF` | Galerie haute resolution sur fond blanc. | Images JPG locales ignorees par Git. |
| `256-JPG-242424` | Galerie moyenne resolution sur fond sombre. | Images JPG locales ignorees par Git. |
| `256-JPG-FFFFFF` | Galerie moyenne resolution sur fond blanc. | Images JPG locales ignorees par Git. |
| `64-PNG` | Petites vignettes PNG. | Images PNG locales ignorees par Git. |
| `thumbnail` | Miniatures de navigation et sous-galeries. | Images JPG locales ignorees par Git. |
| `Musique` | Pistes audio locales. | Fichiers audio ignores par Git. |

## Site HTML local

Le fichier `index.html` a la racine est l'entree principale du site. Il donne acces aux galeries, aux pages paginees, aux miniatures et a la section musique.

Les pages generees incluent :

- un mode clair / sombre ;
- une navigation locale ;
- des miniatures visibles sur la page d'accueil ;
- des galeries adaptees aux images disponibles ;
- l'affichage agrandi d'une image au clic ;
- la fermeture de l'affichage agrandi avec la touche Echappe ;
- les dimensions et le poids des fichiers sous les images ;
- des boutons musique qui lancent ou arretent l'audio sans lecteur visible ;
- les liens sociaux externes demandes, sans dependance obligatoire a Internet.

Le site reste donc consultable localement meme si les ressources externes ne chargent pas.

## Generation du site

Le site est genere par le script :

```powershell
powershell -ExecutionPolicy Bypass -File tools\generate-site.ps1
```

Ce script parcourt les dossiers locaux, detecte les images et les musiques, puis regenere les pages HTML et les assets locaux dans `site-assets/`.

## Regles Git

Le depot GitHub ne doit pas recevoir :

- images ;
- PDF ;
- videos ;
- archives ;
- fichiers audio ou musique ;
- livres numeriques ;
- autres fichiers binaires lourds.

Ces exclusions sont gerees par `.gitignore`.

Git ne suit pas les dossiers vides. Les "tiroirs" visibles dans le depot correspondent donc uniquement aux chemins necessaires pour ranger les fichiers texte du site. L'objectif est de garder une structure courte et claire, avec uniquement les dossiers de base utiles au site local.

## Depot distant

Depot GitHub associe :

<https://github.com/Delfosse-Pascal/TexTures_2026>

## Verification avant publication

Avant chaque commit, verifier :

```powershell
git status --short
git ls-files --cached
```

Le commit ne doit contenir que des fichiers de documentation, HTML, CSS, JavaScript, PowerShell ou configuration Git.
