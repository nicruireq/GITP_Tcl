#############################################################################
#	get_testbench_template.tcl v1.0
#
#	Copyright (C) 2020 Nicolas Ruiz Requejo
#
#	 This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
# 	
############################################################################
#
#	E-mail:	nicolas.ruizre@alum.uca.es
# 	
#	Summary: 
#
#

namespace eval testbenchtemplate {
    # public procedures
    namespace export get_testbench_template

    # variables
    # holds if clock signal exists
    variable clock
    # holds string with the entity
	variable entity
	# holds string with the entity name
	variable entity_name
    # string where is formated the component
	variable tp_component
}


#
#	Checks for vhdl entity (from
#	the string 'data') if includes 
#   a clock signal
#
#	if there isn't a clock signal 
#	return 0 else return 1
#
proc ::testbenchtemplate::clock_exists {data} {
    # variables to be used in this proc
    variable clock

    # test if clock signal is present by
    # matching rising_edge, falling_edge...
    switch -regexp -nocase -- $data {
        {rising_edge\([A-Za-z0-9_]+\)} {
            set clock 1;
        }
        {falling_edge\([A-Za-z0-9_]+\)} {
            set clock 1;
        }
        {(([A-Za-z0-9_]+)'event\s+and\s+([A-Za-z0-9_]+)\s*=\s*'1')?} {
            set clock 1;
        }
        {(([A-Za-z0-9_]+)'event\s+and\s+([A-Za-z0-9_]+)\s*=\s*'0')?} {
            set clock 1;
        }
        default {
            set clock 0;
        }
    }
}

#
#	Extracts an vhdl entity declaration from
#	the string 'data'
#
#	if there isn't an entity declaration
#	return 0 else return 1
#	the entity declaration is stored in
#	namespace variable 'entity' and its name
#	in namespace variable 'entity_name'
#
proc ::testbenchtemplate::extract_entity {data} {
	# variables to be used in this proc
	variable entity
	variable entity_name
	
	set ret_ent [regexp -nocase -- \
				 {entity\s+([A-Za-z0-9_]+)\s+is.*end\s+[A-Za-z0-9_]+\s*;\s+(?=architecture)} \
				 $data entity entity_name \
	]
	
	return $ret_ent
}

#
#	Generates the component template
#
#	ent : a string with the entity's representation
#
#	if it hasn't been to possible generate the template
#	returns 0, else returns 1
#	the component template is stored in the namespace
#	variable 'tp_component'
#
proc ::testbenchtemplate::generate_component {ent} {
	# variables to be used in this proc
	variable tp_component
	
	# replace 'entity' by 'component'
	set num_subs [regsub -nocase -- {^entity} \
					$ent "component" tp_aux \
	]
	if {$num_subs} {
		# replace 'end entity_name;' by 'end component;'
		set num_subs [regsub -nocase -- \
						{end\s+([A-Za-z0-9_]+\s*);} \
						$tp_aux {end component;} tp_component \
		]
	}
	
	return $num_subs
}


# TEST
set fexample [open {./examples/FFD.vhd} "r"]
set text [read $fexample]
set ret1 [::testbenchtemplate::extract_entity $text]
puts "Devuelve: $ret1"
puts "entity:\n$::testbenchtemplate::entity"
puts "entity_name: $::testbenchtemplate::entity_name"
puts "----------------------------------------------------\n"

set ret2 [::testbenchtemplate::clock_exists $text]
puts "Tiene reloj?: $ret2"

puts "----------------------------------------------------\n"
set comp [::testbenchtemplate::generate_component $::testbenchtemplate::entity]
puts "component:\n"
puts "Resultado: $comp"
puts $::testbenchtemplate::tp_component

