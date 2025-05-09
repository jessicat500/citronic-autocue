PROJ	= autocue

${PROJ}.bin:	${PROJ}.s symbols.s
	ca65 -U -o ${PROJ}.o -l ${PROJ}.lst ${PROJ}.s
	ld65 -o $@ -t none ${PROJ}.o

.PHONY:	clean

clean:
	$(RM) *.o *.lst ${PROJ}.bin
