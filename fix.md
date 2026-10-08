Description: Multiple functions repeat env.storage().persistent().get(&DataKey::Event(event_id)).unwrap(). Extract this into a small private helper function with a clear error message.
Acceptance Criteria:

A private fn load_event(env: &Env, event_id: u32) -> Event helper is added and used everywhere applicable
Error message is more descriptive than the default unwrap panic
Tests still pass unchanged