param(
    [string]$Root = (Resolve-Path ".").Path,
    [int]$PageSize = 60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$imageExtensions = @(".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp")
$audioExtensions = @(".mp3", ".wav", ".flac", ".aac", ".ogg", ".m4a")
$videoExtensions = @(".mp4", ".mov", ".avi", ".mkv", ".webm", ".m4v")
$documentExtensions = @(".txt", ".md", ".pdf", ".csv", ".json", ".xml")

function ConvertTo-PosixPath {
    param([string]$Path)
    return ($Path -replace "\\", "/")
}

function Get-RelativePath {
    param([string]$From, [string]$To)
    $fromUri = [System.Uri](([System.IO.Path]::GetFullPath($From).TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar))
    $toFull = [System.IO.Path]::GetFullPath($To)
    $toUri = [System.Uri]$toFull
    return [System.Uri]::UnescapeDataString($fromUri.MakeRelativeUri($toUri).ToString())
}

function Get-RelativePrefix {
    param([string]$PageDir)
    $pageFull = [System.IO.Path]::GetFullPath($PageDir).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
    $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
    if ($pageFull -eq $rootFull) { return "." }
    $fromUri = [System.Uri]($pageFull + [System.IO.Path]::DirectorySeparatorChar)
    $toUri = [System.Uri]($rootFull + [System.IO.Path]::DirectorySeparatorChar)
    $rel = [System.Uri]::UnescapeDataString($fromUri.MakeRelativeUri($toUri).ToString())
    if ([string]::IsNullOrWhiteSpace($rel)) { return "." }
    return $rel.TrimEnd("/")
}

function Escape-Html {
    param([AllowNull()][string]$Value)
    return [System.Net.WebUtility]::HtmlEncode($Value)
}

function Format-Bytes {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return "{0:N2} Go" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N2} Mo" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N1} Ko" -f ($Bytes / 1KB) }
    return "$Bytes o"
}

function Get-ImageInfo {
    param([System.IO.FileInfo]$File)
    $width = 0
    $height = 0
    try {
        $img = [System.Drawing.Image]::FromFile($File.FullName)
        try {
            $width = $img.Width
            $height = $img.Height
        }
        finally {
            $img.Dispose()
        }
    }
    catch {
        $width = 0
        $height = 0
    }

    [PSCustomObject]@{
        Name = $File.Name
        FullName = $File.FullName
        Directory = $File.DirectoryName
        Extension = $File.Extension.ToLowerInvariant()
        Size = $File.Length
        SizeText = Format-Bytes $File.Length
        Width = $width
        Height = $height
        Dimensions = if ($width -gt 0 -and $height -gt 0) { "${width} x ${height} px" } else { "dimensions indisponibles" }
    }
}

function Get-MediaInfo {
    param([System.IO.FileInfo]$File)
    [PSCustomObject]@{
        Name = $File.Name
        FullName = $File.FullName
        Directory = $File.DirectoryName
        Extension = $File.Extension.ToLowerInvariant()
        Size = $File.Length
        SizeText = Format-Bytes $File.Length
    }
}

function Get-ExternalHead {
@'
<link rel="canonical" href="https://filedn.eu/llN3kr5vmyEBPIWCwFj3O6h/">
<link rel="icon" href="https://filedn.eu/llN3kr5vmyEBPIWCwFj3O6h/Site_Web/favicondepascal.png" type="image/png">
<link rel="icon" href="https://filedn.eu/llN3kr5vmyEBPIWCwFj3O6h/Site_Web/favicondepascal.ico" type="image/x-icon">
<!-- Lier le menu social -->
<link rel="stylesheet" type="text/css" href="https://filedn.eu/llN3kr5vmyEBPIWCwFj3O6h/Site_Web/style.css">
<script src="https://filedn.eu/llN3kr5vmyEBPIWCwFj3O6h/Site_Web/script.js"></script>
<!-- Lier le fichier JavaScript du menu -->
<script src="https://filedn.eu/llN3kr5vmyEBPIWCwFj3O6h/Site_Web/menu.js" defer></script>
<link rel="stylesheet" href="https://filedn.eu/llN3kr5vmyEBPIWCwFj3O6h/Site_Web/basedusite.css">
'@
}

function Get-SocialBody {
@'
<!-- menu social -->
<nav class="social-menu">
  <ul>
    <li><a href="https://fr.pinterest.com/pascal509/mes-tableaux-tous-genre/" target="_blank">Pinterest</a></li>
    <li><a href="https://www.flickr.com/photos/delfossepascal" target="_blank">Flickr</a></li>
    <li><a href="https://www.tumblr.com/lestoilesdepascal" target="_blank">Tumblr</a></li>
    <li><a href="https://x.com/PascalDelfossee" target="_blank">X</a></li>
    <li><a href="https://www.youtube.com/c/DelfossePascal" target="_blank">YouTube</a></li>
  </ul>
</nav>

<!-- Le menu sera injecte ici -->
<header></header>
'@
}

