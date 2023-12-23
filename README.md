# libnimib

This builds ontop of nimib allowing any language to use it.

Presently this is just a proof of concept to make it callable from other
languges. The API aims to be simple to make it easy to use from any language,
this is the reason errors are a simple `cstring`(though ideally they would all
be constants to not force a `nimib_free_string` call).
