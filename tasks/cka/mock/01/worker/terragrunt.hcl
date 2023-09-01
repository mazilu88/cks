include {
  path = find_in_parent_folders()
}

locals {
  vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../..//modules/work_pc/"
  # source = "../../..//modules/work_pc_ondemand/"

  extra_arguments "retry_lock" {
    commands  = get_terraform_commands_that_need_locking()
    arguments = ["-lock-timeout=20m"]
  }

}

dependency "ssh-keys" {
  config_path = "../ssh-keys"
}

dependency "vpc" {
  config_path = "../vpc"
}


dependency "cluster1" {
  config_path = "../k8s-1"
}
dependency "cluster2" {
  config_path = "../k8s-2"
}


inputs = {
  region        = local.vars.locals.region
  aws           = local.vars.locals.aws
  prefix        = local.vars.locals.prefix
  tags_common   = local.vars.locals.tags
  app_name      = "k8s-worker"
  subnets_az    = dependency.vpc.outputs.subnets_az_cmdb
  vpc_id        = dependency.vpc.outputs.vpc_id


  work_pc = {
    clusters_config = {
      cluster1 = dependency.cluster1.outputs.k8s_config
      cluster2 = dependency.cluster2.outputs.k8s_config
    }
    instance_type      = local.vars.locals.instance_type
    node_type          = local.vars.locals.node_type
    ami_id             = local.vars.locals.ami_id
    key_name           = local.vars.locals.key_name
    cidrs              = ["0.0.0.0/0"]
    subnet_number      = "0"
    user_data_template = "template/worker.sh"
    util               = {
      kubectl_version = "v1.26.0"
    }
    exam_time_minutes = "120"
    test_url          = "https://raw.githubusercontent.com/ViktorUJ/cks/master/tasks/cka/mock/01/worker/files/tests.bats"
    task_script_url   = "https://raw.githubusercontent.com/ViktorUJ/cks/master/tasks/cka/mock/01/worker/files/worker.sh"
    ssh               = {
      private_key = dependency.ssh-keys.outputs.private_key
      pub_key     = dependency.ssh-keys.outputs.pub_key
    }
    root_volume = local.vars.locals.root_volume
  }


}