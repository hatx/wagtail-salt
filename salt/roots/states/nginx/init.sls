nginx:
  pkg.installed:
    - name: nginx
  service.running:
    - reload: True
    - watch:
      - file: /etc/nginx/nginx.conf
      - file: /etc/nginx/sites-available/*
      - file: /etc/nginx/sites-enabled/*
    - require:
      - pkg: nginx

/etc/nginx/nginx.conf:
  file:
    - exists
    - require:
      - pkg: nginx

/etc/nginx/sites-available/:
  file.directory:
    - require:
      - pkg: nginx

/etc/nginx/sites-enabled/:
  file.directory:
    - require:
      - pkg: nginx

nginx-uwsgi-params:
  file.managed:
    - name: /etc/nginx/sites-available/uwsgi_params
    - source: salt://nginx/uwsgi_params
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx
