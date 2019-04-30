data "aws_cloudformation_stack" "rdgw" {
  name = "${var.StackName}"
  depends_on = ["null_resource.push-changeset"]
}
data "aws_lb" "rdgw" {
  arn = "${data.aws_cloudformation_stack.rdgw.outputs["LoadBalancerName"]}"
  depends_on = ["data.aws_cloudformation_stack.rdgw"]
}
resource "null_resource" "push-changeset" {
  provisioner "local-exec" {
    command     = "${join(" ", local.create_changeset_command)}"
    working_dir = ".."
  }

  provisioner "local-exec" {
    command = "${join(" ", local.destroy_changeset_command)}"
    when    = "destroy"
  }
}
locals {
  create_changeset_command = [
    "aws cloudformation deploy --template",
    "cfn/ra_rdgw_autoscale_public_lb.template.cfn.json",
    " --stack-name ${var.StackName}",
    " --s3-bucket ${var.S3Bucket}",
    " --parameter-overrides AmiId=${var.AmiId}",
    "\"AmiNameSearchString=${var.AmiNameSearchString}\"",
    "\"AuthenticationMethod=${var.AuthenticationMethod}\"",
    "\"CloudWatchAgentUrl=${var.CloudWatchAgentUrl}\"",
    "\"DesiredCapacity=${var.DesiredCapacity}\"",
    "\"DomainDirectoryId=${var.DomainDirectoryId}\"",
    "\"DomainDnsName=${var.DomainDnsName}\"",
    "\"DomainNetbiosName=${var.DomainNetbiosName}\"",
    "\"ForceUpdateToggle=${var.ForceUpdateToggle}\"",
    "\"InstanceType=${var.InstanceType}\"",
    "\"KeyPairName=${var.KeyPairName}\"",
    "\"MaxCapacity=${var.MaxCapacity}\"",
    "\"MinCapacity=${var.MinCapacity}\"",
    "\"PrivateSubnetIDs=${var.PrivateSubnetIds}\"",
    "\"PublicSubnetIDs=${var.PublicSubnetIds}\"",
    "\"RemoteAccessUserGroup=${var.RemoteAccessUserGroup}\"",
    "\"ScaleDownDesiredCapacity=${var.ScaleDownDesiredCapacity}\"",
    "\"ScaleDownSchedule=${var.ScaleDownSchedule}\"",
    "\"ScaleUpSchedule=${var.ScaleUpSchedule}\"",
    "\"SslCertificateName=${var.SslCertificateName}\"",
    "\"SslCertificateService=${var.SslCertificateService}\"",
    "\"UpdateSchedule=${var.UpdateSchedule}\"",
    "\"VPC=${var.VpcId}\"",
    "--capabilities CAPABILITY_IAM",
  ]

  check_stack_progress = [
    "aws cloudformation wait stack-create-complete --stack-name ${var.StackName}",
  ]

  destroy_changeset_command = [
    "aws cloudformation delete-stack --stack-name ${var.StackName}",
  ]
}
resource "aws_route53_record" "lb_pub_dns" {
  zone_id = "${var.Public_Dnszone_Id}"
  name    = "${var.Dns_Name}"
  type    = "A"
  alias {
    name                   = "${data.aws_lb.rdgw.dns_name}"
    zone_id                = "${data.aws_lb.rdgw.zone_id}"
    evaluate_target_health = true
  }
}