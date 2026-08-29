config {
  call_module_type = "all"
}

# Bundled with tflint — no `tflint --init` download needed, so this always works.
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# The AWS ruleset is a separate download and its releases move independently of
# tflint itself. Pick the current version from
# https://github.com/terraform-linters/tflint-ruleset-aws/releases, uncomment,
# then run `tflint --init`. Left commented rather than pinned to a guessed
# version, because a version that does not exist fails `--init` with an error
# that looks like a config problem.
#
# plugin "aws" {
#   enabled = true
#   version = "0.xx.0"
#   source  = "github.com/terraform-linters/tflint-ruleset-aws"
# }
