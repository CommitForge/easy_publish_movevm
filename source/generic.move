module sendit_messenger::generic_store;

use iota::clock::Clock;
use iota::event;
use iota::tx_context::sender;
use std::string;

// ==========================
// CONSTANTS
// ==========================
const MODULE_VERSION: u32 = 1; 
/// true max 340282366920938463463374607431768211455
const MAX_u128: u128 = 340282366920938463463374607431768211450;
// error constants
const E_NOT_OWNER: u64 = 1000;
const E_INVALID_DATATYPE: u64 = 1001;
const E_CANNOT_REMOVE_LAST_OWNER: u64 = 1002;
const E_CANNOT_REMOVE_SELF: u64 = 1003;
const E_OWNER_NOT_FOUND: u64 = 1004;
const E_NO_ACTIVE_OWNERS: u64 = 1005;
const E_INVALID_CONTAINER: u64 = 1006;
//const E_INVALID_DATAITEM: u64 = 1007;
const E_INVALID_VERIFICATION_SENDER: u64 = 1007;
const E_VERIFICATION_ALREADY_SUBMITTED: u64 = 1008;
const E_PARENT_MISMATCH: u64 = 1009;
const E_CHILD_MISMATCH: u64 = 1010;
const E_DUPLICATE_RECIPIENT: u64 = 1011;
const E_DUPLICATE_REFERENCE: u64 = 1012;

// ==========================
// CHAINS
// ==========================
public struct ContainerChain has key, store {
    id: UID,
    last_container_index: u128,
    last_container_id: Option<ID>,
}

public struct UpdateChain has key, store {
    id: UID,
    last_update_record_index: u128,
    last_update_record_id: Option<ID>,
}

public struct DataItemChain has key, store {
    id: UID,
    last_data_item_index: u128,
    last_data_item_id: Option<ID>,
}

public struct DataItemVerificationChain has key, store {
    id: UID,
    last_data_item_verification_index: u128,
    last_data_item_verification_id: Option<ID>,
}

public struct ChainInit has  key, store {
    id: UID,
    module_version: u32,
    container_chain_id: ID,
    update_chain_id: ID,
    data_item_chain_id: ID,
    data_item_verification_chain_id: ID,
}

public struct ChainInitEvent has copy, drop {
    module_version: u32,
    container_chain_id: ID,
    update_chain_id: ID,
    data_item_chain_id: ID,
    data_item_verification_chain_id: ID,
}

// ==========================
// COMMONS
// ==========================
public struct Creator has store {
    creator_addr: address,
    creator_update_addr: Option<address>,
    creator_timestamp_ms: u64,
    creator_update_timestamp_ms: Option<u64>,
}

public struct Specification has store {
    version: string::String,
    schemas: string::String,
    apis: string::String,
    resources: string::String,
}

public struct ContainerPermission has store {
    public_update_container: bool,
    public_attach_container_child: bool,
    public_create_data_type: bool,
    public_publish_data_item: bool,
}

public struct ContainerEventConfig has store {
    event_create: bool,
    event_publish: bool,
    event_attach: bool,
    event_add: bool,
    event_remove: bool,
    event_update: bool,
}

public struct CreatorEvent has copy, drop {
    creator_addr: address,
    creator_update_addr: Option<address>,
    creator_timestamp_ms: u64,
    creator_update_timestamp_ms: Option<u64>,
}

public struct SpecificationEvent has copy, drop {
    version: string::String,
    schemas: string::String,
    apis: string::String,
    resources: string::String,
}

public struct ContainerPermissionEvent has copy, drop {
    public_update_container: bool,
    public_attach_container_child: bool,
    public_create_data_type: bool,
    public_publish_data_item: bool,
}

public struct ContainerEventConfigEvent has copy, drop {
    event_create: bool,
    event_publish: bool,
    event_attach: bool,
    event_add: bool,
    event_remove: bool,
    event_update: bool,
}

// ==========================
// OBJECTS
// ==========================
public struct Container has key, store {
    id: UID,
    container_parent_id: Option<ID>,
    external_id: string::String,
    creator: Creator,
    owners: vector<Owner>,
    owners_active_count: u32,
    name: string::String,
    description: string::String,
    content: string::String,
    specification: Specification,
    permission: ContainerPermission,
    event_config: ContainerEventConfig,
    sequence_index: u128,
    external_index: u128,
    last_owner_index: u128,
    last_container_child_link_index: u128,
    last_data_type_index: u128,
    last_data_item_index: u128,
    last_data_item_verification_index: u128,
    last_update_record_index: u128,
    last_owner_id: Option<ID>,
    last_container_child_link_id: Option<ID>,
    last_data_type_id: Option<ID>,
    last_data_item_id: Option<ID>,
    last_data_item_verification_id: Option<ID>,
    last_update_record_id: Option<ID>,
    prev_container_chain_id: Option<ID>,
}

public struct DataType has key, store {
    id: UID,
    container_id: ID,
    external_id: string::String,
    creator: Creator,
    name: string::String,
    description: string::String,
    content: string::String,
    specification: Specification,
    sequence_index: u128,
    external_index: u128,
    last_data_item_id: Option<ID>,
    prev_id: Option<ID>,
}

public struct DataItem has key, store {
    id: UID,
    container_id: ID,
    data_type_id: ID,
    external_id: string::String,
    creator: Creator,
    recipients: Option<vector<address>>,
    name: string::String,
    description: string::String,
    content: string::String,
    sequence_index: u128,
    external_index: u128,
    references: Option<vector<ID>>,
    // Verification tracking
    verification_success_addresses: Option<vector<address>>,
    verification_failure_addresses: Option<vector<address>>,
    verified: Option<bool>,
    verification_success_data_item: Option<vector<ID>>,
    verification_failure_data_item: Option<vector<ID>>,
    prev_data_item_chain_id: Option<ID>,
    prev_id: Option<ID>,
    prev_data_type_item_id: Option<ID>,
}

public struct DataItemVerification has key, store {
    id: UID,
    // Scope
    container_id: ID,
    data_item_id: ID,
    // External linkage
    external_id: string::String,
    // Creator
    creator: Creator,
    recipients: Option<vector<address>>,
    // Metadata
    name: string::String,
    description: string::String,
    content: string::String,
    sequence_index: u128,
    external_index: u128,
    // Target reference
    references: Option<vector<ID>>,
    // Verification result
    verified: bool,
    // Chain pointers
    prev_data_item_verification_chain_id: Option<ID>,
    prev_id: Option<ID>,
}

public struct ContainerChildLink has key, store {
    id: UID,
    container_parent_id: ID,
    container_child_id: ID,
    external_id: string::String,
    creator: Creator,
    name: string::String,
    description: string::String,
    content: string::String,
    sequence_index: u128,
    external_index: u128,
    prev_id: Option<ID>,
}

public struct Owner has key, store {
    id: UID,
    container_id: ID,
    creator: Creator,
    addr: address,
    role: string::String,
    removed: bool,
    sequence_index: u128,
    prev_id: Option<ID>,
}

public struct UpdateChainRecord has key, store {
    id: UID,
    object_id: ID,
    creator: Creator,
    object_type: string::String,
    // 1 - CREATE, 2 - UPDATE
    action: u8,
    sequence_index: u128,
    prev_id: Option<ID>,
}

public struct UpdateContainerRecord has key, store {
    id: UID,
    container_id: ID,
    object_id: ID,
    creator: Creator,
    object_type: string::String,
    // 1 - CREATE, 2 - UPDATE
    action: u8,
    sequence_index: u128,
    prev_id: Option<ID>,
}

