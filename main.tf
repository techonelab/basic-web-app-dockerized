#created by roselio a.k.a sonny
#I will not be held responsible for any underlying cost that will occur on you account by using this code
#feel free to use but make sure to modify accordingly to your requirements
#################################################
#                 customize IAM                 #
#################################################
resource "aws_iam_role" "customEcsRole" {
  path                 = "/"
  name                 = var.roleAdm
  assume_role_policy   = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ecs-tasks.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
  max_session_duration = 3600
  tags                 = {}
}
resource "aws_iam_policy_attachment" "ecrToEcsRole" {
  name       = "ecrToEcs"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  roles      = [aws_iam_role.customEcsRole.name]

}
resource "aws_iam_policy_attachment" "ecsTaskToEcsRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  roles      = [aws_iam_role.customEcsRole.name]
  name       = "ecsTaskToEcs"
}
resource "aws_iam_policy_attachment" "rdstoEcsRole" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  roles      = [aws_iam_role.customEcsRole.name]
  name       = "rdsToEcs"
}
resource "aws_iam_policy_attachment" "secretToEcsRole" {
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  roles      = [aws_iam_role.customEcsRole.name]
  name       = "secretToEcs"
}
resource "aws_iam_policy_attachment" "dbToEcsRole" {
  policy_arn = "arn:aws:iam::aws:policy/job-function/DatabaseAdministrator"
  roles      = [aws_iam_role.customEcsRole.name]
  name       = "dbToEcs"
}
#################################################
#                       CORE                    #
#################################################
#network
resource "aws_vpc" "main" {
  cidr_block           = var.main_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "privateSubApne1a" {
  availability_zone       = "ap-southeast-1a"
  cidr_block              = var.privateSubApne1a_cidr
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = false
}

resource "aws_subnet" "publicSubApne1a" {
  availability_zone       = "ap-southeast-1a"
  cidr_block              = var.publicSubApne1a_cidr
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_subnet" "privateSubApne1c" {
  availability_zone       = "ap-southeast-1c"
  cidr_block              = var.privateSubApne1c_cidr
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = false
}

resource "aws_subnet" "publicSubApne1c" {
  availability_zone       = "ap-southeast-1c"
  cidr_block              = var.publicSubApne1c_cidr
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_internet_gateway" "igw" {
  tags = {
    Name = "igw"
  }
  vpc_id = aws_vpc.main.id
}

resource "aws_eip" "nat" {
}

resource "aws_nat_gateway" "natGW" {
  subnet_id = aws_subnet.privateSubApne1a.id
  tags = {
    Name = "nat"
  }
  allocation_id = aws_eip.nat.id
  depends_on    = [aws_internet_gateway.igw]
}
#resource "aws_network_interface" "natInterface" {
#    subnet_id = aws_subnet.privateSubApne1a.id
#    private_ip = "10.0.0.1"
#    source_dest_check = true
#    security_groups = [
#        "${aws_security_group.ecsClusterSecGrp.id}"
#    ]
#    depends_on = [ aws_subnet.privateSubApne1a ]
#}

#resource "aws_eip_association" "privateSubnet" {
#   allocation_id = aws_eip.nat.id
#   network_interface_id = aws_network_interface.natInterface.id
#   depends_on = [ aws_ecs_service.ecsSvc ]
#}




resource "aws_network_acl" "defaultNACL" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "default"
  }
}

resource "aws_network_acl_rule" "outboundRule" {
  cidr_block     = "0.0.0.0/0"
  egress         = true
  network_acl_id = aws_network_acl.defaultNACL.id
  protocol       = -1
  rule_action    = "allow"
  rule_number    = 100
  depends_on     = [aws_network_acl.defaultNACL]
}

resource "aws_network_acl_rule" "inboundRule" {
  cidr_block     = "0.0.0.0/0"
  egress         = false
  network_acl_id = aws_network_acl.defaultNACL.id
  protocol       = -1
  rule_action    = "allow"
  rule_number    = 100
  depends_on     = [aws_network_acl.defaultNACL]
}

resource "aws_route_table" "rtIntranet" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "rt_intranet"
  }
}

resource "aws_route_table" "rtPublic" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "rt_public"
  }
}

resource "aws_route_table" "default" {
  vpc_id = aws_vpc.main.id
  tags   = {}
}

resource "aws_route" "intraToPublicRoute" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natGW.id
  route_table_id         = aws_route_table.rtIntranet.id
  depends_on             = [aws_route_table.rtIntranet]
}

