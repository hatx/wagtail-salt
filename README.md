# Wagtail Salt States

***Set up a development environment for Wagtail sites or Django apps.***

These [Salt](https://en.wikipedia.org/wiki/SaltStack) states provision a [Vagrant](https://en.wikipedia.org/wiki/Vagrant_%28software%29) virtual machine for [Wagtail](https://wagtail.io/) or Django development.  They automate the following tasks for one or more projects:

- Nginx and uWSGI are configured.
- A PostgreSQL database is created and setup.
- Dependencies found in requirements.txt are installed in a virtualenv.
- django-admin commands are run automatically (collectstatic, migrate, and createsuperuser).
- Bash aliases are created to conveniently run django-admin commands during development.

The guest OS is Debian 8 (Jessie).  The packages needed to run Wagtail are automatically installed.


## Requirements

- [Vagrant](http://docs.vagrantup.com/v2/installation/index.html)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

## Usage

Two options for using these Salt states are:

1. Keep the vagrant configuration in a separate repository from your project repositories.  This allows you to use a single VM with a consistent configuration to run multiple projects.

2. Duplicate this salt and vagrant configuration inside your own project to have a self-contained app with its own virtual machine.

### Configuration

First clone this repository.  The example below assumes that you placed it in parallel with some Wagtail project directories, so the directory tree looks like this:

    .
    ├── project-one
    │   ├── examplesite
    │   ├── home
    │   ├── search
    │   ├── manage.py
    │   └── requirements.txt
    ├── project-two
    │   ├── examplesite2
    │   ├── home
    │   ├── search
    │   ├── manage.py
    │   └── requirements.txt
    └── wagtail-salt

Two configuration files are needed inside wagtail-salt:

The first file is `salt/pillar/local/sites.sls`, a YAML file that includes the settings for your projects.  This is an example:

    sites:
      project1:
        user: exampleuser1
        domain: test1.example.com
        django:
          settings_module: examplesite.settings
          superuser:
            username: admin
            email: test@example.com
            password: test
        nginx:
          port: 9000
        uwsgi:
          module: examplesite.wsgi:application
          port: 3000
        postgresql:
          user: testdbuser
          dbname: testdb
          password: test

      project2:
        user: exampleuser2
        domain: test2.example.com
        django:
          settings_module: examplesite2.settings
          superuser:
            username: admin
            email: test2@example.com
            password: test
        nginx:
          port: 9001
        uwsgi:
          module: examplesite2.wsgi:application
          port: 3001
        postgresql:
          user: testdbuser2
          dbname: testdb2
          password: test

The second file, `Vagrantfile.local`, tells Vagrant which local project directories to share with the virtual machine.  It also sets up port forwarding so you can access the websites from the host machine.  It should resemble this:

    # forward a port that can be used for django-admin runserver
    config.vm.network "forwarded_port", guest: 8000, host: 8000

    # settings for project 1
    config.vm.network "forwarded_port", guest: 9000, host: 9000
    config.vm.synced_folder "../project-one", "/sites/project1"

    # settings for project 2
    config.vm.network "forwarded_port", guest: 9001, host: 9001
    config.vm.synced_folder "../project-two", "/sites/project2"

With these settings files in place, enter the wagtail-salt directory and run:

    vagrant up

When this command completes you can access your Wagtail/Django websites at the host ports you set in `Vagrantfile.local`, eg: http://localhost:9000/ and http://localhost:9001/

### Passing database settings to your sites

Instead of hardcoding database configuration inside your Wagtail/Django sites you can read the settings from an environment variable.  These Salt states configure Nginx to pass the variable DATABASE_URL to your apps, so you can use [dj_database_url](https://pypi.python.org/pypi/dj-database-url).

### Bash aliases

To ssh into the virtual machine, run:

    vagrant ssh

Then you can run django-admin with aliases that have been automatically created for each project.  For example:

    manage-project1 runserver 0.0.0.0:8000

Note: This alias will also set environment variables, such as DATABASE_URL, for your app.

Another alias is provided to activate the virtualenv for a project:

    activate-project1

### Changing settings

To change project settings, edit `salt/pillar/local/sites.sls` and run:

    vagrant provision

### Adding more projects

To add a project, edit `salt/pillar/local/sites.sls` and `Vagrantfile.local`, and run:

    vagrant reload --provision
