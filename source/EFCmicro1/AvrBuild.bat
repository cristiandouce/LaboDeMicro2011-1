@ECHO OFF
"C:\Archivos de programa\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "C:\dev\repos\LaboDeMicro2011-1\source\EFCmicro1\labels.tmp" -fI -W+ie -o "C:\dev\repos\LaboDeMicro2011-1\source\EFCmicro1\EFCmicro1.hex" -d "C:\dev\repos\LaboDeMicro2011-1\source\EFCmicro1\EFCmicro1.obj" -e "C:\dev\repos\LaboDeMicro2011-1\source\EFCmicro1\EFCmicro1.eep" -m "C:\dev\repos\LaboDeMicro2011-1\source\EFCmicro1\EFCmicro1.map" "C:\dev\repos\LaboDeMicro2011-1\source\EFCmicro1\EFCmicro1.asm"