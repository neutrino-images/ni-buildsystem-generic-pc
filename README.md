# NI \o/ - Neutrino für PC bauen #

## 1) Repository clonen
```bash
git clone https://github.com/neutrino-images/ni-buildsystem-generic-pc.git
cd ni-buildsystem-generic-pc
```

## 2) Prerequisites und Dependencies erfüllen.
Siehe Makefile!


## 3) Build konfigurieren
```bash
make local-files
```

## 4) libdvbsi++, lua und ffmpeg bauen.
```bash
make deps
```
oder
```bash
make libdvbsi lua ffmpeg
```

## 5) Neutrino bauen
```bash
make neutrino
```

## 6) Neutrino starten
```bash
make run
```

## 7) Aktualisieren und sauber machen
```bash
make update
make clean
```
