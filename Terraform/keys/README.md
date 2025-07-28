# SSH Keys Directory

This directory contains SSH keys for accessing EC2 instances.

## Key Files

- `qa-key.pem` - SSH private key for QA environment
- `prod-key.pem` - SSH private key for production environment

## Generating SSH Keys

To generate new SSH keys for your environments:

```bash
# Generate QA key
ssh-keygen -t rsa -b 4096 -f qa-key.pem -N ""

# Generate production key
ssh-keygen -t rsa -b 4096 -f prod-key.pem -N ""
```

## Security Notes

- Keep private keys secure and never commit them to version control
- Set appropriate file permissions: `chmod 600 *.pem`
- Consider using AWS Systems Manager Session Manager for secure access instead of SSH keys

## AWS Key Pair Management

After generating keys, you'll need to import them into AWS:

```bash
# Import the public key to AWS
aws ec2 import-key-pair --key-name acqua-key-qa --public-key-material file://qa-key.pem.pub

aws ec2 import-key-pair --key-name acqua-key-qa --public-key-material "$(cat Terraform/keys/qa-key.pem.pub | base64)"


aws ec2 import-key-pair --key-name acqua-key-prod --public-key-material file://prod-key.pem.pub
```

## Usage

SSH into your instances using:

```bash
# QA environment
ssh -i keys/qa-key.pem ubuntu@<ec2-public-ip>

# Production environment  
ssh -i keys/prod-key.pem ubuntu@<ec2-public-ip>
``` 