// ==========================
// EVENTS (FULL OBJECT SNAPSHOT)
// ==========================
public struct ContainerCreatedEvent has copy, drop {
    object_id: ID,
    container_parent_id: Option<ID>,
    external_id: string::String,
    creator: CreatorEvent,
    owners: vector<OwnerAddedEvent>,
    owners_active_count: u32,
    name: string::String,
    description: string::String,
    content: string::String,
    specification: SpecificationEvent,
    permission: ContainerPermissionEvent,
    event_config: ContainerEventConfigEvent,
    sequence_index: u128,
    external_index: u128,
    last_owner_index: u128,
    last_container_child_link_index: u128,
    last_data_type_index: u128,
    last_data_item_index: u128,
    last_data_item_verification_index: u128,
    last_update_record_index: u128,
    last_owner_id: Option<ID>,
    last_container_child_link_id: Option<ID>,
    last_data_type_id: Option<ID>,
    last_data_item_id: Option<ID>,
    last_data_item_verification_id: Option<ID>,
    last_update_record_id: Option<ID>,
    prev_container_chain_id: Option<ID>,
}

public struct DataTypeCreatedEvent has copy, drop {
    object_id: ID,
    container_id: ID,
    external_id: string::String,
    creator: CreatorEvent,
    name: string::String,
    description: string::String,
    content: string::String,
    specification: SpecificationEvent,
    sequence_index: u128,
    external_index: u128,
    last_data_item_id: Option<ID>,
    prev_id: Option<ID>,
}

public struct DataItemPublishedEvent has copy, drop {
    object_id: ID,
    container_id: ID,
    data_type_id: ID,
    external_id: string::String,
    creator: CreatorEvent,
    recipients: Option<vector<address>>,
    name: string::String,
    description: string::String,
    content: string::String,
    sequence_index: u128,
    external_index: u128,
    references: Option<vector<ID>>,
    verification_success_addresses: Option<vector<address>>,
    verification_failure_addresses: Option<vector<address>>,
    verified: Option<bool>,
    verification_success_data_item: Option<vector<ID>>,
    verification_failure_data_item: Option<vector<ID>>,
    prev_data_item_chain_id: Option<ID>,
    prev_id: Option<ID>,
    prev_data_type_item_id: Option<ID>,
}

public struct DataItemVerificationPublishedEvent has copy, drop {
    object_id: ID,
    container_id: ID,
    data_item_id: ID,
    external_id: string::String,
    creator: CreatorEvent,
    recipients: Option<vector<address>>,
    name: string::String,
    description: string::String,
    content: string::String,
    sequence_index: u128,
    external_index: u128,
    references: Option<vector<ID>>,
    verified: bool,
    prev_data_item_verification_chain_id: Option<ID>,
    prev_id: Option<ID>,
}

public struct ContainerChildLinkAttachedEvent has copy, drop {
    object_id: ID,
    container_parent_id: ID,
    container_child_id: ID,
    external_id: string::String,
    creator: CreatorEvent,
    name: string::String,
    description: string::String,
    content: string::String,
    sequence_index: u128,
    external_index: u128,
    prev_id: Option<ID>,
}

public struct OwnerAddedEvent has copy, drop {
    object_id: ID,
    container_id: ID,
    creator: CreatorEvent,
    addr: address,
    role: string::String,
    removed: bool,
    sequence_index: u128,
    prev_id: Option<ID>,
}

public struct OwnerRemovedEvent has copy, drop {
    object_id: ID,
    container_id: ID,
    creator: CreatorEvent,
    addr: address,
    role: string::String,
    removed: bool,
    sequence_index: u128,
    prev_id: Option<ID>,
}

public struct ContainerUpdatedEvent has copy, drop {
    object_id: ID,
    container_parent_id: Option<ID>,
    external_id: string::String,
    creator: CreatorEvent,
    name: string::String,
    description: string::String,
    content: string::String,
    specification: SpecificationEvent,
}

public struct DataTypeUpdatedEvent has copy, drop {
    object_id: ID,
    container_id: ID,
    external_id: string::String,
    creator: CreatorEvent,
    name: string::String,
    description: string::String,
    content: string::String,
    specification: SpecificationEvent,
}

public struct ContainerLinkUpdatedEvent has copy, drop {
    object_id: ID,
    container_parent_id: ID,
    container_child_id: ID,
    external_id: string::String,
    creator: CreatorEvent,
    name: string::String,
    description: string::String,
    content: string::String,
}

public struct ContainerAudit has key, store {
    id: UID,
    object_id: ID,
    container_parent_id: Option<ID>,
    external_id: string::String,
    creator: Creator,
    name: string::String,
    description: string::String,
    content: string::String,
    specification: Specification,
}

public struct DataTypeAudit has key, store {
    id: UID,
    object_id: ID,
    container_id: ID,
    external_id: string::String,
    creator: Creator,
    name: string::String,
    description: string::String,
    content: string::String,
    specification: Specification,
}

public struct ContainerChildLinkAudit has key, store {
    id: UID,
    object_id: ID,
    container_parent_id: ID,
    container_child_id: ID,
    external_id: string::String,
    creator: Creator,
    name: string::String,
    description: string::String,
    content: string::String,
}

public struct OwnerAudit has key, store {
    id: UID,
    object_id: ID,
    container_id: ID,
    creator: Creator,
    addr: address,
    role: string::String,
    removed: bool,
}

// ==========================
// INIT
// ==========================
fun init(ctx: &mut TxContext) {
    let container_chain = ContainerChain {
        id: object::new(ctx),
        last_container_index: 0,
        last_container_id: option::none<ID>(),
    };

    let container_id = object::id(&container_chain);
    transfer::share_object(container_chain);

    let update_chain = UpdateChain {
        id: object::new(ctx),
        last_update_record_index: 0,
        last_update_record_id: option::none<ID>(),
    };

    let update_id = object::id(&update_chain);
    transfer::share_object(update_chain);

    let data_item_chain = DataItemChain {
        id: object::new(ctx),
        last_data_item_index: 0,
        last_data_item_id: option::none<ID>(),
    };

    let data_item_id = object::id(&data_item_chain);
    transfer::share_object(data_item_chain);

    let data_item_verification_chain = DataItemVerificationChain {
        id: object::new(ctx),
        last_data_item_verification_index: 0,
        last_data_item_verification_id: option::none<ID>(),
    };

    let data_item_verification_id = object::id(&data_item_verification_chain);
    transfer::share_object(data_item_verification_chain);

    transfer::share_object(ChainInit{
        id: object::new(ctx),
        module_version: MODULE_VERSION,
        container_chain_id: container_id,
        update_chain_id: update_id,
        data_item_chain_id: data_item_id,
        data_item_verification_chain_id: data_item_verification_id,
    });

    event::emit(ChainInitEvent {
        module_version: MODULE_VERSION,
        container_chain_id: container_id,
        update_chain_id: update_id,
        data_item_chain_id: data_item_id,
        data_item_verification_chain_id: data_item_verification_id,
    });
}

