"use strict";

const request = require("supertest");
const { createApp } = require("../src/app");

function fakeDb(overrides = {}) {
  return {
    healthCheck: async () => true,
    query: async () => ({ rows: [] }),
    ...overrides,
  };
}

describe("auth", () => {
  test("request-otp rejects an invalid phone number", async () => {
    const res = await request(createApp({ db: fakeDb() }))
      .post("/api/auth/request-otp")
      .send({ phone: "not-a-phone" });
    expect(res.status).toBe(400);
    expect(res.body.error).toBe("validation failed");
  });

  test("request-otp accepts a valid phone", async () => {
    const res = await request(createApp({ db: fakeDb() }))
      .post("/api/auth/request-otp")
      .send({ phone: "+15551234567" });
    expect(res.status).toBe(202);
  });

  test("login requires phone and otp", async () => {
    const res = await request(createApp({ db: fakeDb() }))
      .post("/api/auth/login")
      .send({ phone: "+15551234567" });
    expect(res.status).toBe(400);
  });

  test("login returns 401 when the OTP is wrong (no OTP on record)", async () => {
    // driver_otps lookup returns nothing -> verification fails.
    const res = await request(createApp({ db: fakeDb() }))
      .post("/api/auth/login")
      .send({ phone: "+15551234567", otp: "000000" });
    expect(res.status).toBe(401);
  });

  test("login is not vulnerable to SQL injection via phone (rejected at validation)", async () => {
    const query = jest.fn(async () => ({ rows: [] }));
    const res = await request(createApp({ db: fakeDb({ query }) }))
      .post("/api/auth/login")
      .send({ phone: "' OR '1'='1", otp: "123456" });
    expect(res.status).toBe(400); // never reaches the DB
    expect(query).not.toHaveBeenCalled();
  });
});
