# The GPLv3 License (GPLv3)
# Copyright (c) 2023 Jeremy Baxter
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

PROG      = discord-rpcli
IMPORT    = import
PREFIX    = /usr/local
MANPREFIX = ${PREFIX}/share/man

DC      = ldc2
CFLAGS  = -O -I${IMPORT}
LDFLAGS = -L-ldiscord-rpc
OBJS    = main.o ini.o

all: discord-rpcli

discord-rpcli: ${OBJS}
	${DC} ${CFLAGS} ${LDFLAGS} -of=${PROG} ${OBJS}

# main executable
main.o: main.d
	${DC} -c ${CFLAGS} main.d -of=main.o

ini.o: ${IMPORT}/dini/*.d
	${DC} -c -i ${CFLAGS} ${IMPORT}/dini/*.d -of=ini.o

clean:
	rm -f ${PROG} ${OBJS}

install: discord-rpcli
	mkdir -p ${DESTDIR}${PREFIX}/bin
	mkdir -p ${DESTDIR}${MANPREFIX}/{man1,man5}
	cp -f discord-rpcli ${DESTDIR}${PREFIX}/bin/discord-rpcli
	cp -f discord-rpcli.1 ${DESTDIR}${MANPREFIX}/man1
	cp -f discord-rpcli.conf.5 ${DESTDIR}${MANPREFIX}/man5

.PHONY: clean install
