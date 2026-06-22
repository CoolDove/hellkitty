#import "Basic";
#import "gdextension";

JaiGDData :: struct {
	get_proc_address : GDExtensionInterfaceGetProcAddress;
}
data : JaiGDData;

#program_export
gdextension_init :: (p_get_proc_address: GDExtensionInterfaceGetProcAddress, library: GDExtensionClassLibraryPtr, initialization: *GDExtensionInitialization) #no_context #c_call {
	using initialization;
	initialize = _initialize;
	deinitialize = _deinitialize;
	data.get_proc_address = p_get_proc_address;
	initialization.minimum_initialization_level = .INITIALIZATION_SCENE;
}

_initialize :: (p_userdata: *void, p_level: GDExtensionInitializationLevel) #c_call {
	if p_level == .GDEXTENSION_INITIALIZATION_SCENE {
		push_context {
			print("Hello! GDExtension from Jai!\n");
			load_gdextension_interfaces(data.get_proc_address);
		}
	}
}
_deinitialize :: (p_userdata: *void, p_level: GDExtensionInitializationLevel) #c_call {
}

#import "Remap_Context";