resource "aws_route" "s3EndpointRoute" {
  gateway_id     = aws_vpc_endpoint.endpointS3.id
  route_table_id = aws_route_table.rtIntranet.id
  destination_cidr_block = "0.0.0.0/0"
  depends_on = [
    aws_route_table.rtIntranet,
    aws_vpc_endpoint.endpointS3
  ]
}

resource "aws_route" "igwRoute" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  route_table_id         = aws_route_table.rtPublic.id
}

resource "aws_vpc_endpoint" "endpointEcrApi" {
  vpc_endpoint_type = "Interface"
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-southeast-1.ecr.api"
  policy            = <<EOF
{
  "Statement": [
    {
      "Action": "*", 
      "Effect": "Allow", 
      "Principal": "*", 
      "Resource": "*"
    }
  ]
}
EOF
  subnet_ids = [
    aws_subnet.privateSubApne1a.id,
    aws_subnet.privateSubApne1c.id
  ]
  private_dns_enabled = true
  security_group_ids = [
    "${aws_security_group.ecrSecurityGrp.id}"
  ]
}

resource "aws_vpc_endpoint" "endpointEcrDkr" {
  vpc_endpoint_type = "Interface"
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-southeast-1.ecr.dkr"
  policy            = <<EOF
{
  "Statement": [
    {
      "Action": "*", 
      "Effect": "Allow", 
      "Principal": "*", 
      "Resource": "*"
    }
  ]
}
EOF
  subnet_ids = [
    aws_subnet.privateSubApne1a.id,
    aws_subnet.privateSubApne1c.id
  ]
  private_dns_enabled = true
  security_group_ids = [
    "${aws_security_group.ecrSecurityGrp.id}"
  ]
  depends_on = [aws_vpc.main]
}

resource "aws_vpc_endpoint" "endpointS3" {
  vpc_endpoint_type = "Gateway"
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-southeast-1.s3"
  policy            = "{\"Version\":\"2008-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"*\",\"Resource\":\"*\"}]}"
  route_table_ids = [
    aws_route_table.rtIntranet.id
  ]
  private_dns_enabled = false
  depends_on          = [aws_vpc.main]
}

resource "aws_route_table_association" "privateSubApne1cToIntranet" {
  route_table_id = aws_route_table.rtIntranet.id
  subnet_id      = aws_subnet.publicSubApne1c.id
}

resource "aws_route_table_association" "privateSubApne1aToIntranet" {
  route_table_id = aws_route_table.rtIntranet.id
  subnet_id      = aws_subnet.publicSubApne1c.id
}

resource "aws_route_table_association" "publicSubApne1cToPublic" {
  route_table_id = aws_route_table.rtPublic.id
  subnet_id      = aws_subnet.publicSubApne1c.id
}

resource "aws_route_table_association" "publicSubApne1aToPublic" {
  route_table_id = aws_route_table.rtPublic.id
  subnet_id      = aws_subnet.publicSubApne1a.id
}

resource "aws_lb" "extLb" {
  name               = "alb-ext"
  internal           = false
  load_balancer_type = "application"
  subnets = [
    aws_subnet.publicSubApne1a.id,
    aws_subnet.publicSubApne1c.id
  ]
  security_groups = [
    "${aws_security_group.lbSecurityGrp.id}"
  ]
  ip_address_type = "ipv4"
  access_logs {
    enabled = false
    bucket  = ""
    prefix  = ""
  }
  idle_timeout                     = "60"
  enable_deletion_protection       = "false"
  enable_http2                     = "true"
  enable_cross_zone_load_balancing = "true"
}

resource "aws_lb_listener" "lbListener" {
  load_balancer_arn = aws_lb.extLb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.lbTargetGrp.arn
    type             = "forward"
  }
  depends_on = [aws_lb_target_group.lbTargetGrp]
}


