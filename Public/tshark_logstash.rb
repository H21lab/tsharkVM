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


def register(params)

end

def filter(event)

    # Covert all hex values (0x00...) into numbers
    l = iterate_hash(nil, event.get("layers"))
    
    event.set("layers", l)

    return [event]
end

def iterate_hash(parent, a)
    a.each {|k, v|
        if v.is_a?(Hash) 
            iterate_hash(k, v)
        elsif v.is_a?(Array)
            iterate_array(k, v)
        elsif v.is_a?(String)
            a[k] = format_field(a[k])
        end
    }
    return a
end

def iterate_array(parent, a)
    a.each_with_index {|v, i|
        if v.is_a?(Hash) 
            iterate_hash(parent, v)
        elsif v.is_a?(Array)
            iterate_array(parent, v)
        elsif v.is_a?(String)
            a[i] = format_field(v)
        end
    }
    return a
end

def format_field(f)
    if (f.start_with?("0x"))
        begin
            return Integer(f)
        rescue
            return f
        end
    end
    return f
end
