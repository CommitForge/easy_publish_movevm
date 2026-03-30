# easy_publish README (Based On Tag `v1`)

This README is intentionally based on **tag `v1`** source:

- Tag: `v1`
- Source file: `source/generic.move`
- Module: `sendit_messenger::generic_store`
- `MODULE_VERSION`: `1`

## Version Scope

- Main documentation below describes **v1 behavior**.
- A short **v2** delta is provided near the end.
- **v1 is currently the main version to use**.

## Current Deployment Addresses

- Smart Contract: `0xb0927f142487c66708ec3cf978dbe45da94ccede7944de7a13889efa01f7dc67` (Explorer)
- Container Chain: `0xc225e0fc9f648d95e90e8b0bbb0aecf4122c90f7c8e9f137b64603685a796266` (Explorer)
- Update Chain: `0x6c5215f9827413e25fad5f746e01c50e523caf704d65d4c7db35ddd38a8de30b` (Explorer)
- Data Item Chain: `0x21e241879bc5dad7046d742e06f60ccd8e2b66b5609a48d8d25714e4253166f2` (Explorer)
- Data Item Verification Chain: `0x1cfbe6f207b6f3851ac37d879a47f6a3262514d4b809c5f15cc971c62e2929b9` (Explorer)

## What The v1 Module Stores

### Global chain objects (created in `init`)

- `ContainerChain`: latest global container id/index
- `UpdateChain`: latest global update-record id/index
- `DataItemChain`: latest global data-item id/index
- `DataItemVerificationChain`: latest global verification id/index
- `ChainInit`: shared object with module version and chain IDs
- `ChainInitEvent`: emitted on initialization

### Core objects

- `Container`
  - parent linkage (`container_parent_id`)
  - owner list (`owners`) and active owner counter (`owners_active_count`)
  - metadata (`external_id`, `name`, `description`, `content`)
  - `Specification` (`version`, `schemas`, `apis`, `resources`)
  - permissions (`ContainerPermission`)
  - event toggles (`ContainerEventConfig`)
  - per-container counters and linked-list pointers
- `DataType`
- `DataItem`
  - optional recipients and references
  - verification state fields (`verified`, success/failure vectors)
- `DataItemVerification`
- `ContainerChildLink`
- `Owner` (`removed` is soft-delete)

### Update and audit objects

- `UpdateChainRecord` (global feed, `action`: `1=create`, `2=update`)
- `UpdateContainerRecord` (per-container feed)
- Snapshot audit objects:
  - `ContainerAudit`
  - `DataTypeAudit`
  - `ContainerChildLinkAudit`
  - `OwnerAudit`

## Permissions Model

Authorization helper: `assert_owner(container, asserted, ctx)`

- If `asserted == true`: operation is effectively public.
- If `asserted == false`: caller must be an active owner.

Permission flags on container:

- `public_update_container`
- `public_attach_container_child`
- `public_create_data_type`
- `public_publish_data_item`

## Event Model

Container-level event toggles:

- `event_create`
- `event_publish`
- `event_attach`
- `event_add`
- `event_remove`
- `event_update`

If toggle is false, mutation still happens, but event is not emitted.

## v1 Entry Functions

### `create_container(...)`

- Creates container and first owner (`role="creator"`)
- Updates `ContainerChain`
- Emits `ContainerCreatedEvent` when `event_create`
- Emits `OwnerAddedEvent` when `event_add`
- Appends update records for container creation

### `create_data_type(...)`

- Requires owner unless `public_create_data_type`
- Validates/uses target container
- Updates container data-type pointers/counter
- Emits `DataTypeCreatedEvent` when `event_create`
- Appends update records

### `publish_data_item(...)`

- Requires owner unless `public_publish_data_item`
- Validates data type belongs to container
- Validates no duplicate recipients/references
- Updates global `DataItemChain`, container pointers, and data-type pointer
- Emits `DataItemPublishedEvent` when `event_publish`

### `publish_data_item_verification(...)`

- Requires owner unless `public_publish_data_item`
- Caller must be one of `data_item.recipients`
- Prevents double verification per recipient address
- Updates `DataItemVerificationChain` and container verification pointers
- Updates `DataItem.verified` state machine:
  - any failure -> `Some(false)`
  - all required successes and no failures -> `Some(true)`
  - otherwise -> `None`
- Emits `DataItemVerificationPublishedEvent` when `event_publish`
- Appends update records for verification and data item

### `attach_container_child(...)`

- Parent and child both pass owner/public attach checks
- Validates parent!=child and child not already attached
- Sets `container_child.container_parent_id`
- Creates `ContainerChildLink`
- Emits `ContainerChildLinkAttachedEvent` when parent `event_attach`
- Appends update records

