#import "Basic";
#import "gdextension";

init :: () {
	print("Hello! GDExtension from Jai!\n");
	using data;
	load_gdextension_interfaces(get_proc_address);
	#import "Math";
}
deinit :: () {
}

JaiGDData :: struct {
	get_proc_address : GDExtensionInterfaceGetProcAddress;
	library          : GDExtensionClassLibraryPtr;
}
data : JaiGDData;

#program_export
gdextension_init :: (p_get_proc_address: GDExtensionInterfaceGetProcAddress, library: GDExtensionClassLibraryPtr, initialization: *GDExtensionInitialization) #no_context #c_call {
	{
		using initialization;
		initialize = _initialize;
		deinitialize = _deinitialize;
		minimum_initialization_level = .INITIALIZATION_SCENE;
	}
	data.get_proc_address = p_get_proc_address;
	data.library = library;
}

_initialize :: (p_userdata: *void, p_level: GDExtensionInitializationLevel) #c_call {
	if p_level == .GDEXTENSION_INITIALIZATION_SCENE {
		push_context { init(); }
	}
}
_deinitialize :: (p_userdata: *void, p_level: GDExtensionInitializationLevel) #c_call {
	if p_level == .GDEXTENSION_INITIALIZATION_SCENE {
		push_context { deinit(); }
	}
}

#import "Remap_Context";
