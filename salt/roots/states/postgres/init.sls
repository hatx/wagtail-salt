postgresql:
  pkg.installed:
    - name: postgresql-9.4
  service.running:
    - enable: True
    - requires:
        - pkg: postgresql-9.4

# psycopg2:
#   pkg.installed:
#     - name: python3-psycopg2
#     - requires:
#       - pkg: postgresql

postgresql-server-dev:
  pkg:
    - installed
    - name: postgresql-server-dev-9.4
    - requires:
      - pkg: postgresql
