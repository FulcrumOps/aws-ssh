# aws-ssh
A tool to make discovering and sshing to AWS EC2 instances easy

## Demo

There is Terraform code to spool up 9 t2.micro instances. If you don't
already have EC2 servers, you can launch these to play with the `aws-ssh` tool.

The following assumes you have Terraform installed and your AWS credentials set as ENV vars. If you use 
tooling like [aws-vault](https://github.com/99designs/aws-vault), make the appropriate changes below.

```
cd tf
terraform plan -out terraform.plan
terraform apply terraform.plan
```

Hosts can now be discovered with `aws-ssh`. This will show all instances that match the key word `dev`:

```
AWS_PROFILE=<PROFILE> ./aws-ssh -v -r ssh dev
```

Since `web002` is unique, this will SSH into the instance:

```
AWS_PROFILE=<PROFILE> ./aws-ssh -v -r ssh dev web002
```

Note that not using AWS Identity Center is not currently supported, although easily possible.

# Help

```
$ ./aws-ssh -h
./aws-ssh [ping|ssh] [search terms]

-h: show this help
-u: user to ssh as (default: ubuntu)
-k: ssh key to use (default: /Users/pete/.ssh/id_ed25519.pub)
-d: debug mode (don't actually run commands)
-v: verbose mode (print commands)
-r: refresh cache

Search terms are space separated and are matched against the instance id,
public ip, private ip, and tags.

If more than one instance matches, all matches are printed and nothing
else is done.

If only one instance matches, the action is performed on that instance.

If the action is ping, the public ip of the instance is pinged.

If the action is ssh, the public ip of the instance is pinged and then
an ssh connection via ec2-instance-connect is attempted.

NOTE: You may want to set AWS_PROFILE to the profile you want to use.
```