

# Create RDS instance
resource "aws_db_instance" "wordpress-database" {
  provider               = aws.region-master
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = ["${aws_security_group.RDS_allow_rule.id}"]
  name                   = var.database_name
  username               = var.database_user
  password               = var.database_password
  skip_final_snapshot    = true
}

# change USERDATA variable value after grabbing RDS endpoint info
data "template_file" "userdata_ubuntu" {
  template = file("${path.module}/userdata_ubuntu.tpl")
  vars = {
    db_username      = "${var.database_user}"
    db_user_password = "${var.database_password}"
    db_name          = "${var.database_name}"
    db_RDS           = "${aws_db_instance.wordpress-database.endpoint}"
  }
}




#Create key-pair for logging into EC2 in us-east-1
resource "aws_key_pair" "master-key" {
  provider   = aws.region-master
  key_name   = "lamp-key"
  public_key = file("~/.ssh/id_rsa.pub")
}




# Create EC2 ( only after RDS is provisioned)
resource "aws_instance" "wordpress-instance" {
  provider      = aws.region-master
  ami           = "ami-083654bd07b5da81d"
  instance_type = var.instance-type

  vpc_security_group_ids = ["${aws_security_group.ec2_allow_rule.id}"]
  subnet_id              = aws_subnet.subnet_1.id

  associate_public_ip_address = true
  key_name                    = aws_key_pair.master-key.key_name
  user_data                   = data.template_file.userdata_ubuntu.rendered
  tags = {
    Name = "Wordpress-instance"
  }

  # this will stop creating EC2 before RDS is provisioned and route table overwrited
  depends_on = [aws_db_instance.wordpress-database,
  aws_main_route_table_association.set-master-default-rt-assoc]

}







 