### `add_owner(...)`

- Requires owner unless `public_update_container`
- Existing owner path: writes `OwnerAudit`, updates/reactivates owner
- New owner path: appends owner object and increments active counter
- Emits `OwnerAddedEvent` based on path + `event_add`
- Appends update records for owner and container

### `remove_owner(...)`

- Requires owner unless `public_update_container`
- Prevents removing last active owner
- Prevents self-removal
- Soft-removes owner and decrements active counter
- Writes `OwnerAudit`
- Emits `OwnerRemovedEvent` when `event_remove`
- Appends update records for owner and container

### `update_container(...)`

- Requires owner unless `public_update_container`
- Writes `ContainerAudit` snapshot
- Updates container metadata/spec
- Emits `ContainerUpdatedEvent` when `event_update`
- Appends update records

### `update_data_type(...)`

- Requires owner unless `public_create_data_type`
- Validates container/data-type relation
- Writes `DataTypeAudit` snapshot
- Updates metadata/spec
- Emits `DataTypeUpdatedEvent` when `event_update`
- Appends update records

### `update_container_child_link(...)`

- Validates parent/child relation for link object
- Parent+child owner/public checks
- Writes `ContainerChildLinkAudit` snapshot
- Updates metadata
- Emits `ContainerLinkUpdatedEvent` when parent `event_update`
- Appends update records

### `update_container_owners_active_count(...)` (v1)

- Requires owner unless `public_update_container`
- Recomputes `owners_active_count` from owner vector
- Requires at least one active owner
- Appends update record for container

## Error Codes

- `1000 E_NOT_OWNER`
- `1001 E_INVALID_DATATYPE`
- `1002 E_CANNOT_REMOVE_LAST_OWNER`
- `1003 E_CANNOT_REMOVE_SELF`
- `1004 E_OWNER_NOT_FOUND`
- `1005 E_NO_ACTIVE_OWNERS`
- `1006 E_INVALID_CONTAINER`
- `1007 E_INVALID_VERIFICATION_SENDER`
- `1008 E_VERIFICATION_ALREADY_SUBMITTED`
- `1009 E_PARENT_MISMATCH`
- `1010 E_CHILD_MISMATCH`
- `1011 E_DUPLICATE_RECIPIENT`
- `1012 E_DUPLICATE_REFERENCE`

## v2 (Tiny Section)

Tag `v2` keeps almost all logic, with these key deltas:

- module renamed to `easy_publish::easy_publish`
- source path moved to `sources/easy_publish.move`
- `MODULE_VERSION` changed to `2`
- `update_container_owners_active_count(...)` is deprecated and now aborts (`E_DEPRECATED_FUNCTION = 2000`)
- new `update_container_owners_active_count_v2(...)` takes `clock: &Clock` and records updater metadata from caller + current timestamp
- `Move.toml` was added to repository in v2 (v1 did not include it in GitHub, although deployment used a package config)

## Release Notes / Historical Notes

- Deployment note: v1 runtime/deployment module naming is treated as `easy_publish::easy_publish`.
- Repository history note: tag `v1` source file still shows older namespace/module naming (`sendit_messenger::generic_store`) in `source/generic.move`.

## Future Upgrades (v3+)

- Planned approach: deploy a **new smart contract** for each major upgrade instead of trying to update existing on-chain code.
- Reason: updates create a new contract address, so in-place update flow is not useful for this project strategy.
- Method naming plan: bring `update_container_owners_active_count_v2(...)` back to canonical name `update_container_owners_active_count(...)` in v3+.

## Bug Section

- **Counter owners API (v1): wrong update metadata source**
  - In `update_container_owners_active_count(...)`, the update record is written using `container.creator.creator_addr` and `container.creator.creator_timestamp_ms`.
  - That means the record can attribute the recomputation to original container creator metadata instead of the current caller/time.

## Possible Stuff To Review (Not Confirmed)

- **Sequence counting source for verification chain**
  - `publish_data_item_verification` computes `next_index` from `container.last_data_item_verification_index`, then sets global `verification_chain.last_data_item_verification_index` to that value.
  - Worth reviewing if global counter should derive strictly from chain state.

- **`publish_data_item` does not create update records**
  - Most mutating entry functions call `create_update_record`, but `publish_data_item` does not.
  - Could be intentional, but worth verifying for audit consistency.

- **Container-child attach also sets child `sequence_index`**
  - `attach_container_child` sets `container_child.sequence_index` to parent child-link counter.
  - Might be intended, but worth validating if child container sequence should stay independent.

- **Counter wrap behavior**
  - `add_with_wrap` returns `1` on overflow (never `0`).
  - This is deterministic and valid, but indexers should account for wrap-to-1 semantics.