#if you want to test using a self signed cert uncomment below and make sure to create your self signed cert then upload it to your aws account
#if for example you are using localstack if not remove the endpoint url e.g: aws iam upload-server-certificate --server-certificate-name testonly --certificate-body file://selfsigned/testonly.crt --private-key file://selfsigned/testonly.key --endpoint-url=http://localhost:4566
#resource "aws_lb_listener" "lbListener" {
#  load_balancer_arn = aws_lb.extLb.arn
#  port              = 80
#  protocol          = "HTTP"
#  default_action {
#    type = "redirect"
#    redirect {
#      port = 443
#      protocol = "HTTPS"
#      status_code = "HTTP_301"
#    }
#
#  }
#  depends_on = [aws_lb_target_group.lbTargetGrp]
#}
#
#resource "aws_lb_listener" "lbListener443" {
#  load_balancer_arn = aws_lb.extLb.arn
#  port              = 443
#  protocol          = "HTTPS"
#  certificate_arn = "arn:aws:iam::${local.accountId}:server-certificate/testonly" #change this accordingly
#  default_action {
#    target_group_arn = aws_lb_target_group.lbTargetGrp.arn
#    type             = "forward"
#  }
#  depends_on = [aws_lb_target_group.lbTargetGrp]
#}

# security groups
resource "aws_security_group" "lbSecurityGrp" {
  description = "main sg for loadbalancer"
  name        = "lb-sg"
  tags        = {}
  vpc_id      = aws_vpc.main.id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 80
    protocol  = "tcp"
    to_port   = 80
  }
  ingress {
    cidr_blocks = [
      "${aws_vpc.main.cidr_block}"
    ]
    from_port = 0
    protocol  = "-1"
    to_port   = 0
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 443
    protocol  = "tcp"
    to_port   = 443
  }
  egress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 0
    protocol  = "-1"
    to_port   = 0
  }
}

resource "aws_security_group" "ecsClusterSecGrp" {
  description = "ecs cluster security group"
  name        = "ecs-sg"
  tags        = {}
  vpc_id      = aws_vpc.main.id
  ingress {
    security_groups = [
      "${aws_security_group.lbSecurityGrp.id}"
    ]
    description = "http from loadbalaner"
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }
  ingress {
    cidr_blocks = [
      "${aws_vpc.main.cidr_block}"
    ]
    description = "all intranet traffic"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
  ingress {
    security_groups = [
      "${aws_security_group.lbSecurityGrp.id}"
    ]
    description = "https from loadbalaner"
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
  }
  egress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 0
    protocol  = "-1"
    to_port   = 0
  }
}

resource "aws_security_group" "rdsSecurityGrp" {
  description = "postgres security group"
  name        = "db-sg"
  tags        = {}
  vpc_id      = aws_vpc.main.id
  ingress {
    security_groups = [
      "${aws_security_group.ecsClusterSecGrp.id}"
    ]
    from_port = 5432
    protocol  = "tcp"
    to_port   = 5432
  }
  egress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 0
    protocol  = "tcp"
    to_port   = 65535
  }
  egress {
    security_groups = [
      "${aws_security_group.ecsClusterSecGrp.id}"
    ]
    from_port = 5432
    protocol  = "tcp"
    to_port   = 5432
  }
}

resource "aws_security_group" "ecrSecurityGrp" {
  description = "allow ecr pull from private sub"
  name        = "ecr-sg"
  tags        = {}
  vpc_id      = aws_vpc.main.id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 0
    protocol  = "-1"
    to_port   = 0
  }
  egress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 0
    protocol  = "-1"
    to_port   = 0
  }
}

# LB Handler
resource "aws_lb_target_group" "lbTargetGrp" {
  health_check {
    interval            = 30
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 5
    matcher             = "200"
  }
  #port        = 80
  #protocol    = "HTTP"
  port        = 443
  protocol    = "HTTPS"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
  name        = "ecs-tg"
  depends_on  = [aws_vpc.main]
}

resource "aws_ecr_repository" "app1" {
  name = var.task_families_name[0]
  depends_on = [
    aws_vpc_endpoint.endpointEcrApi,
    aws_vpc_endpoint.endpointS3
  ]
}

resource "aws_ecr_repository" "app2" {
  name = var.task_families_name[1]
  depends_on = [
    aws_vpc_endpoint.endpointEcrApi,
    aws_vpc_endpoint.endpointS3
  ]
}

resource "aws_ecr_repository" "app3" {
  name = var.task_families_name[2]
  depends_on = [
    aws_vpc_endpoint.endpointEcrApi,
    aws_vpc_endpoint.endpointS3
  ]
}

resource "aws_ecr_repository" "dbRepo" {
  name = var.db_img_name
}

resource "null_resource" "app1ImagePush" {
  provisioner "local-exec" {
    command = "docker push ${local.accountId}.dkr.ecr.${var.region}.amazonaws.com/${var.task_families_name[0]}:latest"
  }
  depends_on = [aws_ecr_repository.app1]
}

