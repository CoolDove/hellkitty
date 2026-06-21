#load "gen/gdextension.jai";

// Translated by hand
GDExtensionClassConstructor :: #type () -> GDExtensionObjectPtr #c_call;
GDExtensionInterfaceGetProcAddress :: #type (p_function_name: *u8) -> *void #c_call;
GDExtensionInitializationFunction :: #type (p_get_proc_address: GDExtensionInterfaceGetProcAddress, p_library: GDExtensionClassLibraryPtr, r_initialization: *GDExtensionInitialization) -> GDExtensionBool #c_call;
