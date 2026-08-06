"use strict";

// Deterministic env for tests — never touches a real database or secret store.
process.env.NODE_ENV = "test";
process.env.JWT_SECRET = "test-secret";
process.env.LOG_LEVEL = "silent";
process.env.RATE_LIMIT_MAX = "1000";
