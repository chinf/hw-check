PREFIX := /usr/local

all:

install:
	install -d $(DESTDIR)/etc/cron.daily
	install etc/hw-check.cron.daily    $(DESTDIR)/etc/cron.daily/hw-check
#	install -d $(DESTDIR)$(PREFIX)/share/man/man8
#	install -m 0644 src/hw-check.8 $(DESTDIR)$(PREFIX)/share/man/man8/hw-check.8
#	gzip $(DESTDIR)$(PREFIX)/share/man/man8/hw-check.8
	install -d $(DESTDIR)$(PREFIX)/bin
	install src/hw-check.sh $(DESTDIR)$(PREFIX)/bin/hw-check