// ==========================
// CONTAINER
// ==========================
public entry fun create_container(
    container_chain: &mut ContainerChain,
    update_chain: &mut UpdateChain,
    external_id: string::String,
    name: string::String,
    description: string::String,
    content: string::String,
    version: string::String,
    schemas: string::String,
    apis: string::String,
    resources: string::String,
    public_update_container: bool,
    public_attach_container_child: bool,
    public_create_data_type: bool,
    public_publish_data_item: bool,
    event_create: bool,
    event_publish: bool,
    event_attach: bool,
    event_add: bool,
    event_remove: bool,
    event_update: bool,
    external_index: u128,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // Creator info
    let creator_owner_addr = sender(ctx);
    let creator_timestamp_ms = clock.timestamp_ms();

    let creator_owner = Creator {
        creator_addr: creator_owner_addr,
        creator_update_addr: option::none(),
        creator_timestamp_ms: creator_timestamp_ms,
        creator_update_timestamp_ms: option::none(),
    };

    // Container specification
    let specification = Specification {
        version: version,
        schemas: schemas,
        apis: apis,
        resources: resources,
    };

    let container_permission = ContainerPermission {
        public_update_container: public_update_container,
        public_attach_container_child: public_attach_container_child,
        public_create_data_type: public_create_data_type,
        public_publish_data_item: public_publish_data_item,
    };

    let container_event_config = ContainerEventConfig {
        event_create: event_create,
        event_publish: event_publish,
        event_attach: event_attach,
        event_add: event_add,
        event_remove: event_remove,
        event_update: event_update,
    };

    let creator_container = Creator {
        creator_addr: creator_owner_addr,
        creator_update_addr: option::none(),
        creator_timestamp_ms: creator_timestamp_ms,
        creator_update_timestamp_ms: option::none(),
    };

    let last_container_id = container_chain.last_container_id;

    // Container object
    let mut container = Container {
        id: object::new(ctx),
        container_parent_id: option::none(),
        owners: vector::empty<Owner>(),
        owners_active_count: 1,
        external_id: external_id,
        creator: creator_container,
        name: name,
        description: description,
        content: content,
        specification: specification,
        permission: container_permission,
        event_config: container_event_config,
        sequence_index: 1,
        external_index: external_index,
        last_owner_index: 1,
        last_container_child_link_index: 0,
        last_data_type_index: 0,
        last_data_item_index: 0,
        last_data_item_verification_index: 0,
        last_update_record_index: 0,
        last_owner_id: option::none(),
        last_container_child_link_id: option::none(),
        last_data_type_id: option::none(),
        last_data_item_id: option::none(),
        last_data_item_verification_id: option::none(),
        last_update_record_id: option::none(),
        prev_container_chain_id: last_container_id,
    };

    let container_id = object::id(&container);
    // Owner object
    let owner = Owner {
        id: object::new(ctx),
        container_id: container_id,
        creator: creator_owner,
        addr: creator_owner_addr,
        role: string::utf8(b"creator"),
        removed: false,
        sequence_index: 1,
        prev_id: option::none(),
    };

    let owner_id = object::id(&owner);

    vector::push_back(&mut container.owners, owner);
    container.last_owner_id = option::some(owner_id);

    // Update chain
    container_chain.last_container_index = add_with_wrap(container_chain.last_container_index, 1);
    container_chain.last_container_id = option::some(container_id);

    // Collect active owner addresses
    /* let mut owner_addrs = vector::empty<string::String>();
    let len = vector::length(&container.owners);
    let mut i = 0;
    while (i < len) {
        let owner_ref = vector::borrow(&container.owners, i);
        if (!owner_ref.removed) {
            vector::push_back(&mut owner_addrs, owner_ref.addr);
        };
        i = i + 1;
    };*/

    // Emit event
    if (event_create) {
        let specification_event = SpecificationEvent {
            version: version,
            schemas: schemas,
            apis: apis,
            resources: resources,
        };

        let container_permission_event = ContainerPermissionEvent {
            public_update_container: public_update_container,
            public_attach_container_child: public_attach_container_child,
            public_create_data_type: public_create_data_type,
            public_publish_data_item: public_publish_data_item,
        };

        let container_event_config_event = ContainerEventConfigEvent {
            event_create: event_create,
            event_publish: event_publish,
            event_attach: event_attach,
            event_add: event_add,
            event_remove: event_remove,
            event_update: event_update,
        };

        let creator_event = CreatorEvent {
            creator_addr: creator_owner_addr,
            creator_update_addr: option::none(),
            creator_timestamp_ms: creator_timestamp_ms,
            creator_update_timestamp_ms: option::none(),
        };

        let owner_event = OwnerAddedEvent {
            object_id: owner_id,
            container_id: container_id,
            creator: creator_event,
            addr: creator_owner_addr,
            role: string::utf8(b"creator"),
            removed: false,
            sequence_index: 1,
            prev_id: option::none(),
        };

        event::emit(ContainerCreatedEvent {
            object_id: container_id,
            container_parent_id: option::none(),
            external_id: container.external_id,
            creator: creator_event,
            owners: vector::singleton(owner_event),
            owners_active_count: 1,
            name: container.name,
            description: container.description,
            content: container.content,
            specification: specification_event,
            permission: container_permission_event,
            event_config: container_event_config_event,
            sequence_index: container.sequence_index,
            external_index: container.external_index,
            last_owner_index: container.last_owner_index,
            last_container_child_link_index: container.last_container_child_link_index,
            last_data_type_index: container.last_data_type_index,
            last_data_item_index: container.last_data_item_index,
            last_data_item_verification_index: container.last_data_item_verification_index,
            last_update_record_index: container.last_update_record_index,
            last_owner_id: container.last_owner_id,
            last_container_child_link_id: container.last_container_child_link_id,
            last_data_type_id: container.last_data_type_id,
            last_data_item_id: container.last_data_item_id,
            last_data_item_verification_id: container.last_data_item_verification_id,
            last_update_record_id: container.last_update_record_id,
            prev_container_chain_id: last_container_id,
        });
    };

    if (event_add) {
        let creator_owner_event = CreatorEvent {
            creator_addr: creator_owner_addr,
            creator_update_addr: option::none(),
            creator_timestamp_ms: creator_timestamp_ms,
            creator_update_timestamp_ms: option::none(),
        };

        event::emit(OwnerAddedEvent {
            object_id: owner_id,
            container_id: container_id,
            creator: creator_owner_event,
            addr: creator_owner_addr,
            role: string::utf8(b"creator"),
            removed: false,
            sequence_index: 1,
            prev_id: option::none(),
        });
    };

    create_update_record(
        update_chain,
        &mut container,
        container_id,
        container_id,
        creator_owner_addr,
        creator_timestamp_ms,
        string::utf8(b"container"),
        1,
        ctx,
    );
    transfer::share_object(container);
}

// ==========================
// DATA TYPE
// ==========================
public entry fun create_data_type(
    update_chain: &mut UpdateChain,
    container: &mut Container,
    external_id: string::String,
    name: string::String,
    description: string::String,
    content: string::String,
    version: string::String,
    schemas: string::String,
    apis: string::String,
    resources: string::String,
    external_index: u128,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let permission_ref = &container.permission;
    let event_config_ref = &container.event_config;
    assert_owner(container, permission_ref.public_create_data_type, ctx);

    let container_id = object::id(container);
    let next_index = add_with_wrap(container.last_data_type_index, 1);
    let creator_addr = sender(ctx);
    let creator_timestamp_ms = clock.timestamp_ms();

    let creator = Creator {
        creator_addr: creator_addr,
        creator_update_addr: option::none(),
        creator_timestamp_ms: creator_timestamp_ms,
        creator_update_timestamp_ms: option::none(),
    };

    let specification = Specification {
        version: version,
        schemas: schemas,
        apis: apis,
        resources: resources,
    };

    let data_type = DataType {
        id: object::new(ctx),
        container_id: container_id,
        external_id: external_id,
        creator: creator,
        name: name,
        description: description,
        content: content,
        specification: specification,
        sequence_index: next_index,
        external_index: external_index,
        last_data_item_id: option::none(),
        prev_id: container.last_data_type_id,
    };

    let data_type_id = object::id(&data_type);
    container.last_data_type_id = option::some(data_type_id);
    container.last_data_type_index = next_index;

    if (event_config_ref.event_create) {
        let specification_event = SpecificationEvent {
            version: version,
            schemas: schemas,
            apis: apis,
            resources: resources,
        };

        let creator_event = CreatorEvent {
            creator_addr: creator_addr,
            creator_update_addr: option::none(),
            creator_timestamp_ms: creator_timestamp_ms,
            creator_update_timestamp_ms: option::none(),
        };

        event::emit(DataTypeCreatedEvent {
            object_id: data_type_id,
            container_id: container_id,
            external_id: data_type.external_id,
            creator: creator_event,
            name: data_type.name,
            description: data_type.description,
            content: data_type.content,
            specification: specification_event,
            sequence_index: data_type.sequence_index,
            external_index: data_type.external_index,
            last_data_item_id: data_type.last_data_item_id,
            prev_id: data_type.prev_id,
        });
    };

    create_update_record(
        update_chain,
        container,
        container_id,
        data_type_id,
        creator_addr,
        creator_timestamp_ms,
        string::utf8(b"data_type"),
        1,
        ctx,
    );
    transfer::share_object(data_type);
}

