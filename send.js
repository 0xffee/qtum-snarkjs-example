const { QtumRPC } = require('qtumjs')
const argv = require('argv')

function parseArgv() {
    argv.option([
        {
            name: 'rpcuser',
            type: 'string',
            description: 'Username for JSON-RPC connections of Qtum',
        },
        {
            name: 'rpcpassword',
            type: 'string',
            description: 'Password for JSON-RPC connections of Qtum',
        },
        {
            name: 'rpcport',
            type: 'string',
            description: 'Port for JSON-RPC connections of Qtum',
        },
        {
            name: 'gas',
            type: 'float',
            description: 'Gas used to pay the transaction',
        },
        {
            name: 'msg',
            type: 'string',
            description: 'Message to be sent, no more than 80 byte',
        },
    ])
    let defaultOptions = {
        rpcuser: 'qtum',
        rpcpassword: 'regtest',
        rpcport: '3889',
        gas: 0.1
    }
    let args = argv.run()
    let options = Object.assign(defaultOptions, args.options)

    // check msg
    if (!options.msg) {
        console.log('Message must be set')
        return
    }
    options.msgHexStr = strToHexStr(options.msg)
    if ((options.msgHexStr.length / 2) > 80) {
        console.log('Message must be no more than 80 byte')
        return
    }

    return options
}

function connectQtum(options) {
    let url = 'http://' + options.rpcuser + ':' + options.rpcpassword + '@172.17.0.2:' + options.rpcport
    return new QtumRPC(url)
}

function strToHexStr(str) {
    return Buffer.from(str).toString('hex')
}

async function getUtxo(rpc, gas) {
    let list = await rpc.rawCall('listunspent')
    for (let i = 0; i < list.length; i++) {
        let utxo = list[i];
        if (utxo.amount > gas) {
            // console.log('Use UTXO:\n%o', utxo)
            return utxo;
        }
    }

    console.log('No UTXO avaliable')
    return null
}

function getChange(amount, gas) {
    return (amount * 1e8 - gas * 1e8) / 1e8
}

async function createTransaction(rpc, msg, gas, utxo, changeAddress) {
    let data = [
        [{ 'txid': utxo.txid, 'vout': utxo.vout }],
        { 'data': msg, [changeAddress]: getChange(utxo.amount, gas) }
    ]
    // console.log('Transaction parameters are:\n%o', data)

    return await rpc.rawCall('createrawtransaction', data)
}

async function send(rpc, options) {
    let utxo = await getUtxo(rpc, options.gas)
    let changeAddress = await rpc.rawCall('getrawchangeaddress')
    let rawTransaction = await createTransaction(rpc, options.msgHexStr, options.gas, utxo, changeAddress)
    rawTransaction = await rpc.rawCall('signrawtransaction', [rawTransaction])
    await rpc.rawCall('sendrawtransaction', [rawTransaction.hex])
    return await rpc.rawCall('decoderawtransaction', [rawTransaction.hex])
}

async function run() {
    // parse args
    const options = parseArgv()
    if (options === undefined) {
        console.log('Use -h to get a help about needed args')
        return
    }
    console.log('Options are:\n%o', options)

    // connect to Qtum
    const rpc = connectQtum(options)
    // console.log('Qtum RPC is:\n%o', rpc)

    // send message
    const transaction = await send(rpc, options)
    console.log('Transaction is:\n%o', transaction.txid)
}

run().then()