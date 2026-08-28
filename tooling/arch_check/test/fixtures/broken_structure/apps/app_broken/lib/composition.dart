// Two violations in one package, and they are the pair the app row has to keep
// telling apart.
//
// There is no file matching the entry-point pattern, so S1 fires: an app with
// no entry point is an app nothing can run.
//
// And this file sits directly under lib/ without being one, so S2 fires for
// exactly the reason it fires in a library package — the layout says "public
// surface" and the contents are an implementation detail.
void compose() {}
