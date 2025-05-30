---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Dedicated encryption protects data at rest and in transit using AWS technologies, with support to bring your own encryption keys (BYOK).
title: GitLab Dedicated encryption
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

GitLab Dedicated provides secure encryption capabilities to protect your data through robust security
infrastructure provided by AWS. Data is encrypted both at rest and in transit.

## Encrypted data at rest

GitLab Dedicated encrypts all stored data using AWS AES-256 (Advanced Encryption Standard with 256-bit
keys). This encryption applies to all AWS storage services used by GitLab Dedicated.

| Service | How it's encrypted |
|-------------|-------------------|
| Amazon S3 (SSE-S3) | Uses per-object encryption where each object is encrypted with its own unique key, which is then encrypted by an AWS-managed root key. |
| Amazon EBS | Uses volume-level encryption using Data Encryption Keys (DEKs) generated by AWS Key Management Service (KMS). |
| Amazon RDS (PostgreSQL) | Uses storage-level encryption using DEKs generated by AWS KMS. |
| AWS KMS | Manages encryption keys in an AWS-managed key hierarchy, protecting them using Hardware Security Modules (HSMs). |

All services use AES-256 encryption standard. In this envelope encryption system:

1. Your data is encrypted using Data Encryption Keys (DEKs).
1. The DEKs themselves are encrypted using AWS KMS keys.
1. Encrypted DEKs are stored alongside your encrypted data.
1. AWS KMS keys remain in the AWS Key Management Service and are never exposed in unencrypted form.
1. All encryption keys are protected by Hardware Security Modules (HSMs).

This envelope encryption process works by having AWS KMS derive the DEKs specifically for each
encryption operation. The DEK directly encrypts your data, while the DEK itself is encrypted by the
AWS KMS key, creating a secure envelope around your data.

### Encryption key sources

Your AWS KMS encryption key can come from one of the following sources:

