
resource "aws_docdb_cluster" "docdb" {
  cluster_identifier      = ${var.env}-docdb
  engine                  = var.engine
  master_username         = data.aws_ssm_parameter.user.value
  master_password         = data.aws_ssm_parameter.pass.value
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window
  skip_final_snapshot     = var.skip_final_snapshot   # " true" : Terraform to delete the resource it has created, " false " :otherwise it cannot delete

  engine_version = var.engine_version

}

resource "aws_docdb_subnet_group" "default" {
  name       = "${var.env}-docdb-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags,
{ Name = "${var.env}-subnet-group" })
}

