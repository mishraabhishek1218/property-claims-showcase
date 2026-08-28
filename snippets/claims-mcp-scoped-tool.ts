// Claims-MCP tool definition (trimmed excerpt).
// Demonstrates the safety boundary described in the Architecture section:
// the conversational agent can only call purpose-built, scoped tools like
// this one — never raw database access — so it can propose but never bypass
// business rules (a fraud hold, a coverage decision, etc).

server.registerTool(
  "validate_policy",
  {
    description:
      "Verify a policy number exists and is active before starting or updating a FNOL draft. Call this as soon as the customer provides a policy number.",
    inputSchema: {
      policy_number: z
        .string()
        .describe("Policy number from the customer, e.g. POL-2025-000001"),
    },
  },
  async ({ policy_number }) => {
    try {
      const result = await validatePolicy(policy_number);
      return {
        content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        ...(result.found ? {} : { isError: true }),
      };
    } catch (error) {
      const message =
        error instanceof Error ? error.message : "Policy validation failed";
      return { isError: true, content: [{ type: "text", text: message }] };
    }
  }
);
