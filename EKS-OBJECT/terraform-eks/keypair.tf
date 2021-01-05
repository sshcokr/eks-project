# Upload Keypair
resource "aws_key_pair" "seunghyeon-bastion" {
  key_name = "seunghyeon-eks-bastion"
  public_key = file("/home/sin/.ssh/project/seunghyeon-eks-bastion.pub")
}
resource "aws_key_pair" "seunghyeon-eks" {
  key_name = "seunghyeon-eks"
  public_key = file("/home/sin/.ssh/project/seunghyeon-eks.pub")
}