// ==========================
// DATA ITEM
// ==========================
public entry fun publish_data_item(
    data_item_chain: &mut DataItemChain,
    container: &mut Container,
    data_type: &mut DataType,
    external_id: string::String,
    recipients: Option<vector<address>>,
    name: string::String,
    description: string::String,
    content: string::String,
    external_index: u128,
    references: Option<vector<ID>>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let permission_ref = &container.permission;
    let event_config_ref = &container.event_config;
    assert_owner(container, permission_ref.public_publish_data_item, ctx);

    let container_id = object::id(container);
    assert!(data_type.container_id == container_id, E_INVALID_DATATYPE);

    if (option::is_some(&recipients)) {
        let recs: &vector<address> = option::borrow(&recipients);
        assert_no_duplicate_address(recs, E_DUPLICATE_RECIPIENT);
    };

    if (option::is_some(&references)) {
        let refs: &vector<ID> = option::borrow(&references);
        assert_no_duplicate_id(refs, E_DUPLICATE_REFERENCE);
    };

    let data_type_id = object::id(data_type);
    let next_index = add_with_wrap(container.last_data_item_index, 1);
    let creator_addr = sender(ctx);
    let creator_timestamp_ms = clock.timestamp_ms();

    let creator = Creator {
        creator_addr: creator_addr,
        creator_update_addr: option::none(),
        creator_timestamp_ms: creator_timestamp_ms,
        creator_update_timestamp_ms: option::none(),
    };

    let data_item_chain_id = data_item_chain.last_data_item_id;

    let data_item = DataItem {
        id: object::new(ctx),
        container_id: container_id,
        data_type_id: data_type_id,
        external_id: external_id,
        creator: creator,
        recipients: recipients,
        name: name,
        description: description,
        content: content,
        sequence_index: next_index,
        external_index: external_index,
        references: references,
        // verification fields
        verification_success_addresses: option::none(),
        verification_failure_addresses: option::none(),
        verified: option::none(),
        verification_success_data_item: option::none(),
        verification_failure_data_item: option::none(),
        prev_data_item_chain_id: data_item_chain_id,
        prev_id: container.last_data_item_id,
        prev_data_type_item_id: data_type.last_data_item_id,
    };

    let data_item_id = object::id(&data_item);
    let data_item_id_option = option::some(data_item_id);

    // Update chain
    data_item_chain.last_data_item_index = add_with_wrap(data_item_chain.last_data_item_index, 1);
    data_item_chain.last_data_item_id = data_item_id_option;

    data_type.last_data_item_id = data_item_id_option;
    container.last_data_item_id = data_item_id_option;
    container.last_data_item_index = next_index;

    // Emit event
    if (event_config_ref.event_publish) {
        let creator_event = CreatorEvent {
            creator_addr: creator_addr,
            creator_update_addr: option::none(),
            creator_timestamp_ms: creator_timestamp_ms,
            creator_update_timestamp_ms: option::none(),
        };

        event::emit(DataItemPublishedEvent {
            object_id: data_item_id,
            container_id: container_id,
            data_type_id: data_type_id,
            external_id: data_item.external_id,
            recipients: data_item.recipients,
            creator: creator_event,
            name: data_item.name,
            description: data_item.description,
            content: data_item.content,
            sequence_index: data_item.sequence_index,
            external_index: data_item.external_index,
            references: data_item.references,
            verification_success_addresses: data_item.verification_success_addresses,
            verification_failure_addresses: data_item.verification_failure_addresses,
            verified: data_item.verified,
            verification_success_data_item: data_item.verification_success_data_item,
            verification_failure_data_item: data_item.verification_failure_data_item,
            prev_data_item_chain_id: data_item_chain_id,
            prev_id: data_item.prev_id,
            prev_data_type_item_id: data_item.prev_data_type_item_id,
        });
    };

    transfer::share_object(data_item);
}

