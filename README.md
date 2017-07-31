# Puppet Migration Environment

## What is this?

This is a pseudo-control repository for Puppet Enterprise.

It's design to assit with the migration from PE 3.8 to 2016.4 (but should work with other PE releases based on Puppet 4.x)



## How does it work?

It uses a set of classes and classification groups to automate the PuppetAgent. It's designed to be self contained and easy to install.



Make this the `migration` Puppet environment on both, PE 3.8 and PE 2015+

### Stage 1 (PE 3.8)

Add node to `cutover` node group. This will

 1. Create a new external Fact called `migration_stage` set to `newagent`
   - This is used to classify the node on the new PE infrastructure
 2. Change the settings `server` and `ca_server` (if specified) in the Puppet Agent's `puppet.conf`
 3. Delete the Puppet Agent's SSL certificate
 4. Restart the Puppet Agent service

### Stage 2a (PE 2015+)

The node connects to the new Puppet Master and requests a new certificate. Once the certificate is signed, the node is assigned to the 'MIGRATION: New Agent' Node Group.

This Node Group doesn't have any class assigned to the node and it just 'holds' the freshly migrated nodes.

### Stage 2b



## Setup

On the new Puppet Master, run:

```bash
puppet apply -t -e 'include migration::classification' --environment migration --noop
```

Then run again without `--noop` to create the classification rules.



## Testing

### Puppet Agent from the node

Log in as root to each node to test and run the Puppet Agent in `noop` mode

```bash
puppet agent -t --noop --environment production
```

Inspect the output looking for potential issues

### Orchestrator

```bash
puppet-job plan --query 'inventory[certname] { facts.migration_stage = "upgraded" }' --environment production
```

```bash
puppet-job run --query 'inventory[certname] { facts.migration_stage = "upgraded" }' --environment production --noop
```

The Orchestrator CLI tool will report the status of each Puppet Agent run with a link to the PE Console report. Open the URLs and check for problems.

### MCollective

Switch to `peadmin` user on the Master of Masters

```bash
su - peadmin
```

Get the list of nodes ready to test

```bash
mco puppet ping -F migration_stage=upgraded
```


Trigget a Puppet Agent run on those nodes

```bash
mco puppet runall -F migration_stage=upgraded --noop --environment production 5
```

MCollective works in 'fire-and-forget' mode, it will not show the reports or exit status. To see the result of the Puppet Agent run, check the reports in the PE Console.


