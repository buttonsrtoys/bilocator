## Add inherited models to RegistrarDelegate

Currently only supports single services.

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

## Observer.register could be made lazy

Observer.register instantiates the inherited model when registering it. This could be refactored to 
use _LazyInitializer and retain the build function. (This is a rarely used function and a bit of an edge case, so not a high priority.)

While working on this, add error check when Observer.unregister is called, check that the
_LazyInitializer is the same. I.e., that it wasn't another Observer that registered the model.
