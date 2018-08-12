# class migration::cutover
class migration::cutover (
  $server            = 'pe-201646-master.puppetdebug.vlan',
  $server_section    = 'main',
  $ca_server         = undef,
  $ca_server_section = 'main',
) {
  validate_string($server)

  if ($ca_server) {
    validate_string($ca_server)
    $manage_ca_server = true
  } else {
    $manage_ca_server = false
  }

  file { [ '/etc/puppetlabs', '/etc/puppetlabs/facter', '/etc/puppetlabs/facter/facts.d', ]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/puppetlabs/facter/facts.d/migration_stage.txt':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => 'migration_stage=newagent',
    require => Class['::cutover'],
  }

  ini_setting { 'puppet.conf:main:stringify_facts=false':
    ensure  => present,
    path    => $::settings::config,
    section => 'main',
    setting => 'stringify_facts',
    value   => 'false',
    before  => Class['::cutover'],
  }

  ini_setting { 'puppet.conf:agent:stringify_facts absent':
    ensure  => absent,
    path    => $::settings::config,
    section => 'agent',
    setting => 'stringify_facts',
    before  => Class['::cutover'],
  }

  class { '::cutover':
    manage_server     => true,
    server            => $server,
    server_section    => $server_section,
    manage_ca_server  => $manage_ca_server,
    ca_server         => $ca_server,
    ca_server_section => $ca_server_section,
  }
}
