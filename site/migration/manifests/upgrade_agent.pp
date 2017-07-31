class migration::upgrade_agent {
  $remove_settings = [
    {
      section => 'main',
      setting => 'archive_files',
    },
    {
      section => 'agent',
      setting => 'archive_files',
    },
    {
      section => 'main',
      setting => 'archive_file_server',
    },
    {
      section => 'agent',
      setting => 'archive_file_server',
    },
  ]

  $remove_settings.each | $setting | {
    ini_setting { "${setting['section']}:${setting['setting']} absent":
      ensure  => absent,
      path    => $::settings::config,
      section => $setting['section'],
      setting => $setting['setting'],
      before  => Class['::puppet_agent'],
    }
  }

  include ::puppet_agent

  file { '/etc/puppetlabs/facter/facts.d/migration_stage.txt':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => 'migration_stage=upgraded',
    require => Class['::puppet_agent'],
  }
}