- [AWS-managed keys](#aws-managed-keys) (default): GitLab and AWS handle all aspects of key generation and
management.
- [Bring your own key (BYOK)](#bring-your-own-key-byok): You provide and control your own AWS KMS
keys.

All key generation takes place in AWS KMS using dedicated hardware, ensuring high security
standards for encryption across all storage services.

The following table summarizes the functional differences between these options:

| Encryption key source | AWS-managed keys                                                                            | Bring your own key (BYOK) |
|-----------------------|---------------------------------------------------------------------------------------------|---------------------------|
| **Key generation**    | Generated automatically if BYOK not provided.                                               | You create your own AWS KMS keys. |
| **Ownership**         | AWS manages on your behalf.                                                                 | You own and manage your keys. |
| **Access control**    | Only AWS services using the keys can decrypt and access them. You don't have direct access. | You control access through IAM policies in your AWS account. |
| **Setup**             | No setup required.                                                                          | Must be set up before onboarding. Cannot be enabled later. |

### AWS-managed keys

When you don't bring your own key, AWS uses AWS-managed KMS keys for encryption by
default. These keys are automatically created and maintained by AWS for each service.

AWS KMS manages access to AWS-managed keys using AWS Identity and Access
Management (IAM). This architecture ensures that even AWS personnel cannot access your encryption
keys or decrypt your data directly, as all key operations are managed through the HSM-based security
controls.

You do not have direct access to AWS-managed KMS keys. Only the specific AWS services you use with
your instance can request encryption or decryption operations for resources they manage on your
behalf.

Only AWS services that need access to the key (S3, EBS, RDS) can use them. AWS personnel do not have
direct access to key material, as AWS KMS keys are protected by an internal HSM-based mechanism.

To learn more, see the Amazon documentation on [AWS managed keys](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk).

### Bring your own key (BYOK)

With BYOK, you can encrypt your GitLab Dedicated data at rest using your own AWS KMS keys. This way,
you retain control over your own AWS KMS encryption keys. You manage access policies through your AWS
account.

{{< alert type="note" >}}

BYOK must be enabled during instance onboarding. Once enabled, it cannot be disabled.

If you did not enable BYOK during onboarding, your data is still encrypted at rest with AWS-managed
keys, but you cannot use your own keys.

{{< /alert >}}

Due to key rotation requirements, GitLab Dedicated only supports keys with AWS-managed key material
(the [AWS_KMS](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#key-origin)
origin type).

In GitLab Dedicated, you can use KMS keys in several ways:

- One KMS key for all services across all regions: Use a single multi-region key with replicas in each region where you have Geo instances.
- One KMS key for all services within each region: Use separate keys for each region where you have Geo instances.
- Per-service KMS keys per region: Use different keys for different services (backup, EBS, RDS, S3, advanced search) within each region.
  - Keys do not need to be unique to each service.
  - Selective enablement is not supported.

#### Create AWS KMS keys for BYOK

Create your KMS keys using the AWS Console.

Prerequisites:

- You must have received your GitLab AWS account ID from the GitLab Dedicated account team.
- Your GitLab Dedicated tenant instance must not yet be created.

To create AWS KMS keys for BYOK:

1. Sign in to the AWS Console and go to the KMS service.
1. Select the region of the Geo instance you want to create a key for.
1. Select **Create key**.
1. In the **Configure key** section:
   1. For **Key type**, select **Symmetrical**.
   1. For **Key usage**, select **Encrypt and decrypt**.
   1. Under **Advanced options**:
      1. For **Key material origin**, select **KMS**.
      1. For **Regionality**, select **Multi-Region key**.
1. Enter your values for key alias, description, and tags.
1. Select key administrators.
1. Optional. Allow or prevent key administrators from deleting the key.
1. On the **Define key usage permissions** page, under **Other AWS accounts**, add the GitLab AWS
account.
1. Review the KMS key policy. It should look similar to the example below, populated with your
account IDs and usernames.

```json
{
    "Version": "2012-10-17",
    "Id": "byok-key-policy",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::<CUSTOMER-ACCOUNT-ID>:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow access for Key Administrators",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::<CUSTOMER-ACCOUNT-ID>:user/<CUSTOMER-USER>"
                ]
            },
            "Action": [
                "kms:Create*",
                "kms:Describe*",
                "kms:Enable*",
                "kms:List*",
                "kms:Put*",
                "kms:Update*",
                "kms:Revoke*",
                "kms:Disable*",
                "kms:Get*",
                "kms:Delete*",
                "kms:TagResource",
                "kms:UntagResource",
                "kms:ScheduleKeyDeletion",
                "kms:CancelKeyDeletion",
                "kms:ReplicateKey",
                "kms:UpdatePrimaryRegion"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow use of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::<GITLAB-ACCOUNT-ID>:root"
                ]
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow attachment of persistent resources",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::<GITLAB-ACCOUNT-ID>:root"
                ]
            },
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": "*"
        }
    ]
}
```

#### Create replica keys for additional Geo instances

Create [replica keys](https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-replicate.html)
when you want to use the same KMS key across multiple Geo instances in different regions.

To create replica keys:

1. In the AWS Key Management Service (AWS KMS) console, go to the key you previously created.
1. Select the **Regionality** tab.
1. In the **Related multi-Region keys** section, select **Create new replica keys**.
1. Choose one or more AWS Regions where you have additional Geo instances.
1. Keep the original alias or enter a different alias for the replica key.
1. Optional. Enter a description and add tags.
1. Select the IAM users and roles that can administer the replica key.
1. Optional. Select or clear the **Allow key administrators to delete this key** checkbox.
1. Select **Next**.
1. On the **Define key usage permissions** page, verify that the GitLab AWS account
   is listed under **Other AWS accounts**.
1. Select **Next** and review the policy.
1. Select **Next**, review your settings, and select **Finish**.

For more information on creating and managing KMS keys, see the [AWS KMS documentation](https://docs.aws.amazon.com/kms/latest/developerguide/getting-started.html).

#### Enable BYOK for your instance

To enable BYOK:

1. Collect the ARNs for all keys you created, including any replica keys in their respective regions.
1. Before your GitLab Dedicated tenant is provisioned, ensure these ARNs have been entered into in Switchboard during [onboarding](create_instance/_index.md).
1. Make sure the AWS KMS keys are replicated to your desired primary, secondary, and backup regions
specified in Switchboard during [onboarding](create_instance/_index.md).

## Encrypted data in transit

GitLab Dedicated encrypts all data moving over networks using TLS (Transport Layer Security) with
strong cipher suites. This encryption applies to all network communications used by GitLab Dedicated
services.

| Service | How it's encrypted |
|---------|-------------------|
| Web application | Uses TLS 1.2/1.3 to encrypt client-server communication. |
| Amazon S3 | Uses TLS 1.2/1.3 to encrypt HTTPS access. |
| Amazon EBS | Uses TLS to encrypt data replication between AWS data centers. |
| Amazon RDS (PostgreSQL) | Uses SSL/TLS (minimum TLS 1.2) to encrypt database connections. |
| AWS KMS | Uses TLS to encrypt API requests. |

{{< alert type="note" >}}

Encryption for data in transit is performed with TLS using keys generated and managed by GitLab
Dedicated components, and is not covered by BYOK.

{{< /alert >}}

### Custom TLS certificates

You can configure custom TLS certificates to use your organization's certificates for encrypted
communications.

For more information on configuring custom certificates, see
[custom certificates](configure_instance/network_security.md#custom-certificates).
