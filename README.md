# Physically Based Rendering Minecraft Mod
Diese Mod erweitert Minecraft um ein Physically Based Rendering System. Dieses basiert im Kern auf der Implementation eines Screen-Space Raytracing Algorithmus für die Berechnung von Reflektionen auf den Minecraft Blöcken. Nähere Details können im Paper **spiegelblöcke.pdf** gefunden werden. 

![alt tag](https://raw.githubusercontent.com/Ochrazy/PBR-Minecraft-Mod/master/spiegelbloecke/pbr.png)

## Installation:
- Optifine in Version 1.8.9 installieren
- Ordner "spiegelbloecke" nach .minecraft/shaderpacks kopieren (auf jeden Fall entzippt!)
- Shader in Minecraft aktivieren


## Block-Effekt-Zuordnungen:

- Eisenblock: Halbspiegelnd, 50% Blur, halbe Fresnel Power 
- Goldblock: 80% Spiegelnd, kleine Fresnel Power
- Diamantblock: Vollspiegelnd, gebogener Spiegel		
- Golderzblock: 80% reflektierend
- Eisenerzblock: 40% reflektierend
- Kohleerzblock: 25% reflektierend
- Purer Stein: Vollspiegelnd, mit Fresnel
- Cobblestone: Vollspiegelnd, 50% Blur
- Kies(Gravel): Vollspiegelnd, 100% Blur
- Emeraldblock: Vollspiegelnd, Celshading
- Quartzblock: Vollspiegelnd, Sepia
- Kohleblock: Vollspiegelnd, Schwarz-Weiß
- Und ein paar andere zum Herausfinden ;)
