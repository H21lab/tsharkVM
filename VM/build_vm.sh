#
# Created by Martin Kacer
# Copyright 2020 H21 lab, All right reserved, https://www.h21lab.com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#!/bin/bash

# vagrant destroy default

rm ./Vagrantfile
vagrant init debian/buster64
cat Vagrantfile_template > Vagrantfile
vagrant up
