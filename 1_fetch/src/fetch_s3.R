# s3_get will only download and save the file exactly in the filepath it appears on S3
# So, this function uses S3_get but then moves the file where we want it
fetch_s3 <- function(target_name, s3_file, dummy_date) {
  # `dummy_date` is only used to force a rebuild
  s3_config <- yaml::yaml.load_file(getOption("scipiper.s3_config_file"))
  aws.signature::use_credentials(profile = s3_config$profile)
  aws.s3::save_object(object = s3_file, bucket = s3_config$bucket, 
                      file = target_name)
}
