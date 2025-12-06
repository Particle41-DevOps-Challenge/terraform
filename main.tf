resource "aws_vpc" "main" {
    cidr_block = var.cidr_block
    instance_tenancy = "default"
    enable_dns_hostnames = "true"


    tags = merge(
        var.vpc_tags,
        local.common_tags,
        {
            Name = "${var.project}"
        }
    ) 
}

#IGW Particle41
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id # association with VPC

    tags = merge(
        var.igw_tags,
        local.common_tags,
        {
            Name = "${var.project}"
        }
    )  
}

#Particle41-us-east-1
resource "aws_subnet" "public" {
    count = length(var.public_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidrs[count.index]

    availability_zone = local.az_names[count.index]
    map_public_ip_on_launch = true

    tags = merge(
        var.public_subnet_tags,
        local.common_tags,
        {
            Name = "${var.project}-public-${local.az_names[count.index]}"
        }
    )
  
}

resource "aws_subnet" "private" {
    count = length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidrs[count.index]

    availability_zone = local.az_names[count.index]
    
    tags = merge(
        var.private_subnet_tags,
        local.common_tags,
        {
            Name = "${var.project}-private-${local.az_names[count.index]}"
        }
    )
}


resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    tags = merge(
        var.public_route_table_tags,
        local.common_tags,
        {
            Name = "${var.project}-public"
        }
    )
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    tags = merge(
        var.private_route_table_tags,
        local.common_tags,
        {
            Name = "${var.project}-private"
        }
    )
}

resource "aws_route_table_association" "public" {
    count = length(var.public_subnet_cidrs)
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id  
}

resource "aws_route_table_association" "private" {
    count = length(var.private_subnet_cidrs)
    subnet_id = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private.id  
}



module "eks" {
    source = "terraform-aws-modules/eks/aws"
    version = "~> 21.0" # this is module version

    name = "${var.project}"
    kubernetes_version = "1.33"

    addons = {
        coredns = {}
        eks-pod-identity-agent = {
            before_compute = true
        }
        kube-proxy = {}
        vpc-cni = {
            before_compute = true
        }
        metrics-server = {}
    }

    #Optional
    endpoint_public_access = false

    # Optional: Adds the current caller identity as an administrator via cluster access entry
    enable_cluster_creator_admin_permissions = true

    vpc_id = aws_vpc.main.id
    subnet_ids = aws_subnet.private[*].id
    control_plane_subnet_ids = aws_subnet.private[*].id

    create_node_security_group = false
    create_security_group = false
    security_group_id = aws_security_group.main.id
    node_security_group_id = aws_security_group.main.id

    # EKS Managed Node Group(s)
    eks_managed_node_groups = {
        green = {
            # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
            ami_type = "AL2023_x86_64_STANDARD" # user name is ec2-user
            instance_type = ["m5.xlarge"]

            min_size = 1
            max_sixe = 10
            desired_size = 1

            iam_role_additional_policies = {
                AmazonEBS = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
                AmazonEFS = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
                AmazonEKSLoad = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
            }

        }
    }

    tags = merge(
        local.common_tags,
        {
            Name = "${var.project}"
        }
    )

}

resource "aws_security_group" "main" {
    name = "${var.project}-SG"
    description = "Security Group for EKS"
    vpc_id = aws_vpc.main.id


    egress {
        from_port = 0
        to_port =  0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = merge(
        local.common_tags,
        {
            Name = "${var.project}"
        }
    )
  
}



module "alb" {
  source = "terraform-aws-modules/alb/aws"
  version = "9.16.0"
  internal = false
  name    = "${var.project}-alb" #roboshop-dev-ingress-alb
  vpc_id  = aws_vpc.main.id
  subnets = aws_subnet.public[*].id
  create_security_group = false
  security_groups = [ aws_security_group.main.id ]
  enable_deletion_protection = false
  tags = merge(
    local.common_tags,
    {
        Name = "${var.project}-ingress-alb"
    }
  )
}
