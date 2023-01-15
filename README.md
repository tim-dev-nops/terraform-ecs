# Dev-Nops ECS Terraform Demo

Example [Terraform](https://www.terraform.io) and [GitHub](https://github.com) workflow that creates an ECS service that is then updated via the GitHub workflow without disturbing the Terraform state. This can be used when you want your normal CI/CD to deploy changes to the Docker image used in the ECS task outside of Terraform.

## Requirements
 
- AWS account
- GitHub account
- AWS CLI (v2.9.13)
- Terraform (v1.3.7)

## Development setup

### AWS Credentials

Create AWS access keys for CLI access in the AWS Console following these 
[instructions](https://docs.aws.amazon.com/powershell/latest/userguide/pstools-appendix-sign-up.html). 
Then run `aws-configure` to add the credentials to your local machine. 
The credentials will be used by Terraform to create and destroy AWS resources.

### Fork this repository

[Fork](https://docs.github.com/en/get-started/quickstart/fork-a-repo) this repository and clone your fork locally.

### Create the AWS resources using terraform

In root of your local repository:
```
cd tf
terraform init
terraform plan -out createplan
```
Should see a long list of resources to create and summarized by:
```
Plan: 36 to add, 0 to change, 0 to destroy.
```

Then run:
```
terraform apply createplan
```

Once the resources have all been created the load balancer DNS name can be found by running:
```
terraform output
```

If you visit `http://${YOUR_LB_DNS}/dev-nops-demo/` 
you should see output from [NGINX](https://www.nginx.com) 
with your ECS task IP address, server name, date, 
and URI you are visiting (`/dev-nops-demo/`).

### Setup GitHub secrets and deploy new image

In your forked repository you need to add your AWS credentials to 
[respository secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets) 
so the AWS workflow can deploy to AWS.

You need to create the following secrets:
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY

These should contain the same values used when you ran `aws configure` 
and can be retrieved from `~/.aws/credentials`.

After those are setup, you should visit the `actions` tab of your forked repository and enable workflows.

Make a small change to this file, commit, and push the change to the `main` branch:

```
git add README.md
git commit -m "Deploy new image"
git push
```

After the action completes running reload the URL in your browser 
and you should now see the plain text version of the 
[nginxdemos/hello](https://hub.docker.com/r/nginxdemos/hello/) project.

Then you should run `terraform plan` again in the `tf` directory to confirm there are no changes after the GitHub deploy.

To remove all the AWS resources, run:
```
terraform plan -destroy -out destroyplan
terraform apply destroyplan
```
