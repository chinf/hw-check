# hw-check
Hardware health check and alerting.

* Check that edac-util drivers are loaded.
* Check that edac-util reports no errors.
* Check syslog for recent Hardware errors.
* Check sensors for any alarms (fan/temp/voltage).
  To do: Also monitor for anomalies.

For disk drive hardware checking and alerting see `smartmontools`.

Depends upon:

* `edac-util` for hardware error reporting.
* an appropriate edac driver module being loaded (e.g. `amd64_edac_mod`).
* `lm-sensors` for hardware sensor monitoring.
* the host being set up to send emails; one possibility is to use `bsd-mailx` and `ssmtp`, but several alternatives exist.

## Installation
```
wget https://github.com/chinf/hw-check/archive/master.zip
unzip master.zip
cd hw-check-master
sudo make install
```
This will install a cron entry for hw-check under `/etc/cron.daily/`, configured by default to email output to root@localhost.  Customise the mail address as appropriate.  This cron must run shortly before syslog gets rotated.
