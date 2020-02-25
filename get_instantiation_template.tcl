#############################################################################
#	get_instantiation_template.tcl v1.0
#
#	Copyright (C) 2018-2019 Nicolas Ruiz Requejo
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

namespace eval ::instantiationtemplate {
	# public procedures
	namespace export get_instantiation_template
	
	# holds string with the entity
	variable entity
	# holds string with the entity name
	variable entity_name
	# string where is formated the component
	variable tp_component
	# string where is formated the component
	# instantiation statement
	variable tp_instantiation
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
proc ::instantiationtemplate::extract_entity {data} {
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
proc ::instantiationtemplate::generate_component {ent} {
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

#
#	Generates the component instantiation statement
#	
#	ent : a string with the entity's representation
#
#	if it hasn't been to possible generate the template
#	returns 0, else returns 1
#	the template is stored in the namespace
#	variable 'tp_instantiation'
#
proc ::instantiationtemplate::generate_insttp {ent entname} {
	# variables to be used in this proc
	variable tp_instantiation
	
	# count number of ports and extract their names
	# the regular expression expects first 'port ('
	# and finish with the first ');'
	# stub is discarded 
	set has_port_list [regexp -nocase -- {port\s*\((.*?)\)\s*;} \
						$ent stub str_port_list \
	]	
	# now $str_port_list has only the ports
	if {$has_port_list} {
		# split port list by ';'
		set port_list [split $str_port_list {;}]
		# declare empty list to store only ports's names
		set port_list_ns [list]
		foreach port $port_list {
			# split by ':' and get the names in index zero 
			# delete whitespaces and add to new list 
			lappend port_list_ns [string trim [lindex [split $port {:}] 0]]
		} 
	}

	# test if there is generic list in ent
	# try a regular expression which begins 
	# with 'generic' and maybe spaces and '('
	# and finish with ';' and spaces and 'port'
	# stub is discarded
	set has_generic_list [regexp -nocase -- \
							{generic\s*\((.*)\)\s*;\s*port} \
							$ent stub str_generic_list \
	]
	# now $str_generic_list may have a generic list
	if {$has_generic_list} {
		# idem to above code
		set generic_list [split $str_generic_list {;}]
		set generic_list_ns [list]
		foreach param $generic_list {
			lappend generic_list_ns [string trim [lindex [split $param {:}] 0]]
		}
	}

	# the template is generate with 'append'
	set tp_instantiation "my_"
	append tp_instantiation [string tolower $entname] " : " $entname "\n"
	# add generic instantiation
	if {$has_generic_list} {
		append tp_instantiation "\tgeneric map("
		set num_params [llength $generic_list_ns]
		# if there is only one param
		if {$num_params == 1} {
			append tp_instantiation [lindex $generic_list_ns 0] " => )\n"
		} else {
			# several params 
			for {set i 0} {$i < $num_params} {incr i} {
				if {$i == 0} {
					append tp_instantiation "\n"
				}
				if {$i == [expr ($num_params - 1)]} {
					# last param
					append tp_instantiation "\t\t" [lindex $generic_list_ns $i] " => )\n"
				} else {
					# rest of params
					append tp_instantiation "\t\t" [lindex $generic_list_ns $i] " => ,\n"
				}
			}
			
		}
	}

	# add ports instantiation 
	if {$has_port_list} {
		append tp_instantiation "\tport map(\n"
		set num_ports [llength $port_list_ns]
		for {set i 0} {$i < $num_ports} {incr i} {
			if {$i == [expr ($num_ports - 1)]} {
				# last param
				append tp_instantiation "\t\t" [lindex $port_list_ns $i] " => );\n"
			} else {
				# rest of params
				append tp_instantiation "\t\t" [lindex $port_list_ns $i] " => ,\n"
			}
		}
	}

	# return 'true' if any of port list or generic list
	# are available
	return [expr ($has_port_list || $has_generic_list)]
}

#
#	Writes the output file with templates
#
#	returns the output path where new file
#	has been written
#
proc ::instantiationtemplate::write_output_template {comptp insttp fileorig outdir} {
	# check if fileorig is null
	if {[string trim $fileorig] eq ""} {
		error " Error - the source file path is an empty string. "
	}
	# check if outdir is null
	if {[string trim $outdir] eq ""} {
		error " Error - the output directory file is an empty string. "
	}
	# check if outdir is a directory
	if {![file isdirectory [file dirname $outdir]]} {
		error " Error - dir : $outdir - is not a valid directory. "
	}

	# gets only the filename from the source path
	# the last element of a list got by splitting the path
	# by slash
	set srcname [lindex [split [string trim $fileorig] {/}] end]

	# holds the text to write in output file
	set output_text [format {
-- VHDL Component Instantiation Template 
-- Autogenerated from source file %s with 
-- get_instantiation_template.tcl
-- 
-- Notice:
-- Copy and paste the templates in your destination file(s) and then edit
-- Please if you think there might be a bug contact with us
--

%s

%s

	} $srcname $comptp $insttp]
	#DEBUG
	puts "PLANTILLA FINAL:\n\n $output_text"

	# write in file
	if {[catch {
		# create file name
		append fname [lindex [split $srcname {.}] 0] "_tp.vho"
		append outdir "/" $fname
		set tpfile [open $outdir "w"]
		puts $tpfile $output_text
		close $tpfile
	} werror]} {
		error " Error - Output file could not be wrote : $werror "
	}

	return $outdir
}

#
#	Generates a file in the directory 'outputdir'
#	with the component and component instantiation
#	templates generated from ".vhd" file 'filepath'
#
proc ::instantiationtemplate::get_instantiation_template {filepath {outputdir "."} } {
	# variables to be used in this proc
	variable entity
	variable entity_name
	variable tp_component
	variable tp_instantiation
	
	# try to open the '.vhd' file in '$filepath'
	if {[catch {
		set srcstream [open $filepath "r"]
		set vhdlsrc [read $srcstream]
		close $srcstream
	} ferror]} {
		error " File $filepath couldn't be opened : $ferror "
	}
	
	# try to match an entity declaration
	set exists_entity [::instantiationtemplate::extract_entity $vhdlsrc]
	
	if {$exists_entity} {
		# try to generate the component template
		set exists_comp [::instantiationtemplate::generate_component $entity]
		if {$exists_comp} {
			#DEBUG
			#puts "componente:\n\n $tp_component"
			# try to generate the component instantiation template
			set exists_insttp [::instantiationtemplate::generate_insttp $entity $entity_name]
			if {$exists_insttp} {
				#DEBUG
				#puts "plantilla de instanciacion:\n\n $tp_instantiation"
				# all templates have been generated
				# write in a file
				::instantiationtemplate::write_output_template \
					$tp_component $tp_instantiation $filepath $outputdir
			} else {
				error " Error - component instantiation \
						statement template could not be \
						generated. "
			}
		} else {
			error " Error - component template could not \
					be generated. "
		}
	} else {
		error [format \ 
			" Error - the entity declaration could not be recognized
					in the file : $filepath "]
	}
	##
}

###############################################
# Next code be found in global namespace ::	  #
###############################################

# From here using vivado tcl commands
# gets selected source file from the gui
set selected_vhd [lindex [get_selected_objects] 0] 

# we need to ensure that the vhdl code is syntactically 
# correct then we launch the RTL elaboration, 
# the Tcl API doesn't provide another fast method
if {[catch {
	synth_design -rtl -rtl_skip_constraints -rtl_skip_ip
	close_design
} rtl_error]} {
	error " Error - check VHDL source files syntax: $rtl_error "
}

puts "SELECTED: $selected_vhd"
#	call to main command and gets the returned directory
set outputtp [::instantiationtemplate::get_instantiation_template \
				$selected_vhd [file dirname $selected_vhd]
]

#DEBUG
#puts "DIR DE SALIDA: $outputtp"

# clean spaces at start and end
set outputtp [string trim $outputtp]

# add template file to project fileset,
# by default configuration your current_fileset
# will be 'sources_1'
if {[regexp {\s+} $outputtp]} {
	# if the dir string has spaces we need to eval
	# the command with the dir between double {{}}
	eval add_files -norecurse "{{$outputtp}}"
} else {
	# this works only for dir strings don't contains
	# spaces
	eval add_files -norecurse "\"$outputtp\""
}

# END
