/// The routing adapters: what answers its ports, the DTOs that cross the
/// wire, and the mappers between them.
///
/// Everything this package publishes is exported here and nowhere else.
/// Another package importing `package:routing_infrastructure/src/...` is
/// reaching across a boundary, and arch_check reports it as one.
library;

// Nothing yet: this package's contents arrive in the commit that gives it
// something to hold. A barrel with no export is a package with no public
// surface, which is exactly what this one has until then.
