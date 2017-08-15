# Puppet Migration Environment

## What is this?

This is a pseudo-control repository for Puppet Enterprise.

It's design to assist with the migration from PE 3.8 to 2016.4 (but should work with other PE releases based on Puppet 4.x)

## Pseudo control-repo?

I called it pseudo-control repo for lack of a better name. It's not a full control repo. It has all the pieces of a control repo (`Puppetfile`, `environment.conf`, `site` directory with a profiles module, etc.) but it's not meant to be used as one.

How do you use it then?

You can either add it as a new branch of your existing control repository. If you're not using a control repository, then you can install the modules from the `Puppetfile` and then copy the contents of this repo into a new Puppet environment in your Puppet Master(s).

## Installation


You have two ways to install it

### Using Code Manager (or r10k)

  1. Using r10k/coda manager:
    1. You create a new, empty, branch
    1. Add the contents of this repo to it
  2. Not using r10k/code manager
    1. Install all modules from the Puppetfile (`r10k puppetfile install -v`)
    2. Copy the

```shell
git clone https://github.com/fvoges/migration-control-repo /tmp/migration
# We don't need the full Git repository, just the files
rm -rf /tmp/migration/.git

# Change to the working directory of your control repository
cd LOCATION_OF_YOUR_CONTROL_REPO_WORKDIR
# Create a new empty branch
git checkout --orphan migration
# Remove the unnecessary files
git rm --cached -r .
# Copy over the migration environment
cp -r /tmp/migration/* .
git add .
git commit -m 'Migration environment'
```


### Manual installation without Code Manager (or r10k)

```shell
git clone https://github.com/fvoges/migration-control-repo /tmp/migration
cd /tmp/migration
# We don't need the full Git repository, just the files
rm -rf /tmp/migration/.git
#
# if r10k command is available (e.g., on a Puppet Master)
#
r10k puppetfile install
#
# Manual install without r10k
#
mkdir -p /tmp/modules
puppet module install --target-dir /tmp/modules \
    --ignore-dependencies pizzaops-cutover --version 1.0.5
puppet module install --target-dir /tmp/modules \
    --ignore-dependencies puppetlabs-puppet_agent --version 1.4.0
puppet module install --target-dir /tmp/modules \
    --ignore-dependencies puppetlabs-stdlib --version 4.17.1
puppet module install --target-dir /tmp/modules \
    --ignore-dependencies puppetlabs-transition --version 0.1.1
puppet module install --target-dir /tmp/modules \
    --ignore-dependencies puppetlabs-inifile --version 1.6.0
puppet module install --target-dir /tmp/modules \
    --ignore-dependencies WhatsARanjit-node_manager --version 0.4.2

#
tar -C /tmp -cvzf ~/migration-env.tar.gz migration

```




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


