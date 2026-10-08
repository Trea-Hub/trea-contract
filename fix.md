Description: Add a function to check whether a given address is registered for a given event, without needing to know internal storage keys.
Acceptance Criteria:

is_registered(env: Env, event_id: u32, attendee: Address) -> bool is added
Returns false (not a panic) when no registration exists
Test covers both registered and unregistered cases