TARGET := fixdep

all: $(TARGET)

$(TARGET): fixdep.o

%.o : %.c
	gcc -c $< -o $@

.PHONY: clean 
clean:  
	rm -f *.o $(TARGET)