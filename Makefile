all: os.img

boot.bin: boot/boot.asm
	nasm -f bin boot/boot.asm -o boot.bin
	
kernel.bin: kernel/kernel.asm
	nasm -f bin kernel/kernel.asm -o kernel.bin

print.c: print.c
	i686-elf-gcc -c print.c -o print.o

os.img: boot.bin kernel.bin
	dd if=/dev/zero of=os.img bs=512 count=2880
	dd if=boot.bin of=os.img conv=notrunc
	dd if=kernel.bin of=os.img bs=512 seek=1 conv=notrunc

run: os.img
	qemu-system-x86_64 -drive file=os.img,format=raw -monitor stdio

run2: os.img
	qemu-system-x86_64 -drive file=os.img,format=raw -d int -D qemu.log

debug: os.img
	qemu-system-x86_64 -s -S -drive file=os.img,format=raw &
	gdb -ex "target remote localhost:1234" -ex "set architecture i8086" -ex "break *0x7c00" -ex "continue"

clean:
	rm -f *.bin *.img
