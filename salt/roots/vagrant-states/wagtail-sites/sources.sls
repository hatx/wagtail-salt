{% for site, args in pillar.get('sites', {}).items() %}

{% set user = args['user'] %}
{% set domain = args['domain'] %}

{{ site }}-sources:
  file.symlink:
    - name: /home/{{ user }}/{{ domain }}/djangobase
    - target: /sites/{{ site }}
    - user: {{ user }}
    - group: {{ user }}
    - require:
      - user: {{ site }}-user
      - file: {{ site }}-dir

{% endfor %}