public entry fun publish_data_item_verification(
    update_chain: &mut UpdateChain,
    verification_chain: &mut DataItemVerificationChain,
    container: &mut Container,
    data_item: &mut DataItem,
    external_id: string::String,
    recipients: Option<vector<address>>,
    name: string::String,
    description: string::String,
    content: string::String,
    external_index: u128,
    references: Option<vector<ID>>,
    verified: bool,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let permission_ref = &container.permission;
    let event_config_ref = &container.event_config;
    assert_owner(container, permission_ref.public_publish_data_item, ctx);

    let sender_addr = sender(ctx);
    let container_id = object::id(container);
    let data_item_id = object::id(data_item);

    // --- we should allow/trust the recipient to decide, into which container/data type he will store his own verification ----
    //assert!(data_item.container_id == container_id, E_INVALID_DATAITEM);

    // --- sender must be recipient ---
    assert!(option::is_some(&data_item.recipients), E_INVALID_VERIFICATION_SENDER);

    let required_recipients = option::borrow(&data_item.recipients);
    assert!(vector::contains(required_recipients, &sender_addr), E_INVALID_VERIFICATION_SENDER);

    if (option::is_some(&recipients)) {
        let recs: &vector<address> = option::borrow(&recipients);
        assert_no_duplicate_address(recs, E_DUPLICATE_RECIPIENT);
    };

    if (option::is_some(&references)) {
        let refs: &vector<ID> = option::borrow(&references);
        assert_no_duplicate_id(refs, E_DUPLICATE_REFERENCE);
    };

    // --- no double submission (FIXED) ---
    let already_submitted =
        (option::is_some(&data_item.verification_success_addresses)
            && vector::contains(
                option::borrow(&data_item.verification_success_addresses),
                &sender_addr
            ))
        ||
        (option::is_some(&data_item.verification_failure_addresses)
            && vector::contains(
                option::borrow(&data_item.verification_failure_addresses),
                &sender_addr
            ));

    assert!(!already_submitted, E_VERIFICATION_ALREADY_SUBMITTED);

    let timestamp_ms = clock.timestamp_ms();
    let next_index = add_with_wrap(container.last_data_item_verification_index, 1);

    // --- informational recipients ---
    let info_recipients = if (option::is_some(&recipients)) {
        option::some(clone_vector_address(option::borrow(&recipients)))
    } else {
        option::none()
    };

    let creator = Creator {
        creator_addr: sender_addr,
        creator_update_addr: option::none(),
        creator_timestamp_ms: timestamp_ms,
        creator_update_timestamp_ms: option::none(),
    };

    // --- create verification object ---
    let verification = DataItemVerification {
        id: object::new(ctx),
        container_id: container_id,
        data_item_id: data_item_id,
        external_id: external_id,
        creator: creator,
        recipients: info_recipients,
        name: name,
        description: description,
        content: content,
        sequence_index: next_index,
        external_index: external_index,
        references: references,
        verified: verified,
        prev_data_item_verification_chain_id: verification_chain.last_data_item_verification_id,
        prev_id: container.last_data_item_verification_id,
    };

    let verification_id = object::id(&verification);
    let verification_id_option = option::some(verification_id);

    // --- update chains ---
    verification_chain.last_data_item_verification_index = next_index;
    verification_chain.last_data_item_verification_id = verification_id_option;

    container.last_data_item_verification_index = next_index;
    container.last_data_item_verification_id = verification_id_option;

    // --- update data item state ---
    if (verified) {
        if (!option::is_some(&data_item.verification_success_addresses)) {
            data_item.verification_success_addresses = option::some(vector::empty<address>());
        };
        if (!option::is_some(&data_item.verification_success_data_item)) {
            data_item.verification_success_data_item = option::some(vector::empty<ID>());
        };

        vector::push_back(
            option::borrow_mut(&mut data_item.verification_success_addresses),
            sender_addr,
        );

        vector::push_back(
            option::borrow_mut(&mut data_item.verification_success_data_item),
            verification_id,
        );
    } else {
        if (!option::is_some(&data_item.verification_failure_addresses)) {
            data_item.verification_failure_addresses = option::some(vector::empty<address>());
        };
        if (!option::is_some(&data_item.verification_failure_data_item)) {
            data_item.verification_failure_data_item = option::some(vector::empty<ID>());
        };

        vector::push_back(
            option::borrow_mut(&mut data_item.verification_failure_addresses),
            sender_addr,
        );

        vector::push_back(
            option::borrow_mut(&mut data_item.verification_failure_data_item),
            verification_id,
        );
    };

    // --- VERIFIED STATE MACHINE (FIXED & EXPLICIT) ---

    let required_count = vector::length(required_recipients);

    // Check failure first (only need to know if > 0)
    let has_failure =
        option::is_some(&data_item.verification_failure_addresses) &&
        !vector::is_empty(option::borrow(&data_item.verification_failure_addresses));

    if (has_failure) {
        data_item.verified = option::some(false);
    } else {
        let success_count = if (option::is_some(&data_item.verification_success_addresses)) {
            vector::length(option::borrow(&data_item.verification_success_addresses))
        } else {
            0
        };

        if (success_count >= required_count) {
            data_item.verified = option::some(true);
        } else {
            data_item.verified = option::none();
        };
    };

    if (event_config_ref.event_publish) {
        let creator_event = CreatorEvent {
            creator_addr: sender_addr,
            creator_update_addr: option::none(),
            creator_timestamp_ms: timestamp_ms,
            creator_update_timestamp_ms: option::none(),
        };

        event::emit(DataItemVerificationPublishedEvent {
            object_id: verification_id,
            container_id: container_id,
            data_item_id: data_item_id,
            external_id: verification.external_id,
            creator: creator_event,
            recipients: verification.recipients, // FIXED
            name: verification.name,
            description: verification.description,
            content: verification.content,
            sequence_index: verification.sequence_index,
            external_index: verification.external_index,
            references: verification.references,
            verified: verification.verified,
            prev_data_item_verification_chain_id: verification.prev_data_item_verification_chain_id,
            prev_id: verification.prev_id,
        });
    };

    transfer::share_object(verification);

    // --- update records ---
    create_update_record(
        update_chain,
        container,
        container_id,
        verification_id,
        sender_addr,
        timestamp_ms,
        string::utf8(b"data_item_verification"),
        2,
        ctx,
    );

    create_update_record(
        update_chain,
        container,
        container_id,
        data_item_id,
        sender_addr,
        timestamp_ms,
        string::utf8(b"data_item"),
        2,
        ctx,
    );
}

// ==========================
// CHILD CONTAINERS
// ==========================
public entry fun attach_container_child(
    update_chain: &mut UpdateChain,
    container_parent: &mut Container,
    container_child: &mut Container,
    external_id: string::String,
    name: string::String,
    description: string::String,
    content: string::String,
    external_index: u128,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // Check ownership of both containers
    let parent_permission_ref = &container_parent.permission;
    let child_permission_ref = &container_child.permission;
    let parent_event_config_ref = &container_parent.event_config;
    assert_owner(container_parent, parent_permission_ref.public_attach_container_child, ctx);
    assert_owner(container_child, child_permission_ref.public_attach_container_child, ctx);
    let container_parent_id = object::id(container_parent);
    let container_child_id = object::id(container_child);
    // Ensure parent and child are not the same
    assert!(container_parent_id != container_child_id, E_INVALID_CONTAINER);
    // Ensure a container that is already a parent cannot become a child
    assert!(container_child.last_container_child_link_id.is_none(), E_INVALID_CONTAINER);
    // Prevent attaching the same child more than once
    assert!(option::is_none(&container_child.container_parent_id), E_INVALID_CONTAINER);
    container_child.container_parent_id = option::some(container_parent_id);

    // Increment sequence
    let next_index = add_with_wrap(container_parent.last_container_child_link_index, 1);
    let creator_addr = sender(ctx);
    let creator_timestamp_ms = clock.timestamp_ms();

    // Creator struct
    let creator = Creator {
        creator_addr: creator_addr,
        creator_update_addr: option::none(),
        creator_timestamp_ms: creator_timestamp_ms,
        creator_update_timestamp_ms: option::none(),
    };

    // Create the container child link
    let container_child_link = ContainerChildLink {
        id: object::new(ctx),
        container_parent_id: container_parent_id,
        container_child_id: container_child_id,
        external_id: external_id,
        creator: creator,
        name: name,
        description: description,
        content: content,
        sequence_index: next_index,
        external_index: external_index,
        prev_id: container_parent.last_container_child_link_id,
    };

    let container_child_link_id = object::id(&container_child_link);
    container_parent.last_container_child_link_id = option::some(container_child_link_id);
    container_parent.last_container_child_link_index = next_index;
    container_child.sequence_index = next_index;

    // Emit event if configured
    if (parent_event_config_ref.event_attach) {
        let creator_event = CreatorEvent {
            creator_addr: container_child_link.creator.creator_addr,
            creator_update_addr: container_child_link.creator.creator_update_addr,
            creator_timestamp_ms: container_child_link.creator.creator_timestamp_ms,
            creator_update_timestamp_ms: container_child_link.creator.creator_update_timestamp_ms,
        };

        event::emit(ContainerChildLinkAttachedEvent {
            object_id: container_child_link_id,
            container_parent_id: container_parent_id,
            container_child_id: container_child_id,
            external_id: container_child_link.external_id,
            creator: creator_event,
            name: container_child_link.name,
            description: container_child_link.description,
            content: container_child_link.content,
            sequence_index: container_child_link.sequence_index,
            external_index: container_child_link.external_index,
            prev_id: container_child_link.prev_id,
        });
    };

    create_update_record(
        update_chain,
        container_parent,
        container_parent_id,
        container_child_link_id,
        creator_addr,
        creator_timestamp_ms,
        string::utf8(b"container_child_link"),
        1,
        ctx,
    );
    transfer::share_object(container_child_link);
}

