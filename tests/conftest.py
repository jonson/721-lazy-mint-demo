import pytest
from brownie import accounts


@pytest.fixture(scope="module")
def deployer():
    local = accounts.add()
    accounts[0].transfer(local, "10 ether", gas_price=0)
    return local
