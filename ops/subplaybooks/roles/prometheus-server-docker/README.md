Role Name
=========

This role is rolling out prometheus server which gathers metrics from peers and orderers.

Requirements
------------

In order to enable TLS connection to peers and orderers this role is expecting that here will be following folder available with keys and certs

`{{crypto_config_path}}/prometheusOrganizations/organisation{{organisation_index}}.{{domain}}/tls'`

- server.key - prometheus server private key
- ca.pem - the same ca as used in peer tls configuration
- orderer_ca.pem - the same ca as used in orderer tls configuration
- server.crt - prometheus certificate signed by peer ca
- orderer_server.crt - - prometheus certificate signed by orderer ca

Apart from that peers and orderers must be configured to provide prometheus metrics over TLS:

See https://hyperledger-fabric.readthedocs.io/en/release-1.4/operations_service.html for details.


Role Variables
--------------

scrape_configs_peers:  - config with scraped peers
scrape_configs_orderers: - config with scrapped orderers
node_name:  - template for node name
domain: - domain
crypto_config_path: - path where crypto-config is located
organisation_index:  - default organisation index

      

Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: monitoring_prometheus
      roles:
        - prometheus-server-docker
      vars:
        scrape_configs_peers: "{{ [ { 'name':'fabric peers', 'targets':groups['tag_project_group_peers']|default([])|map('regex_replace','^(.*)$','\\1:9443') |list} ] }}"
        scrape_configs_orderers: "{{ [ { 'name':'fabric orderers', 'targets':groups['tag_project_group_orderers']|default([])|map('regex_replace','^(.*)$','\\1:9443') |list} ] }}"
        crypto_config_path: "{{ hostvars['localhost']['actual_network_dir'] }}/crypto-config"

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
