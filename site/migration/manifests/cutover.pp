# class migration::cutover
class migration::cutover (
  $server            = 'pe-201646-master.puppetdebug.vlan',
  $server_section    = 'main',
  $ca_server         = undef,
  $ca_server_section = 'main',
) {
  validate_string($server)

  $cleanup_settings = {
    'main'  => 'vardir',
    'main'  => 'logdir',
    'main'  => 'rundir',
    'main'  => 'ssldir',
    'agent' => 'pluginsync',
    'agent' => 'report',
    'agent' => 'ignoreschedules',
    'agent' => 'daemon',
  }

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


  for $cleanup_settings.each |$section,$setting| {
    ini_setting { "puppet.conf:${section}:${setting} absent":
      ensure  => absent,
      path    => $::settings::config,
      section => $section,
      setting => $setting,
      before  => Class['::cutover'],
    }
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

  if $ca_server_section == 'main' {
    ini_setting { 'puppet.conf:agent:ca_server absent':
      ensure  => absent,
      path    => $::settings::config,
      section => 'agent',
      setting => 'ca_server',
      before  => Class['::cutover'],
    }
  }

  if $manage_ca_server and $server_section == 'main' {
    ini_setting { 'puppet.conf:agent:server absent':
      ensure  => absent,
      path    => $::settings::config,
      section => 'agent',
      setting => 'server',
      before  => Class['::cutover'],
    }
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
