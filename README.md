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
| `2048-JPG-242424` | Galerie haute resolution sur fond sombre. | Dossier local ignore par Git et retire de GitHub. |
| `2048-JPG-FFFFFF` | Galerie haute resolution sur fond blanc. | Dossier local ignore par Git et retire de GitHub. |
| `256-JPG-242424` | Galerie moyenne resolution sur fond sombre. | Dossier local ignore par Git et retire de GitHub. |
| `256-JPG-FFFFFF` | Galerie moyenne resolution sur fond blanc. | Dossier local ignore par Git et retire de GitHub. |
| `64-PNG` | Petites vignettes PNG. | Dossier local ignore par Git et retire de GitHub. |
| `thumbnail` | Miniatures de navigation et sous-galeries. | Dossier local ignore par Git et retire de GitHub. |
| `Musique` | Pistes audio locales. | Fichiers audio ignores par Git. |

## Site HTML local

Le fichier `index.html` a la racine est l'entree principale du site publie. Il ne pointe plus vers les tiroirs d'images retires de GitHub.

Les pages generees incluent :

- un mode clair / sombre ;
- une navigation locale ;
- une page d'accueil simple ;
- les styles et scripts locaux du site ;
- des boutons musique qui lancent ou arretent l'audio sans lecteur visible ;
- les liens sociaux externes demandes, sans dependance obligatoire a Internet.

Le site reste donc consultable localement meme si les ressources externes ne chargent pas.

## Generation du site

Le site est genere par le script :

```powershell
powershell -ExecutionPolicy Bypass -File tools\generate-site.ps1
```

Ce script parcourt les dossiers locaux, detecte les images et les musiques, puis regenere les pages HTML et les assets locaux. Les dossiers d'images restent ignores par Git, meme si les fichiers existent localement.

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

Les tiroirs `64-PNG`, `256-JPG-242424`, `256-JPG-FFFFFF`, `2048-JPG-242424`, `2048-JPG-FFFFFF` et `thumbnail` sont volontairement retires de GitHub et ignores par Git. Ils peuvent rester presents sur le disque local pour le travail, mais ils ne doivent plus etre publies.

Git ne suit pas les dossiers vides. Les tiroirs visibles dans le depot correspondent donc uniquement aux chemins necessaires pour ranger les fichiers texte du site. L'objectif est de garder une structure courte et claire, avec uniquement les dossiers de base utiles au depot publie.

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
