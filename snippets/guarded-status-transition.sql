-- Guarded claim status transition RPC (trimmed excerpt).
-- Demonstrates: role-checked transitions, and the fraud-hold gate that blocks
-- a claim from reaching a payable status until SIU clears the hold.

if not (v_role = any(v_allowed)) then
  raise exception 'role % may not perform % -> %', v_role, v_from, p_to_status;
end if;

if p_to_status in ('approved_ready_to_pay', 'denied', 'closed', 'reopened') then
  if not can_decide_claim(p_claim_id) then
    raise exception 'not permitted to decide claim';
  end if;
  if v_role = 'supervisor' and not can_access_claim_region(v_claim.region) then
    raise exception 'claim is outside your region';
  end if;
elsif not can_edit_claim(p_claim_id) then
  raise exception 'claim is locked to the assigned user';
end if;

if (v_pre ->> 'reserve_set')::boolean is true and v_claim.reserve_amount is null then
  raise exception 'reserve must be set first';
end if;

-- The fraud hold gate: a claim cannot progress past this transition while
-- fraud_hold is true, regardless of role — SIU must clear it first.
if (v_pre ->> 'fraud_hold_cleared')::boolean is true and v_claim.fraud_hold is true then
  raise exception 'fraud hold must be cleared first';
end if;

if (
  (v_pre ->> 'payments_fully_settled')::boolean is true
  or (v_pre ->> 'payment_settled')::boolean is true
) and not claim_payments_fully_settled(p_claim_id) then
  raise exception 'settled payments must equal or exceed reserve before closing';
end if;
