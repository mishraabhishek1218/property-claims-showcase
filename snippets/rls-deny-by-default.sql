-- Row-Level Security posture (trimmed excerpt).
-- Every table is deny-by-default; customers never reach a claim via direct
-- anon SELECT (only through a PIN-scoped RPC running as service-role).
-- Internal access is role-based off the JWT claim.

alter table claims              enable row level security;
alter table payments            enable row level security;
alter table fraud_alerts        enable row level security;

create policy claims_staff_read on claims for select using (is_staff());

create policy claims_owner_or_supervisor_update on claims for update
  using (is_staff() and (owner_id = auth.uid()
         or auth_role() in ('supervisor','admin','intake_agent')))
  with check (is_staff());
