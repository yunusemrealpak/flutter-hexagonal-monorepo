# The bottom bar: four tabs, and the core contract that did not move

**Status:** decided on 2026-08-30. Implemented across the commits titled
`feat(design_system): a navigation bar that takes data and returns an index`,
`feat(app_courier): four tabs, and the session that forgets where it was` and
`fix(apps): an ended session forgets where it was, in the other two apps`.

**Where the rule lives:** it is
[`DEPENDENCY_RULES.md` §2.4](../DEPENDENCY_RULES.md) applied one level down and
one level up, not a new rule. Down: a component reports an index, the app
supplies the destination. Up: §2.3's *a driving surface belongs to the
audience*, applied to which destinations are one tap away.

---

## 1. What was asked, and what it was expected to force

`app_courier` had thirteen flat routes and no shell — every screen reachable by
URL only, no bar, no tabs. The handoff written at the end of the navigation
work listed five things a tabbed shell would need, and put this first:

> **`RouteDefinition` has no branch concept.** … Expressing a
> `StatefulShellRoute` means adding one, and that is a change to a *core
> contract package* every presentation package depends on.

That expectation turned out to be wrong, and finding out why is most of what
this note is for.

## 2. What a branch actually needs to be expressed

Four facts have to exist somewhere before a `StatefulShellRoute` can be built:

| Fact | Whose answer is it? |
|---|---|
| Which routes live inside which tab | the app's |
| In what order the tabs appear | the app's |
| What each tab is called and which picture it shows | the app's |
| That a tab's root can be opened with no argument | **the feature's** |

The first three are the app's for the reason §2.3 already gives: a courier's
tabs are not a dispatcher's, and `routing_presentation` is mounted by both.
`app_dispatcher` has no bar at all. A field on `RouteDefinition` saying "I am
the second tab" would be a feature declaring something only an app can know,
and two of the three apps would carry it to say nothing.

The fourth is genuinely a feature's fact — and `RouteDefinition` already
states it. A tab is opened by tapping a bar, and a tap carries no argument, so
a tab root cannot be a route with a path parameter. `path` is where that is
written: `/stops` can be a tab, `/stops/:shipmentId/proof` cannot. The check is
one line in a test:

```dart
expect(router.definitions[tab.root]?.path, isNot(contains(':')));
```

So the core contract did not move. A `bool isTabRoot` would have been a second
spelling of a fact `path` already carries, in a package every presentation
package depends on, to save one `contains(':')` in one app.

**The general lesson, worth keeping:** before adding a field to a contract
package, ask whether the fact is already derivable from a field that is there.
A contract with two ways to say the same thing has two ways to disagree.

## 3. The split, in three files

The same shape as the flows, one level down:

| | Knows | Does not know |
|---|---|---|
| `PeykNavigationBar` (`design_system`) | how a bar looks, which index was tapped | that routes exist |
| `courierTabs` (`app_courier`) | which routes are behind which word and picture | how anything is drawn |
| `CourierShell` (`app_courier`) | that index *n* means branch *n* | anything a feature owns |

A bar that navigated would have to name destinations — the candidate §2.4
rejects, and rejects for a reason that gets *stronger* here: a component is
shared by three apps, so a destination inside it would be a destination all
three have to agree on.

`PeykIcon` is `PeykIntent`'s inversion applied to iconography, and its values
are named for the picture — `list`, `map`, `inbox`, `more` — not for the
product. `PeykIcon.stops` would be a design system that has to be recompiled
when a tab is renamed.

## 4. Two behaviours that had to be decided rather than inherited

**A tap on the tab already in force is forwarded.** Material's `NavigationBar`
reports it; a component that filtered it would look tidier and would make
"tapping the tab you are on returns it to its root" impossible to build from
outside. `CourierShell` answers it with
`goBranch(index, initialLocation: index == currentIndex)`. That is the only way
out of a stack for somebody who arrived by deep link and has nothing to pop to.

**Every destination is labelled, not only the selected one.** The icons are
grey glyphs of the same size in the same place; §"colour is never the only
signal" in `design_system`'s README is the same argument, and the alternative
is a bar you have to tap to read.

## 5. What the sign-out test found, which was not about tabs at all

The handoff's fifth point said: *logout has to clear every branch's stack —
write the test first*. The test was written first, and it failed for a reason
nobody had predicted.

A courier signed out at `/stops/SHP-1/proof`, signed back in, and landed on
`/stops/SHP-1/proof`.

The branch stacks were fine: sign-in is mounted outside the shell, so the shell
leaves the tree and its per-branch navigators go with it. What survived was the
*guard's memory*. `redirectFor` attaches `?from=<attempted location>` to every
refusal so that a parcel somebody followed a link to survives signing in — and
an ended session is refused at whatever screen its owner was on. On a shared
handset that is the next courier landing on the previous one's parcel.

**Interception and ejection are indistinguishable to the guard.** Both are a
session-requiring route with no session; `redirectFor` is pure over
`SessionReader.current` and cannot see the difference, which is the property
that makes it testable and is worth keeping.

The transition is visible in exactly one place: `SessionRefresh`, which
subscribes to `SessionReader.changes()`. It was written to ignore the value it
receives — deliberately, so that the router never holds a second copy of a fact
identity owns. It now reads one bit off it: whether there is anybody. `null`
means the session ended, and the app answers by clearing the location before
the guard reads it.

That is not a second copy of the session; it is a `null` check against what the
port already promises, and the file still does not import `identity_api`.

Fixed in all three apps, because all three assemble the same guard. Two tests
each, and the first draft of the second one passed without the fix — the
harness's home is the screen the test happened to be on, so "went home" and
"stayed put" were the same answer. Going somewhere else first is what gave it
teeth.

## 6. What was ruled out

- **A branch field on `RouteDefinition`.** §2 above. Derivable from `path`,
  and two of three apps would carry it to say nothing.
- **A `PeykNavigationBar` that takes routes.** §3. It would put a destination
  in a package three apps share.
- **Tabs assembled from what features declare.** A feature saying "I am fit to
  be a tab" would still leave order, grouping and words to the app, and the
  one fact it could contribute is already in `path`.
- **Putting the flow screens above the shell rather than inside the stops
  tab.** A courier at a door who checks the map would come back to the
  manifest instead of the door. The tab owns its stack; that is what a tab is.
- **Sharing `PeykRouter` between the apps now that one of them has branches.**
  The opposite: this is the first hard evidence for the duplication that file
  has argued for since phase 7. A shared router would have grown a `branches`
  parameter that two of its three callers pass nothing to.

## 7. What is still open

- **`app_dispatcher` has no shell.** A desk wants a persistent sidebar, not a
  bottom bar, and that is a different component with the same split. Nothing
  in this change presumes either way.
- **Deep-link entry from a push payload** remains the next item: `RouteLocation`
  and the URL contract are in place, and nothing turns a notification payload
  into a location yet.
- **A tab badge.** `PeykBadge` exists and the inbox tab is the obvious
  consumer. It is deliberately not in this change: an unread count is a
  subscription, and where that subscription lives is its own decision.