// ==========================
// CONTAINER OWNER MANAGEMENT
// ==========================
public entry fun add_owner(
    update_chain: &mut UpdateChain,
    container: &mut Container,
    new_owner: address,
    role: string::String,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let permission_ref = &container.permission;
    let event_config_ref = &container.event_config;
    let event_add = event_config_ref.event_add;
    assert_owner(container, permission_ref.public_update_container, ctx);

    let container_id = object::id(container);
    let caller_addr = sender(ctx);
    let timestamp_ms = clock.timestamp_ms();

    let updater_addr = option::some(caller_addr);
    let updater_timestamp_ms = option::some(timestamp_ms);

    let len = vector::length(&container.owners);
    let mut i = 0;
    let mut found = false;

    while (i < len) {
        let owner = vector::borrow_mut(&mut container.owners, i);

        if (owner.addr == new_owner) {
            let was_removed = owner.removed;

            let old_creator = Creator {
                creator_addr: owner.creator.creator_addr,
                creator_update_addr: owner.creator.creator_update_addr,
                creator_timestamp_ms: owner.creator.creator_timestamp_ms,
                creator_update_timestamp_ms: owner.creator.creator_update_timestamp_ms,
            };

            let owner_id = object::id(owner);
            let owner_prev_id = owner.prev_id;

            let audit = OwnerAudit {
                id: object::new(ctx),
                object_id: owner_id,
                container_id: container_id,
                creator: old_creator,
                addr: owner.addr,
                role: owner.role,
                removed: owner.removed,
            };

            if (was_removed) {
                owner.removed = false;
                container.owners_active_count = container.owners_active_count + 1;
            };

            owner.role = role;
            owner.creator.creator_update_addr = updater_addr;
            owner.creator.creator_update_timestamp_ms = updater_timestamp_ms;

            found = true;

            if (event_add && was_removed) {
                let new_creator_event = CreatorEvent {
                    creator_addr: owner.creator.creator_addr,
                    creator_update_addr: updater_addr,
                    creator_timestamp_ms: owner.creator.creator_timestamp_ms,
                    creator_update_timestamp_ms: updater_timestamp_ms,
                };

                event::emit(OwnerAddedEvent {
                    object_id: owner_id,
                    container_id: container_id,
                    creator: new_creator_event,
                    addr: owner.addr,
                    role: owner.role,
                    removed: owner.removed,
                    sequence_index: owner.sequence_index,
                    prev_id: owner_prev_id,
                });
            };

            create_update_record(
                update_chain,
                container,
                container_id,
                object::id(&audit),
                caller_addr,
                timestamp_ms,
                string::utf8(b"owner_audit"),
                1,
                ctx,
            );

            create_update_record(
                update_chain,
                container,
                container_id,
                owner_id,
                caller_addr,
                timestamp_ms,
                string::utf8(b"owner"),
                2,
                ctx,
            );

            transfer::share_object(audit);

            break
        };

        i = i + 1;
    };

    if (!found) {
        let next_index = add_with_wrap(container.last_owner_index, 1);
        container.last_owner_index = next_index;

        let creator = Creator {
            creator_addr: caller_addr,
            creator_update_addr: option::none(),
            creator_timestamp_ms: timestamp_ms,
            creator_update_timestamp_ms: option::none(),
        };

        let owner = Owner {
            id: object::new(ctx),
            container_id: container_id,
            creator: creator,
            addr: new_owner,
            role: role,
            removed: false,
            sequence_index: next_index,
            prev_id: container.last_owner_id,
        };

        let owner_id = object::id(&owner);
        let owner_prev_id = owner.prev_id;

        container.last_owner_id = option::some(owner_id);
        container.owners_active_count = container.owners_active_count + 1;

        create_update_record(
            update_chain,
            container,
            container_id,
            owner_id,
            caller_addr,
            timestamp_ms,
            string::utf8(b"owner"),
            1,
            ctx,
        );

        vector::push_back(&mut container.owners, owner);

        if (event_add) {
            let creator_event = CreatorEvent {
                creator_addr: caller_addr,
                creator_update_addr: option::none(),
                creator_timestamp_ms: timestamp_ms,
                creator_update_timestamp_ms: option::none(),
            };

            event::emit(OwnerAddedEvent {
                object_id: owner_id,
                container_id: container_id,
                creator: creator_event,
                addr: new_owner,
                role: role,
                removed: false,
                sequence_index: next_index,
                prev_id: owner_prev_id,
            });
        };
    };

    create_update_record(
        update_chain,
        container,
        container_id,
        container_id,
        caller_addr,
        timestamp_ms,
        string::utf8(b"container"),
        2,
        ctx,
    );
}

public entry fun remove_owner(
    update_chain: &mut UpdateChain,
    container: &mut Container,
    owner_addr_remove: address,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let permission_ref = &container.permission;
    let event_config_ref = &container.event_config;
    assert_owner(container, permission_ref.public_update_container, ctx);
    assert!(container.owners_active_count > 1, E_CANNOT_REMOVE_LAST_OWNER);

    let container_id = object::id(container);
    let caller_addr = sender(ctx);
    let timestamp_ms = clock.timestamp_ms();

    let updater_addr = option::some(caller_addr);
    let update_timestamp_ms = option::some(timestamp_ms);

    let len = vector::length(&container.owners);
    let mut i = 0;
    let mut found = false;

    while (i < len) {
        let owner = vector::borrow_mut(&mut container.owners, i);

        if (owner.addr == owner_addr_remove) {
            // Cannot remove self
            assert!(caller_addr != owner_addr_remove, E_CANNOT_REMOVE_SELF);

            if (owner.removed) {
                abort E_OWNER_NOT_FOUND
            };

            let old_creator = Creator {
                creator_addr: owner.creator.creator_addr,
                creator_update_addr: owner.creator.creator_update_addr,
                creator_timestamp_ms: owner.creator.creator_timestamp_ms,
                creator_update_timestamp_ms: owner.creator.creator_update_timestamp_ms,
            };

            let owner_id = object::id(owner);
            let owner_prev_id = owner.prev_id;

            let audit = OwnerAudit {
                id: object::new(ctx),
                object_id: owner_id,
                container_id: container_id,
                creator: old_creator,
                addr: owner.addr,
                role: owner.role,
                removed: owner.removed,
            };

            owner.removed = true;
            owner.creator.creator_update_addr = updater_addr;
            owner.creator.creator_update_timestamp_ms = update_timestamp_ms;

            container.owners_active_count = container.owners_active_count - 1;
            found = true;

            if (event_config_ref.event_remove) {
                let new_creator_event = CreatorEvent {
                    creator_addr: owner.creator.creator_addr,
                    creator_update_addr: updater_addr,
                    creator_timestamp_ms: owner.creator.creator_timestamp_ms,
                    creator_update_timestamp_ms: update_timestamp_ms,
                };

                event::emit(OwnerRemovedEvent {
                    object_id: owner_id,
                    container_id: container_id,
                    creator: new_creator_event,
                    addr: owner.addr,
                    role: owner.role,
                    removed: owner.removed,
                    sequence_index: owner.sequence_index,
                    prev_id: owner_prev_id,
                });
            };

            create_update_record(
                update_chain,
                container,
                container_id,
                object::id(&audit),
                caller_addr,
                timestamp_ms,
                string::utf8(b"owner_audit"),
                1,
                ctx,
            );

            create_update_record(
                update_chain,
                container,
                container_id,
                owner_id,
                caller_addr,
                timestamp_ms,
                string::utf8(b"owner"),
                2,
                ctx,
            );

            transfer::share_object(audit);

            break;
        };

        i = i + 1;
    };

    assert!(found, E_OWNER_NOT_FOUND);

    create_update_record(
        update_chain,
        container,
        container_id,
        container_id,
        caller_addr,
        timestamp_ms,
        string::utf8(b"container"),
        2,
        ctx,
    );
}

