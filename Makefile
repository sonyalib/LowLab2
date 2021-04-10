AS = nasm
ASFLAGS = -f elf64
ASCMD = $(AS) $(ASFLAGS)
LD = ld

build: main
clean:
	rm -f *.o main
run: main
	./main
main: lib.o dict.o main.o
	$(LD) $^ -o $@
%.o: %.asm
	$(ASCMD) $*.asm

