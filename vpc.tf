/* Query all the availability zones */
data "aws_availability_zones" "get_all" {}

/* create VPC */
resource "aws_vpc" "main" {
  cidr_block = var.cidr_block

  /* Enable DNS support and DNS hostnames to support private hosted zones */
  enable_dns_support   = var.enable_dns
  enable_dns_hostnames = var.enable_dns

  lifecycle {
    prevent_destroy = false
  }

  tags = merge(var.tags, local.tags, { "vpc" = var.name })
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  count = length(var.secondary_cidr_block)

  vpc_id     = aws_vpc.main.id
  cidr_block = var.secondary_cidr_block[count.index]
}

/* create a single internet gateway */
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, local.tags)
}

/*
  Provision NAT Gateway per Availability Zone
*/
resource "aws_eip" "eip" {
  count = length(local.availability_zones)

  tags = merge(var.tags, local.tags, { "Name" = format("%s.%s", var.name,
                                                                local.availability_zones[ count.index ]) },
                                     { "vpc"    = var.name },
                                     { "region" = local.availability_zones[ count.index ] })
}

resource "aws_nat_gateway" "ngw" {
  count = length(local.availability_zones)

  allocation_id = aws_eip.eip[ count.index ].id
  subnet_id     = aws_subnet.public[ count.index ].id

  tags = merge(var.tags, local.tags, { "Name" = format("%s.%s", var.name,
                                                                local.availability_zones[ count.index ]) },
                                     { "vpc"    = var.name },
                                     { "region" = local.availability_zones[ count.index ] })
}

/* create a route table for the public subnet(s) */
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, local.tags, { "Name" = "public" },
                                     { "VPC" = var.name },
                                     { "region" = "all" })
}

resource "aws_route" "public" {
  route_table_id = aws_route_table.public.id

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

/* create a route table per Availability Zone for private subnet(s) */
resource "aws_route_table" "private" {
  count = length(local.availability_zones)

  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, local.tags, { "Name" = "private" },
                                     { "vpc"  = var.name },
                                     { "region" = local.availability_zones[ count.index ] })
}

resource "aws_route" "private" {
  count = length(local.availability_zones)

  route_table_id = aws_route_table.private[ count.index ].id

  /* default route is NAT gateway */
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw[ count.index ].id
}

/*
  Private subnet 
  Dependencies: aws_vpc.main
*/

/* only used if list of private subnets to create isn't passed in */
resource "null_resource" "generated_private_subnets" {
  /* create a subnet for each availability zone required */
  count = length(local.availability_zones)

  triggers = {
    cidr_block = cidrsubnet(aws_vpc.main.cidr_block, var.cidr_block_bits, length(local.availability_zones) + count.index)
  }
}

resource "aws_subnet" "private" {
  count = length(local.availability_zones)

  vpc_id = aws_vpc.main.id

  cidr_block = local.private_subnets[ count.index ]

  /* load balance over all availability zones */
  availability_zone = element(local.availability_zones, count.index)

  /* private subnet, no public IPs */
  map_public_ip_on_launch = false

  /* merge all the tags together */
  tags = merge(var.tags, var.private_subnet_tags, local.tags, { "Name" = format("private-%d.%s", count.index,
                                                                                                 var.name) })
  depends_on = [ aws_vpc_ipv4_cidr_block_association.this ]
}

/*
  Public subnet 
  Dependencies: aws_vpc.main
*/

resource "null_resource" "generated_public_subnets" {
  /* create subnet for each availability zone required */
  count = length(local.availability_zones)

  triggers = {
    cidr_block = cidrsubnet(aws_vpc.main.cidr_block, var.cidr_block_bits, count.index)
  }
}

resource "aws_subnet" "public" {
  count = length(local.availability_zones)

  vpc_id = aws_vpc.main.id

  /* create subnet at the end of the cidr block */
  cidr_block = local.public_subnets[ count.index ]

  /* load balance over all the availabilty zones */
  availability_zone = element(local.availability_zones, count.index)

  /* instances in the public zone get an IP address */
  map_public_ip_on_launch = var.enable_public_ip

  /* merge all the tags together */
  tags = merge(var.tags, var.public_subnet_tags, local.tags, { "Name" = format("public-%d.%s", count.index,
                                                                                               var.name) })

  depends_on = [ aws_vpc_ipv4_cidr_block_association.this ]
}

/*
  Associate the public subnet with the above route table
  Dependencies: aws_subnet.public, aws_route_table.public
*/
resource "aws_route_table_association" "public" {
  count = length(local.availability_zones)

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

/*
  Associate the private subnet(s) with the main VPC route table
  Dependencies: aws_subnet.private, aws_vpc.main
*/
resource "aws_route_table_association" "private" {
  count = length(local.availability_zones)

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

