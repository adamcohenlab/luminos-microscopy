CC=g++
CFLAGS = -g -Wall -DLINUX -I../../../inc/
LDFLAGS = -ldcimgapi
EXECUTABLE = access_recorded_image
SOURCES = $(EXECUTABLE).cpp


all:	$(EXECUTABLE)

$(EXECUTABLE): $(EXECUTABLE).o common_dcimg.o
	$(CC) $(EXECUTABLE).o common_dcimg.o -o $(EXECUTABLE) $(LDFLAGS)

$(EXECUTABLE).o:	$(SOURCES)
	$(CC) $(CFLAGS) $(LDFLAGS) -c $(SOURCES)

common_dcimg.o:	../misc/common_dcimg.cpp
	$(CC) $(CFLAGS) -c ../misc/common_dcimg.cpp

clean:
	rm -rf *.o $(EXECUTABLE)
