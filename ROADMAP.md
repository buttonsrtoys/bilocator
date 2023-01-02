## Add more tests

## Add Location.tree support to BilocatorDelegate

Currently only supports Location.registry (which is the most common use for using Bilocators, but still...)

## Add check for registry when widget tree lookup fails.

When a locate for an inherited model or registered service fails, it would be good to check the
other possible locations and report the results to the developer. E.g.,

    'listenTo<MyModel>(context: context)' did not find an inherited model in the widget tree. 
    However, one was found in the registry. Did you mean to call 'listenTo<MyModel>()' (without
    "context")?

When a registry lookup fails, it would be handy to dump the closest matches. E.g., With same type 
and with different type but same name.

"Bilocator tried to get an instance of type $T with name $name but it is not registered". Can be 
triggered when Bilocator.initState has not yet been called.

## Revisit the 'instance' parameter name?

Maybe confused with other uses of "instance", like GetIt.instance. Maybe "object" or "data"?

Maybe OK in the context of the "builder" parameter.

## Review Bilocator class for registering in constructor rather than initState

## Consider renaming Bilocators to MultiBilocator to be consistent with Provider and Flutter