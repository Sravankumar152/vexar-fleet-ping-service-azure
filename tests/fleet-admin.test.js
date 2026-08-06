"use strict";

const request = require("supertest");
const { createApp } = require("../src/app");
const { signToken } = require("../src/auth");

function fakeDb(overrides = {}) {
  return {
    healthCheck: async () => true,
    query: async () => ({ rows: [] }),
    ...overrides,
  };
}

const driverToken = signToken({ driverId: 1, role: "driver" });
const adminToken = signToken({ userId: 9, role: "admin" });

describe("fleet ping ingestion", () => {
  test("rejects unauthenticated requests", async () => {
    const res = await request(createApp({ db: fakeDb() }))
      .post("/api/fleet/ping")
      .send({ vehicleId: "V1", lat: 10, lng: 20 });
    expect(res.status).toBe(401);
  });

  test("validates the body", async () => {
    const res = await request(createApp({ db: fakeDb() }))
      .post("/api/fleet/ping")
      .set("Authorization", `Bearer ${driverToken}`)
      .send({ vehicleId: "V1", lat: 999, lng: 20 }); // lat out of range
    expect(res.status).toBe(400);
  });

  test("accepts a valid ping and inserts via parameters", async () => {
    const query = jest.fn(async () => ({ rows: [] }));
    const res = await request(createApp({ db: fakeDb({ query }) }))
      .post("/api/fleet/ping")
      .set("Authorization", `Bearer ${driverToken}`)
      .send({ vehicleId: "V1", lat: 12.34, lng: 56.78, speed: 40 });
    expect(res.status).toBe(202);
    expect(query).toHaveBeenCalledTimes(1);
    // parameterised, not string-concatenated
    expect(query.mock.calls[0][1]).toEqual([
      "V1",
      12.34,
      56.78,
      40,
      expect.anything(),
    ]);
  });
});

describe("admin drivers", () => {
  test("401 without a token", async () => {
    const res = await request(createApp({ db: fakeDb() })).get(
      "/api/admin/drivers",
    );
    expect(res.status).toBe(401);
  });

  test("403 for a non-admin (driver) token", async () => {
    const res = await request(createApp({ db: fakeDb() }))
      .get("/api/admin/drivers")
      .set("Authorization", `Bearer ${driverToken}`);
    expect(res.status).toBe(403);
  });

  test("200 for an admin token", async () => {
    const query = jest.fn(async () => ({
      rows: [{ id: 1, phone: "+15551234567", name: "A", created_at: new Date() }],
    }));
    const res = await request(createApp({ db: fakeDb({ query }) }))
      .get("/api/admin/drivers")
      .set("Authorization", `Bearer ${adminToken}`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.drivers)).toBe(true);
  });
});
