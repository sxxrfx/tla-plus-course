---------------- MODULE InventoryInd ----------------
EXTENDS Inventory
SafeOnly == TypeOK /\ NoOverselling
Strong == TypeOK /\ Conservation
=====================================================
