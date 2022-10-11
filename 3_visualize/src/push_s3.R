# s3_put will only allow us to push an object with the same name as a target
# So, this function allows us to name using the input viz dates
push_s3 <- function(upload_ind, local_file, s3_file, config_file) {
  s3_config <- yaml::yaml.load_file(config_file)
  aws.signature::use_credentials(profile = s3_config$profile)
  aws.s3::put_object(file = local_file, object = s3_file, bucket = s3_config$bucket)
  scipiper::sc_indicate(upload_ind, data_file = local_file)
}
