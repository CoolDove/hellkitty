#import "Basic";
#load "gdinterface.jai";


JaiGDData :: struct {
	proc_loader : GDExtensionInterfaceGetProcAddress;
}

data : JaiGDData;

#program_export
gdextension_init :: (p_get_proc_address: GDExtensionInterfaceGetProcAddress, library: GDExtensionClassLibraryPtr, initialization: *GDExtensionInitialization) #no_context #c_call {
	using initialization;
	initialize = _initialize;
	deinitialize = _deinitialize;
	data.proc_loader = p_get_proc_address;
	userdata = *data;
	initialization.minimum_initialization_level = .INITIALIZATION_SCENE;
}

_initialize :: (p_userdata: *void, p_level: GDExtensionInitializationLevel) #c_call {
	if p_level == .GDEXTENSION_INITIALIZATION_SCENE {
		push_context {
			print("Hello! GDExtension from Jai!\n");
			jdata :*JaiGDData= p_userdata;
			jdata.proc_loader("print");
		}
	}
}
_deinitialize :: (p_userdata: *void, p_level: GDExtensionInitializationLevel) #c_call {
}

#import "Remap_Context";
