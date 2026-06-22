
#run,stallable {
	print("Jai Build Started\n");
	defer print("Jai Build Ended\n");
	set_build_options_dc(.{do_output=false});

	{
		w := compiler_create_workspace();
		options := get_build_options(w);
		copy_commonly_propagated_fields(get_build_options(), *options);
		options.output_executable_name = "jaigd.windows.debug.x86_64";
		options.output_type            = .DYNAMIC_LIBRARY;
		options.stack_trace            = true;
		set_optimization(*options, .OPTIMIZED);
		set_build_options(options, w);

		extra_string_interface := generate_extension_interface_bindings();
		// generate_api_bindings();

		add_build_file("library.jai", w);

		for extra_string_interface {
			add_build_string(it, w);
		}
	}
}

generate_extension_interface_bindings :: () -> []string {
	#import "Bindings_Generator";
	#import "File";

	make_directory_if_it_does_not_exist("gen");
	output_filename := "gen/gdextension.jai";

	build_strings : [..]string;
	array_reserve(*build_strings, 128);

	sb_api_loader : String_Builder;
	init_string_builder(*sb_api_loader);
	defer reset(*sb_api_loader);

	VisitorData :: struct {
		output        : *[..]string;
		sb_api_loader : *String_Builder;
		rgx_name      : Regexp;
	}
	visitor_data := VisitorData.{
		output        = *build_strings,
		sb_api_loader = *sb_api_loader,
		rgx_name      = compile("@name (\\w+)"),
	};
	defer uninit(*visitor_data.rgx_name);

	visitor :: (decl: *Declaration, parent_decl: *Declaration, user_data: *void) -> Declaration_Visit_Result {
		using cast(*VisitorData)user_data;
		if ok(match(decl.comment.text, rgx_name), "captures") {
			defer array_free(captures);
			raw_name, name, type := captures[1], tprint("gd_%", captures[1]), decl.name;
			array_add(output, tprint("% : %;", name, type));
			print_to_builder(sb_api_loader, "\t% = cast(%)get_proc_address(\"%\");\n", name, type, raw_name);
		}
		return .RECURSE;
	}
	opts := Generate_Bindings_Options.{
		visitor_data = *visitor_data,
		visitor_with_data = visitor,
	};
	array_add(*opts.source_files, "gdextension_interface.h");

	print_to_builder(*sb_api_loader, "load_gdextension_interfaces :: (get_proc_address: GDExtensionInterfaceGetProcAddress) {\n");

	generate_bindings(opts, output_filename);

	// After the visiting is done.
	print_to_builder(*sb_api_loader, "\n}");
	array_add(*build_strings, builder_to_string(*sb_api_loader));

	target_file := file_open(output_filename);
	generated_content := read_entire_file(target_file,, context.allocator);

	file_close(*target_file);

	String :: #import "String";
	patch_string :: #string DONE
GDExtensionClassConstructor :: #type () -> GDExtensionObjectPtr #c_call;
GDExtensionInterfaceGetProcAddress :: #type (p_function_name: *u8) -> *void #c_call;
GDExtensionInitializationFunction :: #type (p_get_proc_address: GDExtensionInterfaceGetProcAddress, p_library: GDExtensionClassLibraryPtr, r_initialization: *GDExtensionInitialization) -> GDExtensionBool #c_call;

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

	return build_strings;
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
				if ok(table_find(v, "name"), "jv")
					print("- %\n", jv.str);
			}
		}
	}
}

#import "ok";
#import "uniform";

#import "Basic";
#import "Hash_Table";
#import "Compiler";
