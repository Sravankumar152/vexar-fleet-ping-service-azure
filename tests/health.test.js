"use strict";

const request = require("supertest");
const { createApp } = require("../src/app");

describe("health endpoints", () => {
  test("GET /healthz is always ok (no DB dependency)", async () => {
    const db = { healthCheck: async () => true, query: async () => ({ rows: [] }) };
    const res = await request(createApp({ db })).get("/healthz");
    expect(res.status).toBe(200);
    expect(res.body.status).toBe("ok");
  });

  test("GET /readyz returns 200 when the DB is reachable", async () => {
    const db = { healthCheck: async () => true, query: async () => ({ rows: [] }) };
    const res = await request(createApp({ db })).get("/readyz");
    expect(res.status).toBe(200);
    expect(res.body.status).toBe("ready");
  });

  test("GET /readyz returns 503 when the DB check fails", async () => {
    const db = {
      healthCheck: async () => {
        throw new Error("db down");
      },
      query: async () => ({ rows: [] }),
    };
    const res = await request(createApp({ db })).get("/readyz");
    expect(res.status).toBe(503);
    expect(res.body.status).toBe("not ready");
  });
});
