const express = require('express');
const bodyParser = require('body-parser');
const { ApiPromise, WsProvider } = require('@polkadot/api');
const { Keyring } = require('@polkadot/keyring');
const { ContractPromise } = require('@polkadot/api-contract');
const fs = require('fs');

const app = express();
const port = 3000;

app.use(bodyParser.json());

// In-memory storage for tracking clicks
const userClicks = {};

// Polkadot API setup
let api;
let contract;
const contractAddress = '5GqMzDdKrDdusKuULfjbuxFZYKKYS8xUe1JQFELfjUy8wkhJ';
const contractAbi = JSON.parse(fs.readFileSync('../ad_contract.json', 'utf8'));

async function setupPolkadot() {
    try {
        const wsProvider = new WsProvider('wss://rococo-contracts-rpc.polkadot.io');
        api = await ApiPromise.create({ provider: wsProvider });

        await api.isReady;

        contract = new ContractPromise(api, contractAbi, contractAddress);
        console.log('Polkadot API and Contract initialized');
    } catch (error) {
        console.error('Failed to initialize Polkadot API:', error);
        process.exit(1);
    }
}

// Function to call smart contract for reward
async function rewardAdvertiser(adAddress, rewardAddress) {
    if (!api || !contract) {
        throw new Error('Polkadot API or Contract not initialized');
    }

    const keyring = new Keyring({ type: 'sr25519' });
    const caller = keyring.addFromUri('zone october fashion treat near canal slide zoo grab barrel phone waste');

    try {
        const gasLimit = api.registry.createType('WeightV2', {
            refTime: 1000000000n,
            proofSize: 50000n,
        });

        // Query the contract first
        const { result, output } = await contract.query.reward(caller.address, {
            gasLimit,
            storageDepositLimit: null,
        }, adAddress, rewardAddress);

        if (result.isErr) {
            console.error('Query failed:', result.asErr.toHuman());
            throw new Error(`Query failed: ${result.asErr.toHuman()}`);
        }

        console.log('Query successful:', output.toHuman());

        // Send the actual transaction
        return new Promise((resolve, reject) => {
            contract.tx
                .reward({ gasLimit }, adAddress, rewardAddress)
                .signAndSend(caller, ({ status, events }) => {
                    if (status.isInBlock) {
                        console.log('Transaction included at blockHash', status.asInBlock.toHex());
                        resolve({ success: true, status: 'inBlock', blockHash: status.asInBlock.toHex() });
                    } else if (status.isFinalized) {
                        console.log('Transaction finalized at blockHash', status.asFinalized.toHex());
                        resolve({ success: true, status: 'finalized', blockHash: status.asFinalized.toHex() });
                    } else if (status.isError) {
                        console.error('Transaction error');
                        reject({ success: false, error: 'Transaction error' });
                    }
                })
                .catch((error) => {
                    console.error('Error:', error);
                    reject({ success: false, error: error.toString() });
                });
        });
    } catch (error) {
        console.error('Error rewarding advertiser:', error);
        return { success: false, error: error.message };
    }
}

// Click route
app.post('/click', (req, res) => {
    const { username, advertismentaddress, rewardaddress } = req.body;
    if (!username || !advertismentaddress || !rewardaddress) {
        return res.status(400).json({ error: 'Invalid input data' });
    }
    // Record the click
    userClicks[username] = {
        advertismentaddress,
        rewardaddress,
        clickedAt: new Date().toISOString(),
    };
    return res.status(200).json({ message: 'Click recorded' });
});

// Reward route
app.post('/reward', async (req, res) => {
    const { username } = req.body;
    if (!username) {
        return res.status(400).json({ error: 'Invalid input data' });
    }
    // Check if the user has clicked earlier
    if (!userClicks[username]) {
        return res.status(404).json({ error: 'User has not clicked earlier' });
    }

    try {
        const rewardResult = await rewardAdvertiser(
            userClicks[username].advertismentaddress,
            userClicks[username].rewardaddress
        );

        if (rewardResult.success) {
            return res.status(200).json({
                message: `Advertiser rewarded for user ${username}.`,
                txHash: rewardResult.txHash,
                status: rewardResult.status
            });
        } else {
            return res.status(500).json({ error: 'Failed to reward advertiser', details: rewardResult.error });
        }
    } catch (error) {
        return res.status(500).json({ error: 'Failed to reward advertiser', details: error.message });
    }
});

// Initialize Polkadot API before starting the server
setupPolkadot()
    .then(() => {
        app.listen(port, () => {
            console.log(`Server is running on port ${port}`);
        });
    })
    .catch(error => {
        console.error('Failed to initialize Polkadot API:', error);
        process.exit(1);
    });
