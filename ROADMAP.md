## Add tests for context.of method

## Add Location.tree support to BilocatorDelegate

Currently only supports Location.registry (which is the most common use for using Bilocators, but still...)

## Better exception messages when locate fails

When a locate for an inherited model or registered service fails, it would be good to check the
other possible locations and report the results to the developer. E.g.,

    'listenTo<MyModel>(context: context)' did not find an inherited model in the widget tree. 
    However, one was found in the registry. Did you mean to call 'listenTo<MyModel>()' (without
    "context")?

When a registry lookup fails, it would be handy to dump the closest matches. E.g., With same type 
and with different type but same name.

## Revisit the 'instance' parameter name?

Maybe confused with other uses of "instance", like GetIt.instance. Maybe "object" or "data"?

Maybe OK in the context of the "builder" parameter.
