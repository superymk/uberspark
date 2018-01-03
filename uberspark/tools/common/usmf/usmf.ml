(*
	uberspark manifest parsing module
	author: amit vasudevan (amitvasudevan@acm.org)
*)

open Uslog
open Sys
open Yojson
open Str

(*
	**************************************************************************
	global variables
	**************************************************************************
*)

let usmf_fnametoverifopts = ((Hashtbl.create 32) : ((string,string)  Hashtbl.t));;
let g_cfiles_list = ref [""];;


(*
	**************************************************************************
	debug helpers
	**************************************************************************
*)

let dbg_dump_hashtbl key value = 
	Uslog.logf "test" Uslog.Info "key=%s, value=%s" key value;
	;;

let do_action_on_cfile cfilename =
  Uslog.logf "test" Uslog.Info "c-file name: %s" cfilename;
			;;

let do_action_on_vharness_file filename =
  Uslog.logf "test" Uslog.Info "v-harness(file): %s" filename;
			;;

let do_action_on_vharness_options optionstring =
  Uslog.logf "test" Uslog.Info "v-harness(options): %s" optionstring;
			;;
	
			
(*
	**************************************************************************
	interfaces
	**************************************************************************
*)

let rec myMap ~f l = match l with
 | [] -> []
 | h::t -> (f h) :: (myMap ~f t);;

 
let parse_manifest filename = 
	Uslog.logf "test" Uslog.Info "Manifest file: %s" filename;

try
	
  (* read the manifest JSON *)
  let json = Yojson.Basic.from_file filename in

	  (* Locally open the JSON manipulation functions *)
	  let open Yojson.Basic.Util in
	  	let ns = json |> member "ns" |> to_string in
	  	let cfiles = json |> member "c-files" |> to_string in
  		let vharness = json |> member "v-harness" |> to_list in
  		let vfiles = myMap vharness ~f:(fun json -> member "file" json |> to_string) in 
  		let voptions = myMap vharness ~f:(fun json -> member "options" json |> to_string) in

				(* Print the results of the parsing *)
			  Uslog.logf "test" Uslog.Info "Namespace (ns): %s" ns;
			  Uslog.logf "test" Uslog.Info "c-files: %s" cfiles;

				g_cfiles_list := (Str.split (Str.regexp "[ \r\n\t]+") cfiles);
				List.iter do_action_on_cfile !g_cfiles_list;

				let numelems_vfiles = List.length vfiles in
				let numelems_voptions = List.length voptions in
				let elemcnt = ref 0 in 
					if numelems_vfiles = numelems_voptions then
						begin
							elemcnt := 0;
							while (!elemcnt < numelems_vfiles) do
								let vfile_name = List.nth vfiles !elemcnt in
								let voptions_str = List.nth voptions !elemcnt in
									(*
									Uslog.logf "test" Uslog.Info "vfile=%s voptions=%s" vfile_name voptions_str;
					       	*)
									 Hashtbl.add usmf_fnametoverifopts vfile_name voptions_str;
									elemcnt := !elemcnt + 1;
							done;
							
							(*debug dump*)
							Hashtbl.iter dbg_dump_hashtbl usmf_fnametoverifopts;
							
							Uslog.logf "test" Uslog.Info "Parsed Manifest!";
						end
					else
						begin
							Uslog.logf "test" Uslog.Info "ERROR in parsing manifest: numelems_vfiles != numelems_voptions";
						end
					;

				(*List.iter do_action_on_vharness_file vfiles;
				List.iter do_action_on_vharness_options voptions;
				*)
			

with Yojson.Json_error s -> 
				Uslog.logf "test" Uslog.Info "ERROR in parsing manifest!";

	;
		
	;;


