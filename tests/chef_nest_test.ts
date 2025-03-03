import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test session lifecycle",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('chef-nest', 'create-session', 
        [types.ascii("Italian Night"), types.principal(deployer.address)],
        deployer.address
      ),
      Tx.contractCall('chef-nest', 'end-session',
        [types.uint(1)],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 2);
    block.receipts[0].result.expectOk().expectUint(1);
    block.receipts[1].result.expectOk();
    
    const response = chain.callReadOnlyFn(
      'chef-nest',
      'get-session',
      [types.uint(1)],
      deployer.address
    );
    
    const session = response.result.expectSome().expectTuple();
    assertEquals(session['active'], types.bool(false));
  }
});

// [Previous test cases remain unchanged...]

Clarinet.test({
  name: "Test recipe voting",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('chef-nest', 'create-session',
        [types.ascii("Italian Night"), types.principal(deployer.address)],
        deployer.address
      ),
      Tx.contractCall('chef-nest', 'join-session',
        [types.uint(1), types.principal(wallet1.address)],
        wallet1.address
      ),
      Tx.contractCall('chef-nest', 'add-recipe',
        [
          types.uint(1),
          types.ascii("Pasta Carbonara"),
          types.utf8("Cook pasta, mix with eggs and cheese...")
        ],
        deployer.address
      ),
      Tx.contractCall('chef-nest', 'vote-recipe',
        [types.uint(1), types.uint(1)],
        wallet1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 4);
    block.receipts[3].result.expectOk();
    
    const response = chain.callReadOnlyFn(
      'chef-nest',
      'get-recipe',
      [types.uint(1), types.uint(1)],
      deployer.address
    );
    
    const recipe = response.result.expectSome().expectTuple();
    assertEquals(recipe['votes'], types.uint(1));
  }
});
