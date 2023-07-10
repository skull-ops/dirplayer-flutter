# dirplayer

A Flutter implementation of Shockwave player. This project is no longer being actively developed as Flutter has very poor performace when displaying raw in-memory images, which is part of the core functionality of Shockwave. PRs and contributions are welcome, especially if you find a way to work around the limitations around image displaying.

This project would have not been possible without the extensive work of the Shockwave reverse engineering community. 

A lot of code has been reproduced from the following projects:

https://github.com/Earthquake-Project/Format-Documentation/

https://github.com/Brian151/OpenShockwave/

https://gist.github.com/MrBrax/1f3ae06c9320863f1d7b79b988c03e60

https://www.scummvm.org/

## Building for Web

Add your DCRs to the `/web/dcr` directory, then run `flutter build web`.
