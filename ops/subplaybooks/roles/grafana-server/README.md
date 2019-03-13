Role Name
=========

This role creates grafana server and imports quick dashboard with basic indicators for arbitrary network

Requirements
------------
This role requires that target machine has docker engine and that there is prometheus server configured.
Prometheus server could be brought up by **prometheus-server-docker** role


Role Variables
--------------

prometheus_endpoint: should be set to url and port of prometheus server

For example:
    prometheus_endpoint: prometheus.luxoft.com:9090

Dependencies
------------

See **dependencies** section in **meta/main.yml**

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: monitoring_grafana[0]
      roles:
        - grafana-server
      vars:
        prometheus_endpoint: http://"{{ groups['tag_project_group_monitoring_prometheus'][0] }}:9090"

Author Information
------------------

Created by Ivan Fedyanin at Luxoft.com
