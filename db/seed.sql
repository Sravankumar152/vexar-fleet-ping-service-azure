-- Local demo seed data ONLY (never run in production).
-- Gives the login/ping flow a driver to authenticate as.

INSERT INTO drivers (phone, name)
VALUES ('+15551234567', 'Demo Driver')
ON CONFLICT (phone) DO NOTHING;
