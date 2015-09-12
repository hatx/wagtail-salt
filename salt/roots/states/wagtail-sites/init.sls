include:
  - pip
  - virtualenv
  - python3
  - pillow
  - postgres
  - uwsgi

{% for site, args in pillar.get('sites', {}).items() %}

{% set user = args['user'] %}
{% set domain = args['domain'] %}

{{ site }}-user:
  user.present:
    - name: {{ user }}
    - gid_from_name: true

{{ site }}-dir:
  file.directory:
    - name: /home/{{ user }}/{{ domain }}
    - user: {{ user }}
    - group: {{ user }}
    - require:
      - user: {{ site }}-user

{{ site }}-virtualenv:
  virtualenv.managed:
    - name: /home/{{ user }}/{{ domain }}/virtualenv/{{ site }}
    - requirements: /home/{{ user }}/{{ domain }}/djangobase/requirements.txt
    - user: {{ user }}
    - python: python3
    - require:
      - pkg: python-virtualenv
      - pkg: python3-pkgs
      - user: {{ site }}-user
      - file: {{ site }}-sources
      - pkg: pillow-dependencies
  pip.installed:
    - bin_env: /home/{{ user }}/{{ domain }}/virtualenv/{{ site }}
    - name: psycopg2
    - user: {{ user }}
    - require:
      - virtualenv: {{ site }}-virtualenv
      - pkg: python-pip
      - pkg: postgresql-server-dev

{{ site }}-collectstatic:
  module.wait:
    - name: django.collectstatic
    - settings_module: {{ args['django']['settings_module'] }}
    - bin_env: /home/{{ user }}/{{ domain }}/virtualenv/{{ site }}
    - pythonpath: /home/{{ user }}/{{ domain }}/djangobase/
    - watch:
      - module: {{ site }}-migrate
    - require:
      - virtualenv: {{ site }}-virtualenv

{{ site }}-migrate:
  module.wait:
    - name: django.command
    - command: migrate
    - settings_module: {{ args['django']['settings_module'] }}
    - bin_env: /home/{{ user }}/{{ domain }}/virtualenv/{{ site }}
    - pythonpath: /home/{{ user }}/{{ domain }}/djangobase/
    - env:
      - DATABASE_URL: postgres://{{ args['postgresql']['user'] }}:{{ args['postgresql']['password'] }}@localhost/{{ args['postgresql']['dbname'] }}
    - watch:
      - postgres_database: {{ site }}-postgres-db
    - require:
      - virtualenv: {{ site }}-virtualenv

# This seems to be the simplest way to automate superuser account creation
# See: <http://stackoverflow.com/questions/6244382/>
{{ site }}-createsuperuser:
  cmd.wait:
    - name: |
        source /home/{{ user }}/{{ domain }}/virtualenv/{{ site }}/bin/activate
        cat << EOF | python manage.py shell
        from django.contrib.auth.models import User;
        import os;
        User.objects.create_superuser(
          '{{ args['django']['superuser']['username'] }}',
          '{{ args['django']['superuser']['email'] }}',
          os.getenv('SUPERUSER_PWD'))
        EOF
    - env:
      - SUPERUSER_PWD: {{ args['django']['superuser']['password'] }}
      - DATABASE_URL: postgres://{{ args['postgresql']['user'] }}:{{ args['postgresql']['password'] }}@localhost/{{ args['postgresql']['dbname'] }}
    - user: {{ user }}
    - group: {{ user }}
    - cwd: /home/{{ user }}/{{ domain }}/djangobase/
    - watch:
      - module: {{ site }}-migrate
    - require:
      - virtualenv: {{ site }}-virtualenv

{{ site }}-uwsgi:
  file.managed:
    - name: /etc/uwsgi/apps-available/{{ domain }}.ini
    - source: salt://wagtail-sites/uwsgi.ini
    - template: jinja
    - defaults:
        site_root: /home/{{ user }}/{{ domain }}
        site: {{ site }}
        user: {{ user }}
    - user: {{ user }}
    - group: {{ user }}
    - mode: 644
    - require:
      - pkg: uwsgi
      - user: {{ site }}-user
      - file: /etc/uwsgi/apps-available/
      - virtualenv: {{ site }}-virtualenv
      - pip: {{ site }}-virtualenv

{{ site }}-uwsgi-enabled:
  file.symlink:
    - name: /etc/uwsgi/apps-enabled/{{ domain }}.ini
    - target: /etc/uwsgi/apps-available/{{ domain }}.ini
    - force: false
    - require:
      - file: {{ site }}-uwsgi
      - file: /etc/uwsgi/apps-enabled/

{{ site }}-nginx:
  file.managed:
    - name: /etc/nginx/sites-available/{{ domain }}.conf
    - source: salt://wagtail-sites/nginx.conf
    - template: jinja
    - defaults:
        project_path: /home/{{ user }}/{{ domain }}/djangobase
        site: {{ site }}
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx
      - file: nginx-uwsgi-params
      - file: /etc/nginx/sites-available/

{{ site }}-nginx-enabled:
  file.symlink:
    - name: /etc/nginx/sites-enabled/{{ domain }}.conf
    - target: /etc/nginx/sites-available/{{ domain }}.conf
    - force: false
    - require:
      - file: {{ site }}-nginx
      - file: /etc/nginx/sites-enabled/

{{ site }}-postgres-user:
  postgres_user.present:
    - name: {{ args['postgresql']['user'] }}
    - password: {{ args['postgresql']['password'] }}
    - user: postgres
    - require:
      - service: postgresql

{{ site }}-postgres-db:
  postgres_database.present:
    - name: {{ args['postgresql']['dbname'] }}
    - encoding: UTF8
    - owner: {{ args['postgresql']['user'] }}
    - user: postgres
    - require:
        - service: postgresql
        - postgres_user: {{ site }}-postgres-user

{% endfor %}