resource "null_resource" "app2ImagePush" {
  provisioner "local-exec" {
    command = "docker push ${local.accountId}.dkr.ecr.${var.region}.amazonaws.com/${var.task_families_name[1]}:latest"
  }
  depends_on = [aws_ecr_repository.app2]
}

resource "null_resource" "app3ImagePush" {
  provisioner "local-exec" {
    command = "docker push ${local.accountId}.dkr.ecr.${var.region}.amazonaws.com/${var.task_families_name[2]}:latest"
  }
  depends_on = [aws_ecr_repository.app3]
}

#################################################
#                      ECS                      #
#################################################
resource "aws_ecs_cluster" "ecsCluster" {
  name = "hl-ecs-cluster"
  depends_on = [
    aws_vpc.main,
    aws_vpc_endpoint.endpointEcrApi,
    aws_vpc_endpoint.endpointS3
  ]
}

data "aws_caller_identity" "current" {}
locals {
  accountId = data.aws_caller_identity.current.account_id
}

#1
resource "aws_ecs_task_definition" "ecsTaskDef" {
  family             = var.task_families_name[0]
  task_role_arn      = aws_iam_role.customEcsRole.arn
  execution_role_arn = aws_iam_role.customEcsRole.arn
  network_mode       = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]
  cpu    = "1024"
  memory = "3072"

  container_definitions = <<EOF
  [
    {
      "name" : "${var.task_families_name[0]}",
      "image" : "${local.accountId}:dkr.ecr.${var.region}.amazonaws.com/${var.task_families_name[0]}:latest",
      "cpu" : 0,
      "portMappings" :   [{
        "containerPort" : 80,
        "hostPort" : 80,
        "protocol" : "tcp",
        "name" : "${var.task_families_name[0]}-80-tcp",
        "appProtocol" : "http"
      }],
      "essential" : true,
      "environment" : [],
      "environmentFiles" : [],
      "mountPoints" : [],
      "volumesFrom" : [],
      "ulimits" : []
    }
  ]
  EOF

  depends_on = [
    aws_ecs_cluster.ecsCluster,
    null_resource.app1ImagePush
  ]
}

resource "aws_ecs_service" "ecsSvc" {
  name    = var.task_families_name[0]
  cluster = aws_ecs_cluster.ecsCluster.id

  load_balancer {
    target_group_arn = aws_lb_target_group.lbTargetGrp.arn
    container_name   = var.task_families_name[0]
    container_port   = 80
  }
  desired_count                      = 1
  platform_version                   = "LATEST"
  task_definition                    = aws_ecs_task_definition.ecsTaskDef.arn
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  network_configuration {
    assign_public_ip = false
    security_groups = [
      "${aws_security_group.ecsClusterSecGrp.id}"
    ]
    subnets = [
      aws_subnet.privateSubApne1a.id,
      aws_subnet.privateSubApne1c.id
    ]
  }
  health_check_grace_period_seconds = 0
  scheduling_strategy               = "REPLICA"
  depends_on = [
    aws_ecs_cluster.ecsCluster,
    aws_lb.extLb,
    aws_subnet.privateSubApne1a,
    aws_subnet.privateSubApne1c,
    aws_ecs_task_definition.ecsTaskDef
  ]
}

#2
resource "aws_ecs_task_definition" "ecsTaskDef2" {
  family             = var.task_families_name[1]
  task_role_arn      = aws_iam_role.customEcsRole.arn
  execution_role_arn = aws_iam_role.customEcsRole.arn
  network_mode       = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]
  cpu    = "1024"
  memory = "3072"

  container_definitions = <<EOF
  [
    {
      "name" : "${var.task_families_name[1]}",
      "image" : "${local.accountId}:dkr.ecr.${var.region}.amazonaws.com/${var.task_families_name[1]}:latest",
      "cpu" : 0,
      "portMappings" :   [{
        "containerPort" : 80,
        "hostPort" : 80,
        "protocol" : "tcp",
        "name" : "${var.task_families_name[1]}-80-tcp",
        "appProtocol" : "http"
      }],
      "essential" : true,
      "environment" : [],
      "environmentFiles" : [],
      "mountPoints" : [],
      "volumesFrom" : [],
      "ulimits" : []
    }
  ]
  EOF

  depends_on = [
    aws_ecs_cluster.ecsCluster,
    null_resource.app1ImagePush
  ]
}