// ==========================
// UPDATE METHODS
// ==========================
public entry fun update_container(
    update_chain: &mut UpdateChain,
    container: &mut Container,
    new_external_id: string::String,
    new_name: string::String,
    new_description: string::String,
    new_content: string::String,
    new_version: string::String,
    new_schemas: string::String,
    new_apis: string::String,
    new_resources: string::String,
    new_external_index: u128,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let permission_ref = &container.permission;
    let event_config_ref = &container.event_config;
    assert_owner(container, permission_ref.public_update_container, ctx);

    let container_id = object::id(container);
    let caller_addr = sender(ctx);
    let timestamp_ms = clock.timestamp_ms();

    let old_spec = &container.specification;

    let old_spec_copy = Specification {
        version: old_spec.version,
        schemas: old_spec.schemas,
        apis: old_spec.apis,
        resources: old_spec.resources,
    };

    let old_creator_event = Creator {
        creator_addr: container.creator.creator_addr,
        creator_update_addr: container.creator.creator_update_addr,
        creator_timestamp_ms: container.creator.creator_timestamp_ms,
        creator_update_timestamp_ms: container.creator.creator_update_timestamp_ms,
    };

    let audit = ContainerAudit {
        id: object::new(ctx),
        object_id: container_id,
        container_parent_id: container.container_parent_id,
        external_id: container.external_id,
        creator: old_creator_event,
        name: container.name,
        description: container.description,
        content: container.content,
        specification: old_spec_copy,
    };

    let updater_addr = option::some(caller_addr);
    let updater_timestamp_ms = option::some(timestamp_ms);

    container.creator.creator_update_addr = updater_addr;
    container.creator.creator_update_timestamp_ms = updater_timestamp_ms;

    let spec_ref = &mut container.specification;

    container.external_id = new_external_id;
    container.name = new_name;
    container.description = new_description;
    container.content = new_content;
    container.external_index = new_external_index;

    spec_ref.version = new_version;
    spec_ref.schemas = new_schemas;
    spec_ref.apis = new_apis;
    spec_ref.resources = new_resources;

    if (event_config_ref.event_update) {
        let new_spec_event = SpecificationEvent {
            version: spec_ref.version,
            schemas: spec_ref.schemas,
            apis: spec_ref.apis,
            resources: spec_ref.resources,
        };

        let new_creator_event = CreatorEvent {
            creator_addr: container.creator.creator_addr,
            creator_update_addr: updater_addr,
            creator_timestamp_ms: container.creator.creator_timestamp_ms,
            creator_update_timestamp_ms: updater_timestamp_ms,
        };

        event::emit(ContainerUpdatedEvent {
            object_id: container_id,
            container_parent_id: container.container_parent_id,
            external_id: container.external_id,
            creator: new_creator_event,
            name: container.name,
            description: container.description,
            content: container.content,
            specification: new_spec_event,
        });
    };

    create_update_record(
        update_chain,
        container,
        container_id,
        object::id(&audit),
        caller_addr,
        timestamp_ms,
        string::utf8(b"container_audit"),
        1,
        ctx,
    );

    create_update_record(
        update_chain,
        container,
        container_id,
        container_id,
        caller_addr,
        timestamp_ms,
        string::utf8(b"container"),
        2,
        ctx,
    );

    transfer::share_object(audit);
}

public entry fun update_data_type(
    update_chain: &mut UpdateChain,
    container: &mut Container,
    data_type: &mut DataType,
    new_external_id: string::String,
    new_name: string::String,
    new_description: string::String,
    new_content: string::String,
    new_version: string::String,
    new_schemas: string::String,
    new_apis: string::String,
    new_resources: string::String,
    new_external_index: u128,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let permission_ref = &container.permission;
    let event_config_ref = &container.event_config;
    assert_owner(container, permission_ref.public_create_data_type, ctx);

    let container_id = object::id(container);
    assert!(data_type.container_id == container_id, E_INVALID_DATATYPE);

    let data_type_id = object::id(data_type);
    let caller_addr = sender(ctx);
    let timestamp_ms = clock.timestamp_ms();

    let old_spec = &data_type.specification;

    let old_spec_event = Specification {
        version: old_spec.version,
        schemas: old_spec.schemas,
        apis: old_spec.apis,
        resources: old_spec.resources,
    };

    let old_creator_event = Creator {
        creator_addr: data_type.creator.creator_addr,
        creator_update_addr: data_type.creator.creator_update_addr,
        creator_timestamp_ms: data_type.creator.creator_timestamp_ms,
        creator_update_timestamp_ms: data_type.creator.creator_update_timestamp_ms,
    };

    let audit = DataTypeAudit {
        id: object::new(ctx),
        object_id: data_type_id,
        container_id: data_type.container_id,
        external_id: data_type.external_id,
        creator: old_creator_event,
        name: data_type.name,
        description: data_type.description,
        content: data_type.content,
        specification: old_spec_event,
    };

    let updater_addr = option::some(caller_addr);
    let updater_timestamp_ms = option::some(timestamp_ms);

    data_type.creator.creator_update_addr = updater_addr;
    data_type.creator.creator_update_timestamp_ms = updater_timestamp_ms;

    let spec_ref = &mut data_type.specification;

    data_type.external_id = new_external_id;
    data_type.name = new_name;
    data_type.description = new_description;
    data_type.content = new_content;
    data_type.external_index = new_external_index;

    spec_ref.version = new_version;
    spec_ref.schemas = new_schemas;
    spec_ref.apis = new_apis;
    spec_ref.resources = new_resources;

    if (event_config_ref.event_update) {
        let new_spec_event = SpecificationEvent {
            version: spec_ref.version,
            schemas: spec_ref.schemas,
            apis: spec_ref.apis,
            resources: spec_ref.resources,
        };

        let new_creator_event = CreatorEvent {
            creator_addr: data_type.creator.creator_addr,
            creator_update_addr: updater_addr,
            creator_timestamp_ms: data_type.creator.creator_timestamp_ms,
            creator_update_timestamp_ms: updater_timestamp_ms,
        };

        event::emit(DataTypeUpdatedEvent {
            object_id: data_type_id,
            container_id: data_type.container_id,
            external_id: data_type.external_id,
            creator: new_creator_event,
            name: data_type.name,
            description: data_type.description,
            content: data_type.content,
            specification: new_spec_event,
        });
    };

    create_update_record(
        update_chain,
        container,
        container_id,
        object::id(&audit),
        caller_addr,
        timestamp_ms,
        string::utf8(b"data_type_audit"),
        1,
        ctx,
    );

    create_update_record(
        update_chain,
        container,
        container_id,
        data_type_id,
        caller_addr,
        timestamp_ms,
        string::utf8(b"data_type"),
        2,
        ctx,
    );

    transfer::share_object(audit);
}

