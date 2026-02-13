
LUA_VER := $(shell lua -e 'print(("lua%s"):format(_VERSION:match("%d+%.%d+")))')

LUA ?= $(LUA_VER)

CWARNS = -pedantic -Waggregate-return -Wcast-align \
         -Wmissing-prototypes -Wpointer-arith -Wshadow \
         -Wsign-compare -Wstrict-prototypes -Wundef -Wwrite-strings

CC = gcc
LDFLAGS = -Wl,-E
TAGS ?= -DLUA_USE_LINUX -DLUA_USE_READLINE
LIBS = -lm -ldl -lreadline -lhistory -lncurses -l$(LUA)
CFLAGS = -Wall -g -pedantic -O2 $(TAGS) -I/usr/include/$(LUA)

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
