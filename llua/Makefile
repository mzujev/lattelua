LUA ?= lua5.1

CWARNS = -pedantic -Waggregate-return -Wcast-align \
         -Wmissing-prototypes -Wpointer-arith -Wshadow \
         -Wsign-compare -Wstrict-prototypes -Wundef -Wwrite-strings

CC = gcc
CFLAGS = -Wall -g -pedantic -O2 -DLUA_USE_LINUX -I/usr/include/$(LUA)
LDFLAGS = -Wl,-E
LIBS = -lm -ldl -lreadline -lhistory -lncurses -l$(LUA)

TARGET = llua
OBJ = llua.o

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) -o bin/$(TARGET) $(LDFLAGS) bin/$(OBJ) $(LIBS)

$(OBJ): llua/llua.c
	mkdir -p bin
	$(CC) $(CFLAGS) $(CWARNS) -c llua/llua.c -o bin/$(OBJ)

clean:
	rm -f bin/$(OBJ) bin/$(TARGET)

install:

.PHONY: all clean
