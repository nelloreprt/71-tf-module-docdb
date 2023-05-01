# we have already created parameters for user-pass in aws_parameter store
# now to read the VALUES of parameters of docdb_USER-PASS we are using data_source_block of aws_ssm_parameter

data "aws_ssm_parameter" "user" {
  name = "${var.env}.docdb.user"
}

data "aws_ssm_parameter" "pass" {
  name = "${var.env}.docdb.pass"
}

data "aws_kms_key" "by_alias" {
key_id = "alias/roboshop"              # my-key >> key_name is aws >> in our case it is "roboshop"
}