Scarlet Mod v1.3
By Leslie Krause

Scarlet is a thin-wrapper library for Minetest that provides a logical, uniform system of
of measurement for formspecs.

Repository
----------------------

Browse source code:
  https://bitbucket.org/sorcerykid/scarlet

Download archive:
  https://bitbucket.org/sorcerykid/scarlet/get/master.zip
  https://bitbucket.org/sorcerykid/scarlet/get/master.tar.gz

Revision History
----------------------

Version 1.0b (18-May-2019)
  - initial beta version

Version 1.1b (22-May-2019)
  - major code reorganization into multiple classes
  - added support for pixel-based unit of measurement
  - further simplified some "black magic" constants
  - implemented margins to simulate container element
  - revamped translation interface for stateful use
  - various improvements to element parameter parsing

Version 1.2b (24-May-2019)
  - included mod.conf and description.txt files
  - fixed parsing of list and size element parameters
  - recomputed textarea position due to engine bug
  - added padding option to generic element classes
  - implemented algorithm to compute form dimensions
  - reversed point and dot units per documentation

Version 1.3b (27-May-2019)
  - added method to evaluate arithmetic expressions
  - developed in-game unit conversion calculator
  - added optional padding parameter to size element
  - fixed ordering of checkbox element parameters
  - added methods to extract raw pos and dim values

Compatability
----------------------

Minetest 0.4.15+ required

Dependencies
----------------------

ActiveFormspecs Mod (optional)
  https://bitbucket.org/sorcerykid/formspecs

Installation
----------------------

  1) Unzip the archive into the mods directory of your game
  2) Rename the scarlet-master directory to "scarlet"
  3) Add "scarlet" as a dependency for any mods using the API


Source Code License
----------------------

The MIT License (MIT)

Copyright (c) 2019, Leslie Krause (leslie@searstower.org)

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

For more details:
https://opensource.org/licenses/MIT