public entry fun update_container_child_link(
    update_chain: &mut UpdateChain,
    container_child_link: &mut ContainerChildLink,
    container_parent: &mut Container,
    container_child: &mut Container,
    new_external_id: string::String,
    new_name: string::String,
    new_description: string::String,
    new_content: string::String,
    new_external_index: u128,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let container_parent_id = object::id(container_parent);
    let container_child_id = object::id(container_child);
    assert!(container_parent_id != container_child_id, E_INVALID_CONTAINER);
    assert!(container_child_link.container_parent_id == container_parent_id, E_PARENT_MISMATCH);
    assert!(container_child_link.container_child_id == container_child_id, E_CHILD_MISMATCH);
    let parent_permission_ref = &container_parent.permission;
    let child_permission_ref = &container_child.permission;
    assert_owner(container_parent, parent_permission_ref.public_attach_container_child, ctx);
    assert_owner(container_child, child_permission_ref.public_attach_container_child, ctx);

    let container_child_link_id = object::id(container_child_link);
    let caller_addr = sender(ctx);
    let timestamp_ms = clock.timestamp_ms();

    let old_creator = Creator {
        creator_addr: container_child_link.creator.creator_addr,
        creator_update_addr: container_child_link.creator.creator_update_addr,
        creator_timestamp_ms: container_child_link.creator.creator_timestamp_ms,
        creator_update_timestamp_ms: container_child_link.creator.creator_update_timestamp_ms,
    };

    let audit = ContainerChildLinkAudit {
        id: object::new(ctx),
        object_id: container_child_link_id,
        container_parent_id: container_child_link.container_parent_id,
        container_child_id: container_child_link.container_child_id,
        external_id: container_child_link.external_id,
        creator: old_creator,
        name: container_child_link.name,
        description: container_child_link.description,
        content: container_child_link.content,
    };

    let updater_addr = option::some(caller_addr);
    let updater_timestamp_ms = option::some(timestamp_ms);

    container_child_link.creator.creator_update_addr = updater_addr;
    container_child_link.creator.creator_update_timestamp_ms = updater_timestamp_ms;

    container_child_link.external_id = new_external_id;
    container_child_link.name = new_name;
    container_child_link.description = new_description;
    container_child_link.content = new_content;
    container_child_link.external_index = new_external_index;

    if (container_parent.event_config.event_update) {
        let new_creator_event = CreatorEvent {
            creator_addr: container_child_link.creator.creator_addr,
            creator_update_addr: updater_addr,
            creator_timestamp_ms: container_child_link.creator.creator_timestamp_ms,
            creator_update_timestamp_ms: updater_timestamp_ms,
        };

        event::emit(ContainerLinkUpdatedEvent {
            object_id: container_child_link_id,
            container_parent_id: container_child_link.container_parent_id,
            container_child_id: container_child_link.container_child_id,
            external_id: container_child_link.external_id,
            creator: new_creator_event,
            name: container_child_link.name,
            description: container_child_link.description,
            content: container_child_link.content,
        });
    };

    create_update_record(
        update_chain,
        container_parent,
        container_parent_id,
        object::id(&audit),
        caller_addr,
        timestamp_ms,
        string::utf8(b"container_child_link_audit"),
        1,
        ctx,
    );

    create_update_record(
        update_chain,
        container_parent,
        container_parent_id,
        container_child_link_id,
        caller_addr,
        timestamp_ms,
        string::utf8(b"container_child_link"),
        2,
        ctx,
    );

    transfer::share_object(audit);
}

public entry fun update_container_owners_active_count(
    update_chain: &mut UpdateChain,
    container: &mut Container,
    ctx: &mut TxContext,
) {
    let container_id = object::id(container);
    let permission_ref = &container.permission;
    assert_owner(container, permission_ref.public_update_container, ctx);

    let len = vector::length(&container.owners);
    let mut i = 0;
    let mut active: u32 = 0;
    while (i < len) {
        let owner = vector::borrow(&container.owners, i);
        if (!owner.removed) {
            active = active + 1;
        };
        i = i + 1;
    };

    // Defensive invariant: there must be at least one active owner
    assert!(active > 0, E_NO_ACTIVE_OWNERS);

    container.owners_active_count = active;

    // Create UpdateChainRecord for the container itself
    let creator_update = &container.creator;
    create_update_record(
        update_chain,
        container,
        container_id,
        container_id,
        creator_update.creator_addr,
        creator_update.creator_timestamp_ms,
        string::utf8(b"container"),
        2,
        ctx,
    );
}

fun create_update_record(
    update_chain: &mut UpdateChain,
    container: &mut Container,
    container_id: ID,
    object_id: ID,
    creator_addr: address,
    creator_timestamp: u64,
    object_type: string::String,
    action: u8, // 1 = CREATE, 2 = UPDATE
    ctx: &mut TxContext,
) {
    let next_index_chain = add_with_wrap(update_chain.last_update_record_index, 1);
    update_chain.last_update_record_index = next_index_chain;

    // Copy creator fields manually
    let creator_chain = Creator {
        creator_addr: creator_addr,
        creator_update_addr: option::none(),
        creator_timestamp_ms: creator_timestamp,
        creator_update_timestamp_ms: option::none(),
    };

    let record_chain = UpdateChainRecord {
        id: object::new(ctx),
        object_id: object_id,
        creator: creator_chain,
        object_type: object_type,
        action: action,
        sequence_index: next_index_chain,
        prev_id: update_chain.last_update_record_id,
    };

    update_chain.last_update_record_id = option::some(object::id(&record_chain));
    transfer::share_object(record_chain);

    let next_index_container = add_with_wrap(container.last_update_record_index, 1);
    container.last_update_record_index = next_index_container;

    let creator_container = Creator {
        creator_addr: creator_addr,
        creator_update_addr: option::none(),
        creator_timestamp_ms: creator_timestamp,
        creator_update_timestamp_ms: option::none(),
    };

    let record_container = UpdateContainerRecord {
        id: object::new(ctx),
        container_id: container_id,
        object_id: object_id,
        creator: creator_container,
        object_type: object_type,
        action: action,
        sequence_index: container.last_update_record_index,
        prev_id: container.last_update_record_id,
    };

    container.last_update_record_id = option::some(object::id(&record_container));
    transfer::share_object(record_container);
}

// ==========================
// AUTHORIZATION HELPERS
// ==========================
fun assert_owner(container: &Container, asserted: bool, ctx: &TxContext) {
    if (!asserted) {
        let caller_addr = sender(ctx);
        let len = vector::length(&container.owners);
        let mut i = 0;
        while (i < len) {
            let owner = vector::borrow(&container.owners, i);
            if (!owner.removed && owner.addr == caller_addr) {
                return // Authorized, exit early
            };
            i = i + 1;
        };

        // If we get here, no owner matched
        abort E_NOT_OWNER;
    }
}

// ==========================
// STRING AND NUMBER HELPERS
// ==========================

fun add_with_wrap(val: u128, add: u128): u128 {
    if (val > MAX_u128 - add) {
        1
    } else {
        val + add
    }
}

fun clone_vector_address(src: &vector<address>): vector<address> {
    let mut out = vector::empty<address>();
    let mut i = 0;
    let len = vector::length(src);
    while (i < len) {
        vector::push_back(&mut out, *vector::borrow(src, i));
        i = i + 1;
    };
    out
}

// Helper for addresses
public fun assert_no_duplicate_address(addrs: &vector<address>, err_code: u64) {
    let len = vector::length(addrs);
    let mut i = 0;
    while (i < len) {
        let mut j = i + 1;
        let addr_i = *vector::borrow(addrs, i);
        while (j < len) {
            let addr_j = *vector::borrow(addrs, j);
            assert!(addr_i != addr_j, err_code);
            j = j + 1;
        };
        i = i + 1;
    };
}

// Helper for IDs
public fun assert_no_duplicate_id(ids: &vector<ID>, err_code: u64) {
    let len = vector::length(ids);
    let mut i = 0;
    while (i < len) {
        let mut j = i + 1;
        let id_i = *vector::borrow(ids, i);
        while (j < len) {
            let id_j = *vector::borrow(ids, j);
            assert!(id_i != id_j, err_code);
            j = j + 1;
        };
        i = i + 1;
    };
}

/*
fun clone_vector_id(src: &vector<ID>): vector<ID> {
    let mut out = vector::empty<ID>();
    let mut i = 0;
    let len = vector::length(src);
    while (i < len) {
        vector::push_back(&mut out, *vector::borrow(src, i));
        i = i + 1;
    };
    out
}
*/
/*
public fun option_vector_address_len(option_vector_address: &Option<vector<address>>): u64 {
    if (option::is_some(option_vector_address)) {
        let vec_ref = option::borrow(option_vector_address);
        vector::length(vec_ref) as u64
    } else {
        0
    }
}*/
