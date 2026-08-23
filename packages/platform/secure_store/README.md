# secure_store

The keychain-backed adapter for the `SecureStore` port, and the translation from a platform channel's exceptions into its sealed failure type.

## What it is for

| Type | Role |
|---|---|
| `KeychainSecureStore` | implements `core_ports.SecureStore` over the plugin's platform interface |
| `secureStoreFailureFrom` | `PlatformException` → `sealed SecureStoreFailure` |

Refresh tokens and device-binding secrets, and nothing else. This is not a safer `KeyValueStore`: platform-backed secure storage is slower, smaller, and can refuse to answer while the device is locked. A user preference put here buys nothing and costs a possible authentication prompt.

## What it may depend on

`core_kernel`, `core_ports`, the Flutter SDK, `flutter_secure_storage` and `flutter_secure_storage_platform_interface`.

The adapter is written against the **platform interface**, so the platform arrives as a constructor argument and a test can substitute an implementation instead of a method channel. The plugin itself is still a dependency: it registers the Darwin, Android and Windows implementations, and its option classes are what a composition root uses to build the `options` map.

## What must never live here

- **A default for `options`.** Accessibility class and backup behaviour are security decisions that belong to the application. A default here would be exactly the kind nobody revisits.
- **A second, in-memory implementation.** `core_testing` already ships `InMemorySecureStore`. A copy here would be a second thing to keep in step with the port.
- **A key name.** What is stored under which key is the business of the feature that owns the credential.
- **Anything that throws out of a public method.** Invariant 1.2.9.

## The uncomfortable part, stated plainly

`secure_store_failure_mapping.dart` recognises failures by matching substrings of `PlatformException.code`, `.message` and `.details`. There is no enumeration to switch on: those strings are composed by each plugin's native side, and they differ per platform. A plugin upgrade can reword one and silently move a failure into the catch-all.

This is the platform's shape, not a shortcut, and the file says so in its own comments. Two things keep it bounded:

- **The catch-all is the retryable case.** An unrecognised message becomes `SecureStoreUnavailable`, so a reworded string degrades the diagnosis instead of inverting it into "your credential is gone".
- **Every signal is a named constant in one file**, with a test that asserts each one. When a message changes there is one place to correct and one test to update.

The three cases exist because a caller behaves differently about each: `SecureStoreUnavailable` is worth retrying, `SecureStoreAuthenticationFailed` is worth asking the user about, and `SecureStoreKeyInvalidated` means the credential is gone and the only way forward is to sign in again. Collapsing the last two produces an app that offers "try again" for a secret that no longer exists.
