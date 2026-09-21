#!/bin/bash 

for i in `grep -l -i 'SPDX-License-Identifier' -R $1` ; do 
  echo $i ; 
  # modify the SPDX-License-Identifier and remove the empty next line
  ext=$(echo $i | cut -d . -f 2)
  if echo $ext | grep -E '^(cc|h|inl|cu)$' > /dev/null ; then 
    echo "is a C++ file";
    perl -0777 -pe 's/(SPDX-License-Identifier:) LicenseRef-NvidiaProprietary\n(.*)\n/\n\2 \1 Apache-2.0\n/mg' -i $i;
  else 
    perl -0777 -pe 's/(SPDX-License-Identifier:) LicenseRef-NvidiaProprietary(\n.*)\n/\1 Apache-2.0\n/mg' -i $i;
  fi
  # remove the paragraph about license's terms of usage
  sed -i -r '/NVIDIA CORPORATION, its affiliates and licensors retain/,/its affiliates is strictly prohibited/d' $i ;
done
