**NI-Neutrino für PC bauen**

# 1) Repository clonen #
```
git clone https://github.com/neutrino-images/ni-build-generic-pc.git
cd ni-build-generic-pc
```

# 2) Prerequisites und Dependencies erfüllen. #
Siehe Makefile!

# 3) libdvbsi++, lua und ffmpeg bauen #
```
make deps
```
oder
```
make libdvbsi lua ffmpeg
```

# 4) Neutrino bauen #
```
make neutrino
```

# 5) Neutrino starten #
```
make run
```

# 6) Aktualisieren und sauber machen #
```
make update
make clean
```
