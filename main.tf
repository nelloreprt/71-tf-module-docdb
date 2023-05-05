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

  vpc_security_group_ids = [aws_security_group.main.id]
  # adding security group back to docdb
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

# name: Load Schema
#ansible.builtin.shell: mongo --host mongodb-dev.devopsb71.online </app/schema/{{component}}.js
ansible.builtin.shell: mongo --ssl --host {{ lookup('amazon.aws.aws_ssm', '{{env}}.docdb.endpoint', region='us-east-1') }}:27017 --sslCAFile /app/rds-combined-ca-bundle.pem --username {{ lookup('amazon.aws.aws_ssm', '{{env}}.docdb.user', region='us-east-1') }} --password {{ lookup('amazon.aws.aws_ssm', '{{env}}.docdb.pass', region='us-east-1') }} </app/schema/{{component}}.js


# ///////////////////////////////////////////////////////////////////////////////////////////
# CATALOGUE IS LOOKING FOR mongo_url >> now it is replaced with docdb_url
# docdb_url for catalogue is different
resource "aws_ssm_parameter" "docdb_url_catalogue" {
  name  = "${var.env}.docdb.url.catalogue"
  type  = "String"
  value = "mongodb://${data.aws_ssm_parameter.user.value}:${data.aws_ssm_parameter.pass.value}@dev-docdb.cluster-cbvsbeoyxek4.us-east-1.docdb.amazonaws.com:27017/catalogue?tls=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
}

# USER IS LOOKING FOR mongo_url >> now it is replaced with docdb_url
# docdb_url for USER is different
resource "aws_ssm_parameter" "docdb_url_user" {
  name  = "${var.env}.docdb.url.user"
  value = "mongodb://${data.aws_ssm_parameter.user.value}:${data.aws_ssm_parameter.pass.value}@dev-docdb.cluster-cbvsbeoyxek4.us-east-1.docdb.amazonaws.com:27017/users?tls=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
  type  = "String"
}

# docdb_endpoint is already available in >> resource _ aws_docdb_cluster.main, we are refering to that value
resource "aws_ssm_parameter" "docdb_endpoint" {
  name  = "${var.env}.docdb.endpoint"
  type  = "String"
  value = aws_docdb_cluster.main.endpoint
}

#------------------------------------

resource "aws_security_group" "main" {
  name        = "docdb-${var.env}"
  description = "docdb-${var.env}"
  vpc_id      = var.vpc_id    # vpc_id is coming from tf-module-vpc >> output_block

# We need to open the Application port & we also need too tell to whom that port is opened
# (i.e who is allowed to use that application port)
# I.e shat port to open & to whom to open
# Example for CTALOGUE we will open port 8080 ONLY WITHIN the APP_SUBNET
# So that the following components (i.e to USER / CART / SHIPPING / PAYMENT) can use CATALOGUE.
# And frontend also is necessarily need not be accessing the catalogue, i.e not to FRONTEND, because frontend belongs to web_subnet
  ingress {
    description      = "APP"
    from_port        = 27017   # rds port number
    to_port          = 27017   # rds port number
    protocol         = "tcp"
    cidr_blocks      = var.allow_subnets  # we want cidr number not subnet_id
}

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
}

  tags = merge(var.tags,
    { Name = "docdb-${var.env}" })
}

