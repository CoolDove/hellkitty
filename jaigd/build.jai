#import "Basic";
#import "Compiler";

#run,stallable {
	print("Jai Build Started\n");
	defer print("Jai Build Ended\n");
	set_build_options_dc(.{do_output=false});

	generate_extension_interface_bindings();
	generate_api_bindings();

	{
		w := compiler_create_workspace();
		options := get_build_options(w);
		copy_commonly_propagated_fields(get_build_options(), *options);
		options.output_executable_name = "jaigd.windows.debug.x86_64";
		options.output_type            = .DYNAMIC_LIBRARY;
		options.stack_trace            = true;
		set_optimization(*options, .OPTIMIZED);
		set_build_options(options, w);

		add_build_file("library.jai", w);
	}
}

generate_extension_interface_bindings :: () {
	#import "Bindings_Generator";
	#import "File";

	make_directory_if_it_does_not_exist("gen");
	output_filename := "gen/gdextension.jai";

	opts : Generate_Bindings_Options;
	opts.log_unsupported = true;

	array_add(*opts.source_files, "gdextension_interface.h");

	generate_bindings(opts, output_filename);

	target_file := file_open(output_filename);
	generated_content := read_entire_file(target_file,, context.allocator);

	file_close(*target_file);

	String :: #import "String";
	patch_string :: #string DONE
/* Called when starting the main loop. */
GDExtensionMainLoopStartupCallback :: #type *void;
/* Called when shutting down the main loop. */
GDExtensionMainLoopShutdownCallback :: #type *void;
/* Called for every frame iteration of the main loop. */
GDExtensionMainLoopFrameCallback :: #type *void;
GDExtensionMainLoopCallbacks :: struct {
	/* Will be called after Godot is started and is fully initialized. */
	startup_func : GDExtensionMainLoopStartupCallback;
	/* Will be called before Godot is shutdown when it is still fully initialized. */
	shutdown_func : GDExtensionMainLoopShutdownCallback;
	/* Will be called for each process frame. This will run after all `_process()` methods on Node, and before `ScriptServer::frame()`.
	 * This is intended to be the equivalent of `ScriptLanguage::frame()` for GDExtension language bindings that don't use the script API.
	 */
	frame_func : GDExtensionMainLoopFrameCallback;
}
DONE

	new_content := String.replace(generated_content, "GDExtensionMainLoopCallbacks :: struct {}", patch_string);
	write_entire_file(output_filename, new_content);

}

generate_api_bindings :: () {
	Jaison :: #import "jaison";
	{
		push_allocator(temp);
		print("json parsing...\n");
		if !ok(Jaison.json_parse_file("./extension_api.json"), "data") {
			print("failed to parse json\n");
			return;
		}
		print("json parse done!\n");
		if ok(table_find(data.object, "utility_functions"), "functions") {
			print("parsed utility functions:\n");
			for functions.array {
				v := it.object;
				// jv := cast(*Jaison.JSON_Value)(okv(table_find(v, "name")).value_pointer);
				jv := okv(table_find(v, "name"));
				if jv != null {
					print("- %\n", jv.str);
				}
			}
		}
	}
}

#import "OK";
#import "Basic";
#import "Hash_Table";
