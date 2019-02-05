(*------------------------------------------------------------------------------
	uberSpark uberobject verification and build interface
	author: amit vasudevan (amitvasudevan@acm.org)
------------------------------------------------------------------------------*)

open Usconfig
open Uslog
open Usmanifest
open Usextbinutils
open Usuobjgen

module Usuobj =
struct

class uobject = object(self)
		val log_tag = "Usuobj";
		
		val usmf_type_usuobj = "uobj";

		val o_usmf_hdr_type = ref "";
		method get_o_usmf_hdr_type = !o_usmf_hdr_type;
		val o_usmf_hdr_subtype = ref "";
		method get_o_usmf_hdr_subtype = !o_usmf_hdr_subtype;
		val o_usmf_hdr_id = ref "";
		method get_o_usmf_hdr_id = !o_usmf_hdr_id;
		val o_usmf_sources_c_files: string list ref = ref [];
		method get_o_usmf_sources_c_files = !o_usmf_sources_c_files;
		val o_usmf_sources_casm_files: string list ref = ref [];
		method get_o_usmf_sources_casm_files = !o_usmf_sources_casm_files;
		val o_uobj_sections_list : string list list ref = ref [];
		method get_o_uobj_sections_list = !o_uobj_sections_list;
		val o_usmf_filename = ref "";
		method get_o_usmf_filename = !o_usmf_filename;
		val o_uobj_dir_abspathname = ref "";
		method get_o_uobj_dir_abspathname = !o_uobj_dir_abspathname;
		
		
		(* val mutable slab_idtoname = ((Hashtbl.create 32) : ((int,string)  Hashtbl.t)); *)


		(*--------------------------------------------------------------------------*)
		(* parse uobj manifest *)
		(* usmf_filename = canonical uobj manifest filename *)
		(* keep_temp_files = true if temporary files need to be preserved *)
		(*--------------------------------------------------------------------------*)
		method parse_manifest usmf_filename keep_temp_files =
			
			(* store filename and uobj dir absolute pathname *)
			o_usmf_filename := Filename.basename usmf_filename;
			o_uobj_dir_abspathname := Filename.dirname usmf_filename;
			

			(* read manifest JSON *)
			let (rval, mf_json) = Usmanifest.read_manifest 
																usmf_filename keep_temp_files in
			
			if (rval == false) then (false)
			else
			(* parse usmf-hdr node *)
			let (rval, usmf_hdr_type, usmf_hdr_subtype, usmf_hdr_id) =
								Usmanifest.parse_node_usmf_hdr mf_json in

			if (rval == false) then (false)
			else
			
			(* sanity check type to be uobj *)
			if (compare usmf_hdr_type usmf_type_usuobj) <> 0 then (false)
			else
			let dummy = 0 in
				begin
					o_usmf_hdr_type := usmf_hdr_type;								
					o_usmf_hdr_subtype := usmf_hdr_subtype;
					o_usmf_hdr_id := usmf_hdr_id;
				end;

			(* parse usmf-sources node *)
			let(rval, usmf_source_c_files, usmf_sources_casm_files) = 
				Usmanifest.parse_node_usmf_sources	mf_json in
	
			if (rval == false) then (false)
			else
			let dummy = 0 in
				begin
					o_usmf_sources_c_files := usmf_source_c_files;
					o_usmf_sources_casm_files := usmf_sources_casm_files;
				end;

			(* parse uobj-binary node *)
			let (rval, uobj_sections_list) = 
										Usmanifest.parse_node_uobj_binary mf_json in

			if (rval == false) then (false)
			else
			let dummy = 0 in
				begin
					o_uobj_sections_list := uobj_sections_list;
				end;
																											
			(true)
		;


		(*--------------------------------------------------------------------------*)
		(* compile a uobj cfile *)
		(* cfile_list = list of cfiles *)
		(* cc_includedirs_list = list of include directories *)
		(* cc_defines_list = list of definitions *)
		(*--------------------------------------------------------------------------*)
		method compile_cfile_list cfile_list cc_includedirs_list cc_defines_list =
			List.iter (fun x ->  
									Uslog.logf log_tag Uslog.Info "Compiling: %s" x;
									let (pestatus, pesignal, cc_outputfilename) = 
										(Usextbinutils.compile_cfile x (x ^ ".o") cc_includedirs_list cc_defines_list) in
											begin
												if (pesignal == true) || (pestatus != 0) then
													begin
															(* Uslog.logf log_mpf Uslog.Info "output lines:%u" (List.length poutput); *)
															(* List.iter (fun y -> Uslog.logf log_mpf Uslog.Info "%s" !y) poutput; *) 
															(* Uslog.logf log_mpf Uslog.Info "%s" !(List.nth poutput 0); *)
															Uslog.logf log_tag Uslog.Error "in compiling %s!" x;
															ignore(exit 1);
													end
												else
													begin
															Uslog.logf log_tag Uslog.Info "Compiled %s successfully" x;
													end
											end
								) cfile_list;
			()
		;


		(*--------------------------------------------------------------------------*)
		(* build a uobj *)
		(* build_dir = directory to use for building *)
		(* keep_temp_files = true if temporary files need to be preserved in build_dir *)
		(*--------------------------------------------------------------------------*)
		method build build_dir keep_temp_files = 
	
			Uslog.logf log_tag Uslog.Info "Starting build in '%s' [%b]\n" build_dir keep_temp_files;
			
			Uslog.logf log_tag Uslog.Info "cfiles_count=%u, casmfiles_count=%u\n"
						(List.length !o_usmf_sources_c_files) 
						(List.length !o_usmf_sources_casm_files);
	
			(* generate uobj linker script *)
			(* use usmf_hdr_id as the uobj_name *)
			let uobj_linker_script_filename =	
				Usuobjgen.generate_uobj_linker_script !o_usmf_hdr_id 0x60000000 
					!o_uobj_sections_list in
				Uslog.logf log_tag Uslog.Info "uobj_lscript=%s\n" uobj_linker_script_filename;
					
			(* generate uobj header *)
			(* use usmf_hdr_id as the uobj_name *)
			let uobj_hdr_filename = 
				Usuobjgen.generate_uobj_hdr !o_usmf_hdr_id 0x60000000 
					!o_uobj_sections_list in
				Uslog.logf log_tag Uslog.Info "uobj_hdr_filename=%s\n" uobj_hdr_filename;
			
			(* compile all the cfiles *)							
			self#compile_cfile_list (!o_usmf_sources_c_files @ [ uobj_hdr_filename ]) 
					(Usconfig.get_std_incdirs ())
					(Usconfig.get_std_defines ());
		
			(* link the uobj binary *)
			Uslog.logf log_tag Uslog.Info "Proceeding to link uobj binary '%s'..."
					!o_usmf_hdr_id;
				let uobj_libdirs_list = ref [] in
				let uobj_libs_list = ref [] in
				let (pestatus, pesignal) = 
						(Usextbinutils.link_uobj  
							(!o_usmf_sources_c_files @ [ uobj_hdr_filename ])
							!uobj_libdirs_list !uobj_libs_list
							uobj_linker_script_filename (!o_usmf_hdr_id ^ ".bin")
						) in
						if (pesignal == true) || (pestatus != 0) then
							begin
									Uslog.logf log_tag Uslog.Error "in linking uobj binary '%s'!" !o_usmf_hdr_id;
									ignore(exit 1);
							end
						else
							begin
									Uslog.logf log_tag Uslog.Info "Linked uobj binary '%s' successfully" !o_usmf_hdr_id;
							end
						;
																																																																																																																							
																																																																																																																																																																																																			
			Uslog.logf log_tag Uslog.Info "Done.\r\n";
			()
		;


	(*--------------------------------------------------------------------------*)
	(* generate uobj info table *)
	(*--------------------------------------------------------------------------*)
	method generate_uobj_info ochannel = 
		let i = ref 0 in 
		
		Printf.fprintf ochannel "\n";
    Printf.fprintf ochannel "\n	//%s" (!o_usmf_hdr_id);
    Printf.fprintf ochannel "\n	{";

  	Printf.fprintf ochannel "\n\t0x00000000UL, ";    (*entrystub*)
								
    Printf.fprintf ochannel "\n	}";
		Printf.fprintf ochannel "\n";

		()
	;

	(*--------------------------------------------------------------------------*)
	(* generate uobj header *)
	(*--------------------------------------------------------------------------*)
	method generate_uobj_hdr 
			(uobj_name : string) 
			(uobj_load_addr : int)
			(uobj_sections_list : string list list)
			: string  =
		let uobj_hdr_filename = (uobj_name ^ ".hdr.c") in
		let oc = open_out uobj_hdr_filename in
			Printf.fprintf oc "\n/* autogenerated uberSpark uobj header */";
			Printf.fprintf oc "\n/* author: amit vasudevan (amitvasudevan@acm.org) */";
			Printf.fprintf oc "\n";
			Printf.fprintf oc "\n";
	
			Printf.fprintf oc "\n#include <uberspark.h>";
			Printf.fprintf oc "\n";
	
			Printf.fprintf oc "\n__attribute__((section (\".ustack\"))) uint8_t __ustack[MAX_PLATFORM_CPUS * USCONFIG_SIZEOF_UOBJ_USTACK]={ 0 };";
			Printf.fprintf oc "\n__attribute__((section (\".tstack\"))) uint8_t __tstack[MAX_PLATFORM_CPUS * USCONFIG_SIZEOF_UOBJ_TSTACK]={ 0 };";
	
			List.iter (fun x ->
				(* new section *)
				let section_name_var = ("__uobjsection_filler_" ^ (List.nth x 0)) in
				let section_name = (List.nth x 3) in
				  if ((compare section_name ".text") <> 0) && 
						((compare section_name ".ustack") <> 0) &&
						((compare section_name ".tstack") <> 0) then
						begin
							Printf.fprintf oc "\n__attribute__((section (\"%s\"))) uint8_t %s[1]={ 0 };"
								section_name section_name_var;
						end
					;
				()
			)  uobj_sections_list;
	
			Printf.fprintf oc "\n";
			Printf.fprintf oc "\n";
				
			close_out oc;
		(uobj_hdr_filename)
	; 

	(*--------------------------------------------------------------------------*)
	(* generate uobj linker script *)
	(*--------------------------------------------------------------------------*)
	method generate_uobj_linker_script 
		(uobj_name : string) 
		(uobj_load_addr : int) 
		(uobj_sections_list : string list list)
		: string  = 
		
		let uobj_linker_script_filename = (uobj_name ^ ".lscript") in
		let uobj_section_load_addr = ref 0 in
		let oc = open_out uobj_linker_script_filename in
			Printf.fprintf oc "\n/* autogenerated uberSpark uobj linker script */";
			Printf.fprintf oc "\n/* author: amit vasudevan (amitvasudevan@acm.org) */";
			Printf.fprintf oc "\n";
			Printf.fprintf oc "\n";
			Printf.fprintf oc "\nOUTPUT_ARCH(\"i386\")";
			Printf.fprintf oc "\n";
			Printf.fprintf oc "\nMEMORY";
			Printf.fprintf oc "\n{";
	
			uobj_section_load_addr := uobj_load_addr;
			
			List.iter (fun x ->
				(* new section *)
				let memregion_name = ("uobjmem_" ^ (List.nth x 0)) in
				let memregion_attrs = ( (List.nth x 1) ^ "ail") in
				let memregion_origin = !uobj_section_load_addr in
				let memregion_size =  int_of_string (List.nth x 2) in
					Printf.fprintf oc "\n %s (%s) : ORIGIN = 0x%08x, LENGTH = 0x%08x"
						memregion_name memregion_attrs memregion_origin memregion_size;
				uobj_section_load_addr := !uobj_section_load_addr + memregion_size;
				()
			)  uobj_sections_list;
					
			Printf.fprintf oc "\n}";
			Printf.fprintf oc "\n";
			
			
			Printf.fprintf oc "\nSECTIONS";
			Printf.fprintf oc "\n{";
			Printf.fprintf oc "\n";
	
			uobj_section_load_addr := uobj_load_addr;
			
			List.iter (fun x ->
				(* new section *)
				Printf.fprintf oc "\n	. = 0x%08x;" !uobj_section_load_addr;
		    Printf.fprintf oc "\n %s : {" (List.nth x 0);
				let section_size= (List.nth x 2) in
				let elem_index = ref 0 in
				elem_index := 0;
				List.iter (fun y ->
					if (!elem_index > 2) then
						begin
					    Printf.fprintf oc "\n *(%s)" y;
						end
					; 
					elem_index := !elem_index + 1;
					()
				) x;
		
				Printf.fprintf oc "\n . = %s;" section_size; 
		    Printf.fprintf oc "\n	} >uobjmem_%s =0x9090" (List.nth x 0);
		    Printf.fprintf oc "\n";
				uobj_section_load_addr := !uobj_section_load_addr + 
						int_of_string(section_size);
				()
			) uobj_sections_list;
	
	
			Printf.fprintf oc "\n";
			Printf.fprintf oc "\n	/* this is to cause the link to fail if there is";
			Printf.fprintf oc "\n	* anything we didn't explicitly place.";
			Printf.fprintf oc "\n	* when this does cause link to fail, temporarily comment";
			Printf.fprintf oc "\n	* this part out to see what sections end up in the output";
			Printf.fprintf oc "\n	* which are not handled above, and handle them.";
			Printf.fprintf oc "\n	*/";
			Printf.fprintf oc "\n	/DISCARD/ : {";
			Printf.fprintf oc "\n	*(*)";
			Printf.fprintf oc "\n	}";
			Printf.fprintf oc "\n}";
			Printf.fprintf oc "\n";
																																																																																																																									
			close_out oc;
			(uobj_linker_script_filename)
	;
		

