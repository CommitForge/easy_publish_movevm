module easy_publish::follow_container {

    use std::vector;
    use std::table::{Table, new, add, borrow_mut, borrow, contains};

    /// Registry resource: tracks many addresses -> vector<Container ID>
    struct AddressContainerRegistry has key {
        map: Table<address, vector<ID>>,
    }

    /// Initialize registry (per account)
    public entry fun init_registry(owner: &signer) {
        if (!exists<AddressContainerRegistry>(signer::address_of(owner))) {
            move_to(owner, AddressContainerRegistry { map: new<address, vector<ID>>() });
        }
    }

    /// Add a container for an address (no duplicates)
    public entry fun add_container(owner: &signer, user: address, container_id: ID) acquires AddressContainerRegistry {
        let registry = borrow_global_mut<AddressContainerRegistry>(signer::address_of(owner));

        if (!contains(&registry.map, user)) {
            add(&mut registry.map, user, vector::empty<ID>());
        }

        let containers = borrow_mut(&mut registry.map, user);

        // push only if not present
        if (!vector::contains(containers, container_id)) {
            vector::push_back(containers, container_id);
        }
    }

    /// Remove a container for an address
    public entry fun remove_container(owner: &signer, user: address, container_id: ID) acquires AddressContainerRegistry {
        let registry = borrow_global_mut<AddressContainerRegistry>(signer::address_of(owner));

        if (contains(&registry.map, user)) {
            let containers = borrow_mut(&mut registry.map, user);

            let mut i = 0;
            while (i < vector::length(containers)) {
                if (vector::borrow(containers, i) == &container_id) {
                    vector::swap_remove(containers, i); // remove efficiently
                } else {
                    i = i + 1;
                }
            }
        }
    }

    /// Get containers for an address
    public fun get_containers(owner_addr: address, user: address): vector<ID> acquires AddressContainerRegistry {
        if (exists<AddressContainerRegistry>(owner_addr)) {
            let registry = borrow_global<AddressContainerRegistry>(owner_addr);
            if (contains(&registry.map, user)) {
                borrow(&registry.map, user)
            } else {
                vector::empty<ID>()
            }
        } else {
            vector::empty<ID>()
        }
    }
}
