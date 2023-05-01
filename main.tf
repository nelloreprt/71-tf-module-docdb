# step-2 # cluster is like a VPC, inside the cluster we have to create instances
resource "aws_docdb_cluster" "main" {
  cluster_identifier      = "${var.env}-docdb"
  engine                  = var.engine
  master_username         = data.aws_ssm_parameter.user.value
  master_password         = data.aws_ssm_parameter.pass.value
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window
  skip_final_snapshot     = var.skip_final_snapshot
  # " true" : Terraform to delete the resource it has created, " false " :otherwise it cannot delete

  engine_version       = var.engine_version
  db_subnet_group_name = aws_docdb_subnet_group.main.name
  # as we are referencing within the module, from: resource > aws_docdb_cluster ; To: resource >aws_docdb_subnet_group
  # we are not sending "db_subnet_group_name" to root_module
  kms_key_id           = data.aws_kms_key.by_alias.arn
  storage_encrypted    = "true"       # as we are using kms_key, data in the database shall be encrypted, by default it is false, we are setting it to be true
}

  # secrets = [ in roboshop-infra/aws-parameters/env-dev/main.tfvars
# {name = "test1" , value = "hello universe" , type = "string"  ,
# { name = "dev.docdb.user", value = "admin1" , type = "SecureString" } ,    # creating docdb parameter for USER
# { name = "dev.docdb.pass", value = "RoboShop1" , type = "SecureString" } , # creating docdb parameter for PASSWORD
# ]

# step-1
resource "aws_docdb_subnet_group" "main" {
  name       = "${var.env}-docdb-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags,
{ Name = "${var.env}-subnet-group" })
}

# step-3
resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = var.no_of_instances
  identifier         = "${var.env}-docdb-${count.index}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = var.instance_class
}