end ;;

end


(*---------------------------------------------------------------------------*)
(* potpourri *)
(*---------------------------------------------------------------------------*)
(*		
						(*slab_tos*)
    Printf.fprintf oc "\n\t{";
		i := 0;
		while (!i < Usconfig.get_std_max_platform_cpus) do
		    (* Printf.fprintf oc "\n\t\t   %s + (1*XMHF_SLAB_STACKSIZE)," (Hashtbl.find slab_idtostack_addrstart !i);*)
		    Printf.fprintf oc "\n\t\t0x00000000UL,";
				i := !i + 1;
		done;
    Printf.fprintf oc "\n\t},";

		Printf.fprintf oc "\n\t0x00000000UL, ";    (*slab_callcaps*)
    Printf.fprintf oc "\n\ttrue,";             (*slab_uapisupported*)
		
		(*slab_uapicaps*)
    Printf.fprintf oc "\n\t{";
		i := 0;
		while (!i < total_uobjs) do
		    Printf.fprintf oc "\n\t\t0x00000000UL,";
				i := !i + 1;
		done;
    Printf.fprintf oc "\n\t},";

		Printf.fprintf oc "\n\t0x00000000UL, ";    (*slab_memgrantreadcaps*)
		Printf.fprintf oc "\n\t0x00000000UL, ";    (*slab_memgrantwritecaps*)

		(*incl_devices*)
    Printf.fprintf oc "\n\t{";
		i := 0;
		while (!i < get_std_max_incldevlist_entries) do
		    Printf.fprintf oc "\n\t\t{0x00000000UL,0x00000000UL},";
				i := !i + 1;
		done;
    Printf.fprintf oc "\n\t},";

		Printf.fprintf oc "\n\t0x00000000UL, ";    (*incl_devices_count*)

		(*excl_devices*)
    Printf.fprintf oc "\n\t{";
		i := 0;
		while (!i < get_std_max_excldevlist_entries) do
		    Printf.fprintf oc "\n\t\t{0x00000000UL,0x00000000UL},";
				i := !i + 1;
		done;
    Printf.fprintf oc "\n\t},";
		
		Printf.fprintf oc "\n\t0x00000000UL, ";    (*excl_devices_count*)

		(*excl_devices*)
    Printf.fprintf oc "\n\t{";
		i := 0;
		while (!i < get_std_max_excldevlist_entries) do
		    Printf.fprintf oc "\n\t\t{0x00000000UL,0x00000000UL},";
				i := !i + 1;
		done;
    Printf.fprintf oc "\n\t},";
*)

