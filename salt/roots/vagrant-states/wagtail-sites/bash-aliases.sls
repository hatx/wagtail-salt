include:
  - vagrant-bash-aliases

{% for site, args in pillar.get('sites', {}).items() %}

{% set user = args['user'] %}
{% set domain = args['domain'] %}

{{ site }}-activate-bash-alias:
  file.replace:
    - name: /home/vagrant/.bash_aliases
    - pattern: alias activate-{{ site }}=.*
    - repl: alias activate-{{ site }}='source /home/{{ user }}/{{ domain }}/virtualenv/{{ site }}/bin/activate'
    - append_if_not_found: True
    - require:
      - file: vagrant-bash-aliases

# This alias passes command line arguments on to manage.py
# See: <http://stackoverflow.com/a/22684652>
{{ site }}-manage-bash-alias:
  file.replace:
    - name: /home/vagrant/.bash_aliases
    - pattern: alias manage-{{ site }}=.*
    - repl: alias manage-{{ site }}='function _manage-{{ site }}(){ sudo -u {{ user }} env "DATABASE_URL=postgres://{{ args['postgresql']['user'] }}:{{ args['postgresql']['password'] }}@localhost/{{ args['postgresql']['dbname'] }}" /home/{{ user }}/{{ domain }}/virtualenv/{{ site }}/bin/python /home/{{ user }}/{{ domain }}/djangobase/manage.py "$@" ; };_manage-{{ site }}'
    - append_if_not_found: True
    - require:
      - file: vagrant-bash-aliases

{% endfor %}
