ok :: (code: Code, $values: .. string, $loc:=#location()) -> bool #expand {
	#insert -> string {
		push_allocator(temp);
		sb : String_Builder;
		print_to_builder(*sb, "okvalue");
		for values {
			print_to_builder(*sb, ", `%", it);
		}
		print_to_builder(*sb, " := #insert code;");
		return builder_to_string(*sb);
	};
	return okvalue;
}

okv :: (code: Code, $type: Type) -> Maybe(type) #expand {
	okvalue, result_value := #insert code;
	if okvalue  return .{ .VALUE, result_value };
	else  return .{ .POINTER, null };
}

Maybe :: union(ValueType:Type) kind: enum u8 { POINTER; VALUE; } {
	.POINTER,, pointer : *void;
	.VALUE,, value : ValueType;
}

operator == :: (maybe: Maybe($T), ptr: *T) -> bool #symmetric {
	if ptr != null  return false;

	if maybe.kind == .VALUE  return false;
	else  return true;
}

#scope_file
#if false {

example :: () {
	#import "Hash_Table";
	dtable : Table(string, string);
	defer deinit(*dtable);
	table_add(*dtable, "apple", "Nice but normal.");
	table_add(*dtable, "banana", "Good.");
	table_add(*dtable, "watermelon", "Perfect!");
	if ok(table_find(*dtable, "apple"), "comment") {
		print("Yes, we have an apple! (with comment: %) \n", comment);
	} else {
		print("No, we didn't find the apple...\n");
	}
}

}


#import "Basic";
#import "String";
