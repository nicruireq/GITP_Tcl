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

#puts "CODIGO:\n$text"
#set ret2 [regexp -nocase -- {rising_edge\([A-Za-z0-9_]+\)} $text]
#puts "resultado expresion: $ret2"
