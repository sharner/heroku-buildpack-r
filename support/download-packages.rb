#!/usr/bin/env ruby

require 'aws/s3'

include AWS::S3

rversion="2.15.1"

puts "Downloading R"
%x[ wget "http://cran.r-project.org/src/base/R-2/R-#{rversion}.tar.gz" ]
%x[ tar zxvf "R-#{rversion}.tar.gz" ]
%x[ rm "R-#{rversion}.tar.gz" ]

packages=["colorspace", "RColorBrewer", "dichromat", "munsell", "labeling", "SparseM", "sp", "mvtnorm", "digest", "memoise", "proto", "quantreg", "Hmisc", "maps", "mapproj", "hexbin", "gpclib", "maptools", "multcomp", "abind", "plyr", "stringr", "evaluate", "testthat", "RUnit", "randomForest", "scales", "reshape2", "ggplot2", "iterators", "itertools", "foreach", "rjson"]

package_versions=["colorspace_1.1-1.tar.gz", "RColorBrewer_1.0-5.tar.gz", "dichromat_1.2-4.tar.gz", "munsell_0.3.tar.gz", "labeling_0.1.tar.gz", "SparseM_0.96.tar.gz", "sp_0.9-99.tar.gz", "mvtnorm_0.9-9992.tar.gz", "digest_0.5.2.tar.gz", "memoise_0.1.tar.gz", "proto_0.3-9.2.tar.gz", "quantreg_4.81.tar.gz", "Hmisc_3.9-3.tar.gz", "maps_2.2-6.tar.gz", "mapproj_1.1-8.3.tar.gz", "hexbin_1.26.0.tar.gz", "gpclib_1.5-3.tar.gz", "maptools_0.8-16.tar.gz", "multcomp_1.2-12.tar.gz", "abind_1.4-0.tar.gz", "plyr_1.7.1.tar.gz", "stringr_0.6.1.tar.gz", "evaluate_0.4.2.tar.gz", "testthat_0.7.tar.gz", "RUnit_0.4.26.tar.gz", "randomForest_4.6-6.tar.gz", "scales_0.2.1.tar.gz", "reshape2_1.2.1.tar.gz", "ggplot2_0.9.1.tar.gz", "iterators_1.0.6.tar.gz", "itertools_0.1-1.tar.gz", "foreach_1.4.0.tar.gz", "rjson_0.2.9.tar.gz"]

package_versions.zip(packages) do |f, l| 
  puts "Fetching #{f}"
  %x[ wget "http://cran.r-project.org/src/contrib/#{f}" ]
  %x[ mv "#{f}" "R-#{rversion}/src/library/Recommended" ]
  %x[ cd "R-#{rversion}/src/library/Recommended" ; ln -s "#{f}" "#{l}.tgz" ]
end

packages_str = packages.join(' ')

# Update this with share/make/vars.mk
vars_mk = <<EOF
R_PKGS_BASE = base tools utils grDevices graphics stats datasets methods grid splines stats4 tcltk compiler parallel
## Those which can be installed initially compiled (not base tools)
R_PKGS_BASE1 = utils grDevices graphics stats datasets methods grid splines stats4 tcltk parallel
## Those with standard R directories (not datasets, methods)
R_PKGS_BASE2 = base tools utils grDevices graphics stats grid splines stats4 tcltk compiler parallel

R_PKGS_RECOMMENDED =  MASS lattice Matrix nlme survival boot cluster codetools foreign KernSmooth rpart class nnet spatial mgcv #{packages_str}
EOF

puts "Backing up vars.mk"
%x[ mv "R-#{rversion}/share/make/vars.mk" "vars.mk.back" ]

puts "Adding dependencies to var.mk"
File.open("R-#{rversion}/share/make/vars.mk", "w") do |file|
  file << vars_mk
end

puts "Packaging R distribution"
%x[ tar zcvf "R-#{rversion}.tgz" "R-#{rversion}" ]
%x[ rm -rf "R-#{rversion}" ]

puts "Uploading modified R version to S3"
Base.establish_connection!(:access_key_id     => ENV['AWSACCESSKEY'],
                           :secret_access_key =>  ENV['AWSSECRETKEY'])
S3Object.store("R-#{rversion}.tgz", open("R-#{rversion}.tgz"), ENV['AWSBUCKET'])

puts "Don't forget to enable download permission for everyone!"
