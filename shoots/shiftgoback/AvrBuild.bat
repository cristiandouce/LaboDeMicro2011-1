@ECHO OFF
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "C:\Proyectos\shiftgoback\labels.tmp" -fI -W+ie -o "C:\Proyectos\shiftgoback\shiftgoback.hex" -d "C:\Proyectos\shiftgoback\shiftgoback.obj" -e "C:\Proyectos\shiftgoback\shiftgoback.eep" -m "C:\Proyectos\shiftgoback\shiftgoback.map" "C:\Proyectos\shiftgoback\shiftgoback.asm"
