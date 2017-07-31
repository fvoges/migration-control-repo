# class migration::classification
class migration::classification {
  node_group { 'MIGRATION: Back to prod':
    ensure               => 'present',
    classes              => {'migration::cleanup' => {}},
    environment          => 'migration',
    override_environment => true,
    parent               => 'MIGRATION: Ready',
  }
  node_group { 'MIGRATION: New Agent':
    ensure               => 'present',
    environment          => 'migration',
    override_environment => true,
    parent               => 'Production environment',
    rule                 => ['and', ['=', ['fact', 'migration_stage'], 'newagent']],
  }
  node_group { 'MIGRATION: Ready':
    ensure               => 'present',
    environment          => 'migration',
    override_environment => true,
    parent               => 'Production environment',
    rule                 => ['and', ['=', ['fact', 'migration_stage'], 'upgraded']],
  }
  node_group { 'MIGRATION: Test':
    ensure               => 'present',
    environment          => 'agent-specified',
    override_environment => true,
    parent               => 'MIGRATION: Ready',
    rule                 => ['and', ['~', ['fact', 'agent_specified_environment'], '.*']],
  }
  node_group { 'MIGRATION: Upgrade':
    ensure               => 'present',
    classes              => {'migration::upgrade_agent' => {}},
    environment          => 'migration',
    override_environment => true,
    parent               => 'MIGRATION: New Agent',
    rule                 => ['and', ['~', 'name', '']],
  }
}