function Get-Head {
    param(
        [string]$Title,
        [string]$PageDir
    )
    $prefix = Get-RelativePrefix -PageDir $PageDir
    $css = ConvertTo-PosixPath "$prefix/site-assets/site.css"
    $js = ConvertTo-PosixPath "$prefix/site-assets/site.js"
    $external = Get-ExternalHead
@"
<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$(Escape-Html $Title)</title>
  $external
  <link rel="stylesheet" href="$css">
  <script src="$js" defer></script>
</head>
"@
}

function Get-ThemeButton {
@'
<button class="theme-toggle" type="button" data-theme-toggle aria-label="Basculer le mode clair ou sombre">Mode clair / sombre</button>
'@
}

function Get-HomeButton {
    param([string]$PageDir)
    $prefix = Get-RelativePrefix -PageDir $PageDir
    $href = ConvertTo-PosixPath "$prefix/index.html"
    return "<a class=""home-button"" href=""$href"">Retour a l'accueil</a>"
}

function Get-PageFrameStart {
    param(
        [string]$Title,
        [string]$PageDir,
        [string]$ClassName
    )
    $head = Get-Head -Title $Title -PageDir $PageDir
    $social = Get-SocialBody
    $theme = Get-ThemeButton
    $homeLink = Get-HomeButton -PageDir $PageDir
@"
$head
<body class="$ClassName">
$social
<div class="top-actions">
  $homeLink
  $theme
</div>
<main>
"@
}

function Get-PageFrameEnd {
@'
</main>
<div class="lightbox" data-lightbox hidden>
  <button class="lightbox-close" type="button" data-lightbox-close aria-label="Fermer">Fermer</button>
  <div class="lightbox-stage" data-lightbox-stage></div>
  <p class="lightbox-caption" data-lightbox-caption></p>
</div>
</body>
</html>
'@
}