resource "aws_ecs_service" "ecsSvc2" {
  name    = var.task_families_name[1]
  cluster = aws_ecs_cluster.ecsCluster.id

  load_balancer {
    target_group_arn = aws_lb_target_group.lbTargetGrp.arn
    container_name   = var.task_families_name[1]
    container_port   = 80
  }
  desired_count                      = 1
  platform_version                   = "LATEST"
  task_definition                    = aws_ecs_task_definition.ecsTaskDef2.arn
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  network_configuration {
    assign_public_ip = false
    security_groups = [
      "${aws_security_group.ecsClusterSecGrp.id}"
    ]
    subnets = [
      aws_subnet.privateSubApne1a.id,
      aws_subnet.privateSubApne1c.id
    ]
  }
  health_check_grace_period_seconds = 0
  scheduling_strategy               = "REPLICA"
  depends_on = [
    aws_ecs_cluster.ecsCluster,
    aws_lb.extLb,
    aws_subnet.privateSubApne1a,
    aws_subnet.privateSubApne1c,
    aws_ecs_task_definition.ecsTaskDef
  ]
}
#3
resource "aws_ecs_task_definition" "ecsTaskDef3" {
  family             = var.task_families_name[2]
  task_role_arn      = aws_iam_role.customEcsRole.arn
  execution_role_arn = aws_iam_role.customEcsRole.arn
  network_mode       = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]
  cpu    = "1024"
  memory = "3072"

  container_definitions = <<EOF
  [
    {
      "name" : "${var.task_families_name[2]}",
      "image" : "${local.accountId}:dkr.ecr.${var.region}.amazonaws.com/${var.task_families_name[2]}:latest",
      "cpu" : 0,
      "portMappings" :   [{
        "containerPort" : 80,
        "hostPort" : 80,
        "protocol" : "tcp",
        "name" : "${var.task_families_name[2]}-80-tcp",
        "appProtocol" : "http"
      }],
      "essential" : true,
      "environment" : [],
      "environmentFiles" : [],
      "mountPoints" : [],
      "volumesFrom" : [],
      "ulimits" : []
    }
  ]
  EOF

  depends_on = [
    aws_ecs_cluster.ecsCluster,
    null_resource.app1ImagePush
  ]
}

resource "aws_ecs_service" "ecsSvc3" {
  name    = var.task_families_name[2]
  cluster = aws_ecs_cluster.ecsCluster.id

  load_balancer {
    target_group_arn = aws_lb_target_group.lbTargetGrp.arn
    container_name   = var.task_families_name[2]
    container_port   = 80
  }
  desired_count                      = 1
  platform_version                   = "LATEST"
  task_definition                    = aws_ecs_task_definition.ecsTaskDef2.arn
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  network_configuration {
    assign_public_ip = false
    security_groups = [
      "${aws_security_group.ecsClusterSecGrp.id}"
    ]
    subnets = [
      aws_subnet.privateSubApne1a.id,
      aws_subnet.privateSubApne1c.id
    ]
  }
  health_check_grace_period_seconds = 0
  scheduling_strategy               = "REPLICA"
  depends_on = [
    aws_ecs_cluster.ecsCluster,
    aws_lb.extLb,
    aws_subnet.privateSubApne1a,
    aws_subnet.privateSubApne1c,
    aws_ecs_task_definition.ecsTaskDef
  ]
}


#################################################   
#                      RDS                      #
#################################################
resource "aws_db_instance" "rds" {
  allocated_storage      = 20
  identifier             = "hldatabase" #change this then remove this comment rds cannot parse data from variable
  username               = var.dbusername
  password               = var.dbpassword
  engine                 = "postgresql"
  engine_version         = "14.6"
  instance_class         = "db.t3.micro"
  vpc_security_group_ids = [aws_security_group.rdsSecurityGrp.id]
  db_subnet_group_name   = aws_db_subnet_group.rdsSubnetGrp.name
  depends_on             = [aws_db_subnet_group.rdsSubnetGrp]
}
resource "aws_db_subnet_group" "rdsSubnetGrp" {
  subnet_ids = [
    aws_subnet.privateSubApne1a.id,
    aws_subnet.privateSubApne1c.id
  ]
  depends_on = [
    aws_subnet.privateSubApne1a,
    aws_subnet.privateSubApne1c
  ]
}

#optional but can be handy for mapping
resource "aws_service_discovery_http_namespace" "serviceDiscoverNamespace" {
  name = aws_ecs_cluster.ecsCluster.name
}