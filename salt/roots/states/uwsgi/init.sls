include:
  - nginx

uwsgi:
  pkg.installed:
    - names:
      - uwsgi
      - uwsgi-plugin-python3

uwsgi-emperor-config:
  file.managed:
    - name: /etc/uwsgi/emperor.ini
    - source: salt://uwsgi/emperor.ini
    - template: jinja
    - require:
      - pkg: uwsgi
      - pkg: nginx

uwsgi-emperor-service-unit:
  file.managed:
    - name: /etc/systemd/system/uwsgi-emperor.service
    - source: salt://uwsgi/uwsgi-emperor.service
    - require:
      - file: uwsgi-emperor-config

uwsgi-service-unit-loaded:
  cmd.wait:
    - name: sudo systemctl daemon-reload
    - watch:
      - file: uwsgi-emperor-service-unit

# disable the built-in uwsgi service provided with the debian package, because
# we are creating our own emperor service instead
uwsgi-service:
  service.disabled:
    - name: uwsgi

uwsgi-emperor-service:
  service.running:
    - enable: True
    - name: uwsgi-emperor
    - watch:
      - file: uwsgi-emperor-config
      - file: /etc/uwsgi/apps-available/*
      - file: /etc/uwsgi/apps-enabled/*
    - require:
      - cmd: uwsgi-service-unit-loaded
      - file: uwsgi-emperor-service-unit
      - service: uwsgi-service

/etc/uwsgi/apps-available/:
  file.directory:
    - require:
      - pkg: uwsgi

/etc/uwsgi/apps-enabled/:
  file.directory:
    - require:
      - pkg: uwsgi
