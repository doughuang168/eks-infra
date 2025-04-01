resource "kubectl_manifest" "jenkins_ns" {
  yaml_body = <<YAML
kind: Namespace
apiVersion: v1
metadata:
  name: jenkins
YAML
}

