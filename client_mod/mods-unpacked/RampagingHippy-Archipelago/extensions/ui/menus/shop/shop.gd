## Extension for the single-player Shop
##
## THIS FILE IS INTENTIONALLY EMPTY, DO NOT REMOVE.
## For whatever reason, if we don't define this extension, then various Parser Errors
## appear in base_shop.gd, that look like (copying to make it easier to search for this)
## "Parser Error: The function signature doesn't match the parent. Parent signature is: <the correct signature>"
## There's probably some weirdness going on with how ModLoader extends the base game
## objects where it can't figure out that an extended instance of a class is valid as
## the base class (or perhaps Godot doesn't follow Liskov?). Defining this class lets
## the extensions work as normal, which is weird but not much we can do about it.
##
## See the comment in the base_shop extension for further details.
extends "res://ui/menus/shop/shop.gd"
