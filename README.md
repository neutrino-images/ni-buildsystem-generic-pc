# NI \o/ - Neutrino für PC bauen #

## 1) Repository clonen
```bash
git clone https://github.com/neutrino-images/ni-build-generic-pc.git
cd ni-build-generic-pc
```

## 2) Prerequisites und Dependencies erfüllen.
Siehe Makefile!

## 3) libdvbsi++, lua und ffmpeg bauen.
```bash
make deps
```
oder
```bash
make libdvbsi lua ffmpeg
```

## 4) Neutrino bauen
```bash
make neutrino
```

## 5) Neutrino starten
```bash
make run
```

## 6) Aktualisieren und sauber machen
```bash
make update
make clean
```
