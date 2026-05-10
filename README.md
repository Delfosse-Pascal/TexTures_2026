# TexTures 2026

Bibliotheque locale de textures destinee a regrouper des images de reference et de travail pour des usages graphiques, 3D, rendu, prototypage ou documentation visuelle.

## Contenu local

Le dossier local contient actuellement des lots de textures organises par format, resolution et fond :

| Dossier | Description | Nombre de fichiers |
| --- | --- | ---: |
| `2048-JPG-242424` | Textures JPG en 2048 px sur fond sombre `#242424`. | 615 |
| `2048-JPG-FFFFFF` | Textures JPG en 2048 px sur fond blanc `#FFFFFF`. | 615 |
| `256-JPG-242424` | Textures JPG en 256 px sur fond sombre `#242424`. | 624 |
| `256-JPG-FFFFFF` | Textures JPG en 256 px sur fond blanc `#FFFFFF`. | 624 |
| `64-PNG` | Vignettes ou apercus PNG en 64 px. | 72 |
| `thumbnail` | Vignettes JPG de consultation rapide. | 2260 |

Les fichiers repertories localement sont majoritairement des images de textures (`.jpg` et `.png`) nommees par categorie ou materiau, par exemple briques, beton, bois, nourriture, metaux, sols et surfaces diverses.

## Gestion Git

Ce depot Git sert principalement a versionner la documentation, les fichiers de configuration et les eventuels scripts ou index texte du projet.

Les images, PDF, videos, archives et fichiers audio sont volontairement exclus du suivi Git afin d'eviter de publier des fichiers lourds ou binaires dans le depot. Ils restent disponibles dans le dossier local de travail, mais ne sont pas ajoutes aux commits.

## Depot distant

Depot GitHub associe :

<https://github.com/Delfosse-Pascal/TexTures_2026>

## Notes de maintenance

- Ajouter les nouveaux fichiers texte utiles au suivi du projet : documentation, inventaires, scripts, licences ou notes de traitement.
- Conserver les medias sources dans les dossiers locaux prevus a cet effet.
- Verifier `git status` avant chaque commit pour confirmer que seuls les fichiers voulus sont suivis.
