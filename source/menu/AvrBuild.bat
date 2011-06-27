@ECHO OFF
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "C:\Proyectos\menu\labels.tmp" -fI -W+ie -o "C:\Proyectos\menu\menu.hex" -d "C:\Proyectos\menu\menu.obj" -e "C:\Proyectos\menu\menu.eep" -m "C:\Proyectos\menu\menu.map" "C:\Proyectos\menu\menu.asm"