function Get-NavLinks {
    param(
        [array]$PageFiles,
        [int]$Current,
        [string]$PageDir
    )
    if ($PageFiles.Count -le 1) { return "" }
    $links = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $PageFiles.Count; $i++) {
        $label = $i + 1
        $cls = if ($i -eq $Current) { " class=""is-current""" } else { "" }
        $href = ConvertTo-PosixPath ([System.IO.Path]::GetFileName($PageFiles[$i]))
        $links.Add("<a$cls href=""$href"">Page $label</a>")
    }
    return "<nav class=""pager"" aria-label=""Pages de galerie"">$($links -join "`n")</nav>"
}

function Get-ImageCard {
    param(
        [object]$Image,
        [string]$PageDir
    )
    $src = ConvertTo-PosixPath (Get-RelativePath -From $PageDir -To $Image.FullName)
    $name = Escape-Html $Image.Name
    $meta = Escape-Html "$($Image.SizeText) - $($Image.Dimensions)"
@"
<figure class="media-card pop-card">
  <button class="media-open" type="button" data-lightbox-src="$src" data-lightbox-type="image" data-lightbox-caption="$name - $meta">
    <img src="$src" alt="$name" loading="lazy">
  </button>
  <figcaption>
    <strong>$name</strong>
    <span>$meta</span>
  </figcaption>
</figure>
"@
}

function Get-AudioCard {
    param(
        [object]$Audio,
        [string]$PageDir
    )
    $src = ConvertTo-PosixPath (Get-RelativePath -From $PageDir -To $Audio.FullName)
    $name = Escape-Html $Audio.Name
    $meta = Escape-Html $Audio.SizeText
@"
<article class="audio-card pop-card">
  <div>
    <h2>$name</h2>
    <p>$meta</p>
  </div>
  <button class="music-button" type="button" data-audio-toggle data-audio-src="$src" data-audio-title="$name">Lancer la musique</button>
  <audio class="inline-audio" hidden preload="none" src="$src"></audio>
</article>
"@
}

function Get-Variant {
    param([string]$Name)
    $variants = @("variant-speed", "variant-bubbles", "variant-panels", "variant-trame", "variant-flash")
    $sum = 0
    foreach ($ch in $Name.ToCharArray()) { $sum += [int][char]$ch }
    return $variants[$sum % $variants.Count]
}

function New-GalleryPages {
    param(
        [string]$Dir,
        [array]$Images,
        [array]$AllPages
    )

    $folderName = Split-Path $Dir -Leaf
    $pageCount = [Math]::Ceiling($Images.Count / $PageSize)
    $pageFiles = @()
    for ($p = 0; $p -lt $pageCount; $p++) {
        if ($p -eq 0) { $pageFiles += (Join-Path $Dir "index.html") }
        else { $pageFiles += (Join-Path $Dir ("page-{0}.html" -f ($p + 1))) }
    }

    for ($p = 0; $p -lt $pageCount; $p++) {
        $start = $p * $PageSize
        $slice = $Images | Select-Object -Skip $start -First $PageSize
        $currentFile = $pageFiles[$p]
        $title = if ($pageCount -gt 1) { "$folderName - page $($p + 1)" } else { $folderName }
        $variant = Get-Variant -Name $folderName
        $html = New-Object System.Text.StringBuilder
        [void]$html.AppendLine((Get-PageFrameStart -Title $title -PageDir $Dir -ClassName "gallery-page $variant"))
        [void]$html.AppendLine("<section class=""hero comic-hero"">")
        [void]$html.AppendLine("<p class=""kicker"">Galerie locale</p>")
        [void]$html.AppendLine("<h1>$(Escape-Html $folderName)</h1>")
        [void]$html.AppendLine("<p>Ce dossier rassemble $($Images.Count) image(s) exploitable(s). Les fichiers sont presentes en miniatures avec leur poids et leurs dimensions; un clic ouvre l'image en grand, et la touche Echappe ferme l'affichage.</p>")
        [void]$html.AppendLine("<div class=""hero-stats""><span>$($slice.Count) elements sur cette page</span><span>$($p + 1) / $pageCount</span></div>")
        [void]$html.AppendLine("</section>")
        [void]$html.AppendLine((Get-NavLinks -PageFiles $pageFiles -Current $p -PageDir $Dir))
        [void]$html.AppendLine("<section class=""gallery-grid"">")
        foreach ($image in $slice) {
            [void]$html.AppendLine((Get-ImageCard -Image $image -PageDir $Dir))
        }
        [void]$html.AppendLine("</section>")
        [void]$html.AppendLine((Get-NavLinks -PageFiles $pageFiles -Current $p -PageDir $Dir))
        [void]$html.AppendLine((Get-PageFrameEnd))
        [System.IO.File]::WriteAllText($currentFile, $html.ToString(), [System.Text.UTF8Encoding]::new($false))
    }

    foreach ($file in $pageFiles) {
        $AllPages += [PSCustomObject]@{
            Title = if ($file -like "*page-*") { "$folderName - $([System.IO.Path]::GetFileNameWithoutExtension($file))" } else { $folderName }
            Path = $file
            Directory = $Dir
            Kind = "Images"
            Count = $Images.Count
            Thumb = $Images[0].FullName
            Shape = Get-Variant -Name (Split-Path $file -Leaf)
        }
    }
    return $AllPages
}

function New-AudioPage {
    param(
        [string]$Dir,
        [array]$AudioFiles,
        [array]$AllPages
    )
    $folderName = Split-Path $Dir -Leaf
    $html = New-Object System.Text.StringBuilder
    [void]$html.AppendLine((Get-PageFrameStart -Title $folderName -PageDir $Dir -ClassName "audio-page variant-flash"))
    [void]$html.AppendLine("<section class=""hero audio-hero"">")
    [void]$html.AppendLine("<p class=""kicker"">Playlist locale</p>")
    [void]$html.AppendLine("<h1>$(Escape-Html $folderName)</h1>")
    [void]$html.AppendLine("<p>Ce dossier contient $($AudioFiles.Count) piste(s) audio. Aucune lecture automatique n'est active : le bouton rouge lance ou arrete la piste, sans afficher de lecteur.</p>")
    [void]$html.AppendLine("</section>")
    [void]$html.AppendLine("<section class=""audio-list"">")
    foreach ($audio in $AudioFiles) {
        [void]$html.AppendLine((Get-AudioCard -Audio $audio -PageDir $Dir))
    }
    [void]$html.AppendLine("</section>")
    [void]$html.AppendLine((Get-PageFrameEnd))
    $file = Join-Path $Dir "index.html"
    [System.IO.File]::WriteAllText($file, $html.ToString(), [System.Text.UTF8Encoding]::new($false))
    $AllPages += [PSCustomObject]@{
        Title = $folderName
        Path = $file
        Directory = $Dir
        Kind = "Audio"
        Count = $AudioFiles.Count
        Thumb = $null
        Shape = "variant-flash"
    }
    return $AllPages
}

function New-HubPage {
    param(
        [string]$Dir,
        [array]$Children,
        [array]$AllPages
    )
    $folderName = Split-Path $Dir -Leaf
    $html = New-Object System.Text.StringBuilder
    [void]$html.AppendLine((Get-PageFrameStart -Title $folderName -PageDir $Dir -ClassName "hub-page variant-panels"))
    [void]$html.AppendLine("<section class=""hero hub-hero"">")
    [void]$html.AppendLine("<p class=""kicker"">Carrefour local</p>")
    [void]$html.AppendLine("<h1>$(Escape-Html $folderName)</h1>")
    [void]$html.AppendLine("<p>Cette page rassemble les sous-dossiers exploitables et permet de circuler sans connexion Internet entre les galeries reliees.</p>")
    [void]$html.AppendLine("</section>")
    [void]$html.AppendLine("<section class=""page-tiles"">")
    foreach ($child in $Children) {
        $href = ConvertTo-PosixPath (Get-RelativePath -From $Dir -To $child.Path)
        $title = Escape-Html $child.Title
        $kind = Escape-Html "$($child.Kind) - $($child.Count) element(s)"
        [void]$html.AppendLine("<a class=""tile $(Escape-Html $child.Shape)"" href=""$href""><span>$title</span><small>$kind</small></a>")
    }
    [void]$html.AppendLine("</section>")
    [void]$html.AppendLine((Get-PageFrameEnd))
    $file = Join-Path $Dir "index.html"
    [System.IO.File]::WriteAllText($file, $html.ToString(), [System.Text.UTF8Encoding]::new($false))
    $AllPages += [PSCustomObject]@{
        Title = $folderName
        Path = $file
        Directory = $Dir
        Kind = "Hub"
        Count = $Children.Count
        Thumb = $Children | Where-Object { $_.Thumb } | Select-Object -First 1 -ExpandProperty Thumb
        Shape = "variant-panels"
    }
    return $AllPages
}

function New-HomePage {
    param(
        [array]$Pages,
        [array]$AudioFiles
    )
    $thumbnailRoot = Join-Path $Root "thumbnail"
    $homeThumbs = @()
    if (Test-Path $thumbnailRoot) {
        $homeThumbs = @(Get-ChildItem -Path $thumbnailRoot -Recurse -File -Include *.jpg,*.jpeg,*.png |
            Where-Object { $_.Length -gt 30000 } |
            Sort-Object FullName)
    }
    $html = New-Object System.Text.StringBuilder
    [void]$html.AppendLine((Get-PageFrameStart -Title "TexTures 2026 - Accueil" -PageDir $Root -ClassName "home-page variant-bubbles"))
    [void]$html.AppendLine("<section class=""home-hero"">")
    [void]$html.AppendLine("<div>")
    [void]$html.AppendLine("<p class=""kicker"">Site local</p>")
    [void]$html.AppendLine("<h1>TexTures 2026</h1>")
    [void]$html.AppendLine("<p>Accueil general des textures, vignettes et musiques du projet. Les galeries restent conservees localement et l'accueil relie les pages disponibles sur cette machine, avec miniatures, navigation et musique manuelle.</p>")
    [void]$html.AppendLine("</div>")
    [void]$html.AppendLine("<div class=""sound-panel"" id=""musique"">")
    if ($AudioFiles.Count -gt 0) {
        $audio = $AudioFiles[0]
        $src = ConvertTo-PosixPath (Get-RelativePath -From $Root -To $audio.FullName)
        [void]$html.AppendLine("<button class=""music-button home-music"" type=""button"" data-audio-toggle data-audio-src=""$src"" data-audio-title=""$(Escape-Html $audio.Name)"">Musique</button>")
        [void]$html.AppendLine("<audio class=""inline-audio"" hidden preload=""none"" src=""$src""></audio>")
        [void]$html.AppendLine("<p>Lecture manuelle uniquement. Le bouton rouge lance ou arrete la premiere piste disponible.</p>")
    }
    else {
        [void]$html.AppendLine("<button class=""music-button home-music"" type=""button"" disabled>Musique</button>")
        [void]$html.AppendLine("<p>Aucune piste audio locale detectee.</p>")
    }
    [void]$html.AppendLine("</div>")
    [void]$html.AppendLine("</section>")
    [void]$html.AppendLine("<section class=""page-tiles home-tiles"" id=""galeries"">")
    $i = 0
    foreach ($page in ($Pages | Where-Object { $_.Path -ne (Join-Path $Root "index.html") })) {
        $href = ConvertTo-PosixPath (Get-RelativePath -From $Root -To $page.Path)
        $title = Escape-Html $page.Title
        $kind = Escape-Html "$($page.Kind) - $($page.Count) element(s)"
        $shapeClass = @("shape-round", "shape-wide", "shape-square", "shape-ticket")[$i % 4]
        $variant = Escape-Html $page.Shape
        $tileThumb = $null
        if ($homeThumbs.Count -gt 0) {
            $tileThumb = $homeThumbs[$i % $homeThumbs.Count].FullName
        }
        elseif ($page.Thumb) {
            $tileThumb = $page.Thumb
        }
        if ($tileThumb) {
            $thumb = ConvertTo-PosixPath (Get-RelativePath -From $Root -To $tileThumb)
            [void]$html.AppendLine("<a class=""tile thumb-tile $shapeClass $variant"" href=""$href""><img class=""tile-image"" src=""$thumb"" alt="""" loading=""lazy""><span>$title</span><small>$kind</small></a>")
        }
        else {
            [void]$html.AppendLine("<a class=""tile $shapeClass $variant"" href=""$href""><span>$title</span><small>$kind</small></a>")
        }
        $i++
    }
    [void]$html.AppendLine("</section>")
    [void]$html.AppendLine((Get-PageFrameEnd))
    $file = Join-Path $Root "index.html"
    [System.IO.File]::WriteAllText($file, $html.ToString(), [System.Text.UTF8Encoding]::new($false))
}

$assetDir = Join-Path $Root "site-assets"
New-Item -ItemType Directory -Force -Path $assetDir | Out-Null

$css = @'
:root {
  color-scheme: light dark;
  --white: #ffffff;
  --black: #050505;
  --red: #e00022;
  --blue: #0057ff;
  --paper: #fffdf7;
  --ink: #050505;
  --panel: rgba(255, 255, 255, 0.86);
  --line: #050505;
  --shadow: 8px 8px 0 #050505;
}

:root[data-theme="dark"] {
  --paper: #050505;
  --ink: #ffffff;
  --panel: rgba(5, 5, 5, 0.86);
  --line: #ffffff;
  --shadow: 8px 8px 0 #0057ff;
}

* { box-sizing: border-box; }

html { scroll-behavior: smooth; }

body {
  margin: 0;
  min-height: 100vh;
  color: var(--ink);
  background:
    radial-gradient(circle at 12% 18%, rgba(224, 0, 34, 0.22) 0 10px, transparent 11px),
    radial-gradient(circle at 82% 16%, rgba(0, 87, 255, 0.22) 0 13px, transparent 14px),
    linear-gradient(115deg, transparent 0 78%, rgba(224, 0, 34, 0.16) 78% 80%, transparent 80%),
    repeating-linear-gradient(0deg, transparent 0 14px, rgba(0, 0, 0, 0.08) 15px 16px),
    var(--paper);
  font-family: "Segoe Script", "Brush Script MT", "Lucida Handwriting", cursive;
  letter-spacing: 0;
}

a { color: inherit; }

.social-menu,
body > header {
  width: min(1120px, calc(100% - 24px));
  margin: 12px auto 0;
  text-align: center;
  position: relative;
  z-index: 3;
}

.social-menu ul,
body > header nav ul {
  list-style: none;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-wrap: wrap;
  gap: 8px;
  padding: 8px;
  margin: 0;
  background: var(--panel);
  border: 3px solid var(--line);
  box-shadow: 5px 5px 0 var(--red);
}

.social-menu a,
body > header a,
.home-button,
.theme-toggle,
.pager a,
.music-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  min-height: 42px;
  padding: 8px 14px;
  border: 3px solid var(--line);
  background: var(--white);
  color: var(--black);
  text-decoration: none;
  font-weight: 800;
  cursor: pointer;
  box-shadow: 4px 4px 0 var(--blue);
  transition: transform .18s ease, box-shadow .18s ease, background .18s ease;
}

.social-menu a:hover,
body > header a:hover,
.home-button:hover,
.theme-toggle:hover,
.pager a:hover,
.music-button:hover {
  transform: translate(-2px, -2px) rotate(-1deg);
  box-shadow: 7px 7px 0 var(--red);
}

.top-actions {
  width: min(1120px, calc(100% - 24px));
  margin: 14px auto;
  display: flex;
  justify-content: center;
  flex-wrap: wrap;
  gap: 10px;
}

main {
  width: min(1240px, calc(100% - 24px));
  margin: 0 auto 60px;
}

.hero,
.home-hero {
  border: 4px solid var(--line);
  box-shadow: var(--shadow);
  background:
    linear-gradient(135deg, rgba(255,255,255,.9), rgba(255,255,255,.72)),
    repeating-linear-gradient(45deg, rgba(0,87,255,.22) 0 8px, transparent 9px 18px);
  color: var(--black);
  padding: clamp(22px, 5vw, 58px);
  margin: 20px 0 28px;
  position: relative;
  overflow: hidden;
}

:root[data-theme="dark"] .hero,
:root[data-theme="dark"] .home-hero {
  background:
    linear-gradient(135deg, rgba(5,5,5,.88), rgba(5,5,5,.72)),
    repeating-linear-gradient(45deg, rgba(0,87,255,.4) 0 8px, transparent 9px 18px);
  color: var(--white);
}

.hero::after,
.home-hero::after {
  content: "WOW!";
  position: absolute;
  right: clamp(12px, 5vw, 54px);
  top: clamp(12px, 5vw, 42px);
  color: var(--red);
  font-size: clamp(2rem, 8vw, 6rem);
  font-weight: 900;
  transform: rotate(8deg);
  opacity: .2;
  animation: pulseWord 2.8s ease-in-out infinite;
}

.kicker {
  display: inline-block;
  padding: 4px 12px;
  background: var(--red);
  color: var(--white);
  border: 3px solid var(--line);
  font-weight: 900;
  transform: rotate(-1deg);
}

h1 {
  max-width: 920px;
  margin: 12px 0;
  font-size: clamp(2.4rem, 8vw, 6.8rem);
  line-height: .98;
}

.hero p,
.home-hero p {
  max-width: 780px;
  font-family: "Segoe UI", Arial, sans-serif;
  font-size: 1.05rem;
  line-height: 1.65;
  font-weight: 700;
}

.hero-stats {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 18px;
  font-family: "Segoe UI", Arial, sans-serif;
}

.hero-stats span {
  background: var(--blue);
  color: var(--white);
  border: 3px solid var(--line);
  padding: 7px 12px;
  font-weight: 900;
}

.pager {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 8px;
  margin: 22px 0;
}

.pager .is-current {
  background: var(--red);
  color: var(--white);
  box-shadow: 4px 4px 0 var(--black);
}

.gallery-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(170px, 1fr));
  gap: 18px;
  align-items: stretch;
}

.media-card,
.audio-card,
.tile {
  background: var(--panel);
  border: 4px solid var(--line);
  box-shadow: 6px 6px 0 var(--blue);
  position: relative;
  overflow: hidden;
}

.pop-card {
  animation: floatPanel 5s ease-in-out infinite;
}

.media-card:nth-child(3n) { animation-delay: .35s; }
.media-card:nth-child(4n) { animation-delay: .7s; }

.media-open {
  display: block;
  width: 100%;
  padding: 0;
  border: 0;
  background: transparent;
  cursor: zoom-in;
}

.media-card img {
  display: block;
  width: 100%;
  aspect-ratio: 1 / 1;
  object-fit: cover;
  background: var(--white);
  transition: transform .35s ease;
}

.media-card:hover img {
  transform: scale(1.06) rotate(.6deg);
}

figcaption {
  display: grid;
  gap: 5px;
  padding: 10px;
  font-family: "Segoe UI", Arial, sans-serif;
  background: var(--panel);
}

figcaption strong,
.tile span,
.audio-card h2 {
  overflow-wrap: anywhere;
}

figcaption span,
.tile small,
.audio-card p {
  font-size: .88rem;
  font-weight: 800;
}

.audio-list {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 18px;
}

.audio-card {
  padding: 18px;
  display: grid;
  gap: 14px;
}

.music-button {
  background: var(--red);
  color: var(--white);
  border-color: var(--black);
  font-family: "Segoe Script", "Brush Script MT", cursive;
}

.music-button.is-playing {
  background: var(--blue);
  color: var(--white);
  box-shadow: 4px 4px 0 var(--red);
}

.home-hero {
  min-height: 430px;
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(220px, 320px);
  gap: 24px;
  align-items: center;
}

.sound-panel {
  padding: 20px;
  border: 4px solid var(--line);
  background: var(--white);
  color: var(--black);
  box-shadow: 7px 7px 0 var(--red);
  transform: rotate(2deg);
}

.page-tiles {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 18px;
}

.tile {
  min-height: 170px;
  padding: 18px;
  display: flex;
  flex-direction: column;
  justify-content: end;
  text-decoration: none;
  color: var(--white);
  background:
    repeating-linear-gradient(135deg, rgba(0, 87, 255, .8) 0 12px, rgba(224, 0, 34, .82) 13px 24px);
  background-size: cover;
  background-position: center;
  transition: transform .22s ease, box-shadow .22s ease;
}

.tile::after {
  content: "";
  position: absolute;
  inset: 0;
  z-index: 1;
  background: linear-gradient(180deg, rgba(0,0,0,.02), rgba(0,0,0,.5));
  pointer-events: none;
}

.tile-image {
  position: absolute;
  inset: 0;
  z-index: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  filter: saturate(1.15) contrast(1.08);
  transition: transform .3s ease;
}

.tile:hover {
  transform: translateY(-6px) rotate(-1deg);
  box-shadow: 10px 10px 0 var(--red);
}

.tile:hover .tile-image {
  transform: scale(1.08);
}

.tile span {
  position: relative;
  z-index: 2;
  font-size: 1.4rem;
  line-height: 1.08;
  text-shadow: 2px 2px 0 var(--black);
}

.tile small {
  position: relative;
  z-index: 2;
  font-family: "Segoe UI", Arial, sans-serif;
  margin-top: 8px;
  text-shadow: 1px 1px 0 var(--black);
}

.shape-round { border-radius: 50%; aspect-ratio: 1 / 1; }
.shape-wide { grid-column: span 2; min-height: 190px; }
.shape-square { aspect-ratio: 1 / 1; }
.shape-ticket { border-radius: 0 38px 0 38px; }

.variant-speed .hero { clip-path: polygon(0 0, 100% 0, 96% 100%, 0 94%); }
.variant-bubbles .tile { border-radius: 44px; }
.variant-panels .hero { box-shadow: 12px 12px 0 var(--red); }
.variant-trame .gallery-grid { background: radial-gradient(circle, rgba(0,0,0,.18) 1px, transparent 2px); background-size: 12px 12px; padding: 10px; }
.variant-flash .hero { transform: rotate(-.4deg); }

.lightbox[hidden] { display: none; }

.lightbox {
  position: fixed;
  inset: 0;
  z-index: 20;
  display: grid;
  grid-template-rows: auto 1fr auto;
  gap: 10px;
  padding: 18px;
  background: rgba(0, 0, 0, .9);
  color: var(--white);
}

.lightbox-close {
  justify-self: end;
  background: var(--red);
  color: var(--white);
  border: 3px solid var(--white);
  padding: 10px 16px;
  font-weight: 900;
  cursor: pointer;
}

.lightbox-stage {
  display: grid;
  place-items: center;
  min-height: 0;
}

.lightbox-stage img,
.lightbox-stage video {
  max-width: 96vw;
  max-height: 78vh;
  object-fit: contain;
  border: 4px solid var(--white);
  background: var(--black);
}

.lightbox-stage audio {
  width: min(720px, 92vw);
}

.lightbox-caption {
  text-align: center;
  font-family: "Segoe UI", Arial, sans-serif;
  font-weight: 800;
}

@keyframes pulseWord {
  0%, 100% { transform: rotate(8deg) scale(1); }
  50% { transform: rotate(5deg) scale(1.08); }
}

@keyframes floatPanel {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-4px); }
}

@media (max-width: 760px) {
  .home-hero { grid-template-columns: 1fr; }
  .shape-wide { grid-column: span 1; }
  h1 { font-size: clamp(2.2rem, 16vw, 4rem); }
  .gallery-grid { grid-template-columns: repeat(auto-fit, minmax(135px, 1fr)); }
}
'@

$js = @'
(function () {
  const root = document.documentElement;
  const savedTheme = localStorage.getItem("textures-theme");
  if (savedTheme) root.dataset.theme = savedTheme;

  function ensureHeaderMenu() {
    const header = document.querySelector("body > header");
    if (!header) return;
    const hasExternalMenu = Array.from(header.children).some((child) => child.dataset.localMenu !== "fallback");
    if (hasExternalMenu) {
      const fallback = header.querySelector('[data-local-menu="fallback"]');
      if (fallback) fallback.remove();
      return;
    }
    if (!header.querySelector('[data-local-menu="fallback"]')) {
      header.insertAdjacentHTML("beforeend", '<nav data-local-menu="fallback" aria-label="Menu local"><ul><li><a href="' + localHomeHref() + '">Accueil</a></li><li><a href="' + localHomeHref() + '#galeries">Galeries</a></li><li><a href="' + localHomeHref() + '#musique">Musique</a></li></ul></nav>');
    }
  }

  function localHomeHref() {
    const home = document.querySelector(".home-button");
    return home ? home.getAttribute("href") : "index.html";
  }

  function toggleTheme() {
    const next = root.dataset.theme === "dark" ? "light" : "dark";
    root.dataset.theme = next;
    localStorage.setItem("textures-theme", next);
  }

  const lightbox = document.querySelector("[data-lightbox]");
  const stage = document.querySelector("[data-lightbox-stage]");
  const caption = document.querySelector(".lightbox-caption");
  let activeAudio = null;
  let activeAudioButton = null;

  function resetAudioButton(button) {
    if (!button) return;
    button.classList.remove("is-playing");
    button.textContent = button.classList.contains("home-music") ? "Musique" : "Lancer la musique";
    button.setAttribute("aria-pressed", "false");
  }

  function stopActiveAudio() {
    if (activeAudio) {
      activeAudio.pause();
      activeAudio.currentTime = 0;
      activeAudio = null;
    }
    resetAudioButton(activeAudioButton);
    activeAudioButton = null;
  }

  function getAudioForButton(button) {
    const localAudio = button.parentElement ? button.parentElement.querySelector(".inline-audio") : null;
    if (localAudio) return localAudio;
    const src = button.dataset.audioSrc;
    if (!src) return null;
    const audio = document.createElement("audio");
    audio.className = "inline-audio";
    audio.hidden = true;
    audio.preload = "none";
    audio.src = src;
    button.insertAdjacentElement("afterend", audio);
    return audio;
  }

  function toggleAudio(button) {
    const audio = getAudioForButton(button);
    if (!audio) return;
    if (activeAudioButton === button && activeAudio && !activeAudio.paused) {
      stopActiveAudio();
      return;
    }
    stopActiveAudio();
    activeAudio = audio;
    activeAudioButton = button;
    button.classList.add("is-playing");
    button.textContent = "Arreter la musique";
    button.setAttribute("aria-pressed", "true");
    activeAudio.addEventListener("ended", stopActiveAudio, { once: true });
    activeAudio.play().catch(() => {
      stopActiveAudio();
      resetAudioButton(button);
    });
  }

  function bindAudioButtons() {
    document.querySelectorAll("[data-audio-toggle]").forEach((button) => {
      if (button.dataset.audioBound === "true") return;
      button.dataset.audioBound = "true";
      button.setAttribute("aria-pressed", "false");
      button.addEventListener("click", (event) => {
        event.preventDefault();
        event.stopPropagation();
        toggleAudio(button);
      });
    });
  }

  function closeLightbox() {
    if (!lightbox || !stage) return;
    stage.querySelectorAll("audio, video").forEach((media) => media.pause());
    stage.innerHTML = "";
    lightbox.hidden = true;
    document.body.style.overflow = "";
  }

  function openLightbox(src, type, text) {
    if (!lightbox || !stage) return;
    stage.innerHTML = "";
    let element;
    if (type === "audio") {
      element = document.createElement("audio");
      element.controls = true;
      element.autoplay = false;
      element.src = src;
    } else if (type === "video") {
      element = document.createElement("video");
      element.controls = true;
      element.autoplay = false;
      element.src = src;
    } else {
      element = document.createElement("img");
      element.src = src;
      element.alt = text || "Image agrandie";
    }
    stage.appendChild(element);
    if (caption) caption.textContent = text || "";
    lightbox.hidden = false;
    document.body.style.overflow = "hidden";
    if (type === "audio" || type === "video") element.focus();
  }

  document.addEventListener("click", (event) => {
    const themeButton = event.target.closest("[data-theme-toggle]");
    if (themeButton) {
      toggleTheme();
      return;
    }

    const closeButton = event.target.closest("[data-lightbox-close]");
    if (closeButton || event.target === lightbox) {
      closeLightbox();
      return;
    }

    const opener = event.target.closest("[data-lightbox-src]");
    if (opener) {
      openLightbox(opener.dataset.lightboxSrc, opener.dataset.lightboxType || "image", opener.dataset.lightboxCaption || "");
    }
  }, true);

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") closeLightbox();
  });

  window.addEventListener("beforeunload", stopActiveAudio);

  bindAudioButtons();
  ensureHeaderMenu();
  const header = document.querySelector("body > header");
  if (header) {
    const observer = new MutationObserver(() => ensureHeaderMenu());
    observer.observe(header, { childList: true });
  }
})();
'@

[System.IO.File]::WriteAllText((Join-Path $assetDir "site.css"), $css, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $assetDir "site.js"), $js, [System.Text.UTF8Encoding]::new($false))

$allFiles = Get-ChildItem -Path $Root -Recurse -File | Where-Object {
    $_.FullName -notmatch "\\\.git\\" -and
    $_.FullName -notmatch "\\site-assets\\" -and
    $_.FullName -notmatch "\\tools\\" -and
    $_.Name -ne "index.html" -and
    $_.Name -notmatch "^page-\d+\.html$"
}

$imagesByDir = $allFiles | Where-Object { $imageExtensions -contains $_.Extension.ToLowerInvariant() } | Sort-Object FullName | ForEach-Object { Get-ImageInfo $_ } | Group-Object Directory
$audioByDir = $allFiles | Where-Object { $audioExtensions -contains $_.Extension.ToLowerInvariant() } | Sort-Object FullName | ForEach-Object { Get-MediaInfo $_ } | Group-Object Directory
$allAudio = $allFiles | Where-Object { $audioExtensions -contains $_.Extension.ToLowerInvariant() } | Sort-Object FullName | ForEach-Object { Get-MediaInfo $_ }

$pages = @()

foreach ($group in $imagesByDir) {
    $pages = New-GalleryPages -Dir $group.Name -Images $group.Group -AllPages $pages
}

foreach ($group in $audioByDir) {
    $pages = New-AudioPage -Dir $group.Name -AudioFiles $group.Group -AllPages $pages
}

$thumbnailDir = Join-Path $Root "thumbnail"
if (Test-Path $thumbnailDir) {
    $children = $pages | Where-Object {
        $_.Directory -like "$thumbnailDir\*" -and
        ((Split-Path $_.Directory -Parent) -eq $thumbnailDir) -and
        (Split-Path $_.Path -Leaf) -eq "index.html"
    }
    if ($children.Count -gt 0) {
        $pages = New-HubPage -Dir $thumbnailDir -Children $children -AllPages $pages
    }
}

New-HomePage -Pages $pages -AudioFiles $allAudio

Write-Host "Site genere : $($pages.Count + 1) pages principales et paginees, assets locaux dans site-assets."
