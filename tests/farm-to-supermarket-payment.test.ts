import { describe, expect, it } from "vitest";
import { initSimnet } from "@hirosystems/clarinet-sdk";

const simnet = await initSimnet();
const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;
const address2 = accounts.get("wallet_2")!;

describe("Farm-to-Supermarket Payment Tests", () => {
  it("ensures simnet is well initialised", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  it("allows farmer registration", () => {
    const { result } = simnet.callPublicFn(
      "farm-to-supermarket-payment",
      "register-farmer",
      ["Green Valley Farm", "California, USA"],
      address1
    );
    expect(result).toBeOk(address1);
  });

  it("allows supermarket registration", () => {
    const { result } = simnet.callPublicFn(
      "farm-to-supermarket-payment",
      "register-supermarket",
      ["Fresh Market", "New York, USA"],
      address2
    );
    expect(result).toBeOk(address2);
  });

  it("allows order creation with escrow", () => {
    // First register both parties
    simnet.callPublicFn(
      "farm-to-supermarket-payment",
      "register-farmer",
      ["Test Farm", "Test Location"],
      address1
    );
    
    simnet.callPublicFn(
      "farm-to-supermarket-payment",
      "register-supermarket",
      ["Test Market", "Test Location"],
      address2
    );

    // Create order
    const { result } = simnet.callPublicFn(
      "farm-to-supermarket-payment",
      "create-order",
      [address1, 1000000, "Test Produce"],
      address2
    );
    expect(result).toBeOk(1);
  });

  it("allows complete order flow", () => {
    // Register parties
    simnet.callPublicFn(
      "farm-to-supermarket-payment",
      "register-farmer",
      ["Complete Farm", "Test Location"],
      address1
    );
    
    simnet.callPublicFn(
      "farm-to-supermarket-payment",
      "register-supermarket",
      ["Complete Market", "Test Location"],
      address2
    );

    // Create order
    simnet.callPublicFn(
      "farm-to-supermarket-payment",
      "create-order",
      [address1, 2000000, "Complete Test Produce"],
      address2
    );

    // Accept order
    const acceptResult = simnet.callPublicFn(
      "farm-to-supermarket-payment",
      "accept-order",
      [2],
      address1
    );
    expect(acceptResult.result).toBeOk(true);

    // Confirm delivery (this should auto-release payment)
    const deliveryResult = simnet.callPublicFn(
      "farm-to-supermarket-payment",
      "confirm-delivery",
      [2],
      address2
    );
    expect(deliveryResult.result).toBeOk(true);
  });
});
