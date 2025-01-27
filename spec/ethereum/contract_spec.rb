require 'spec_helper'
require 'eth'

describe EvmClient::Contract do

  class MockClient < EvmClient::Client
    def default_account() "0x27dcb234fab8190e53e2d949d7b2c37411efb72e" end
    def gas_price() nil end
    def gas_limit() nil end
    def net_version() {"jsonrpc"=>"2.0", "id"=>1, "result"=>"1234"} end
  end

  let(:client) { MockClient.new }
  let(:address) { "0xaf83b6f1162062aa6711de633821f3e66b6fb3a5" }
  let(:abi) { '[{"constant":false,"inputs":[],"name":"kill","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"greet","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"inputs":[{"name":"_greeting","type":"string"}],"payable":false,"type":"constructor"}]' }
  let(:code) { '606060405234610000576040516102c13803806102c1833981016040528051015b5b60008054600160a060020a03191633600160a060020a03161790555b8060019080519060200190828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f1061008957805160ff19168380011785556100b6565b828001600101855582156100b6579182015b828111156100b657825182559160200191906001019061009b565b5b506100d79291505b808211156100d357600081556001016100bf565b5090565b50505b505b6101d6806100eb6000396000f300606060405263ffffffff60e060020a60003504166341c0e1b5811461002f578063cfae32171461003e575b610000565b346100005761003c6100cb565b005b346100005761004b61010d565b604080516020808252835181830152835191928392908301918501908083838215610091575b80518252602083111561009157601f199092019160209182019101610071565b505050905090810190601f1680156100bd5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b6000543373ffffffffffffffffffffffffffffffffffffffff9081169116141561010a5760005473ffffffffffffffffffffffffffffffffffffffff16ff5b5b565b604080516020808201835260008252600180548451600282841615610100026000190190921691909104601f81018490048402820184019095528481529293909183018282801561019f5780601f106101745761010080835404028352916020019161019f565b820191906000526020600020905b81548152906001019060200180831161018257829003601f168201915b505050505090505b905600a165627a7a72305820293955f201e1545746c248227c00553ddded3cab3195c1f640197fc52fb562600029' }
  let(:contract) { EvmClient::Contract.create(name: "Greeter", code: code, abi: abi, client: client, address: address) }
  let(:eth_send_result) { '{"jsonrpc":"2.0", "result": "", "id": 1}' }
  let(:insufficient_funds_result) { '{"jsonrpc":"2.0","error":{"code":-32010,"message":"Insufficient funds. The account you tried to send transaction from does not have enough funds.","data":null},"id":1}' }

  shared_examples "communicate with node" do |expected|
    it "communicate with node" do
      expect(client).to receive(:send_single).once.with(eth_send_request).and_return(eth_send_result)
      subject
    end
  end

  context "estimate" do
    let(:create_contract_request) { '{"jsonrpc":"2.0","method":"eth_estimateGas","params":[{"from":"0x27dcb234fab8190e53e2d949d7b2c37411efb72e","data":"0x606060405234610000576040516102c13803806102c1833981016040528051015b5b60008054600160a060020a03191633600160a060020a03161790555b8060019080519060200190828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f1061008957805160ff19168380011785556100b6565b828001600101855582156100b6579182015b828111156100b657825182559160200191906001019061009b565b5b506100d79291505b808211156100d357600081556001016100bf565b5090565b50505b505b6101d6806100eb6000396000f300606060405263ffffffff60e060020a60003504166341c0e1b5811461002f578063cfae32171461003e575b610000565b346100005761003c6100cb565b005b346100005761004b61010d565b604080516020808252835181830152835191928392908301918501908083838215610091575b80518252602083111561009157601f199092019160209182019101610071565b505050905090810190601f1680156100bd5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b6000543373ffffffffffffffffffffffffffffffffffffffff9081169116141561010a5760005473ffffffffffffffffffffffffffffffffffffffff16ff5b5b565b604080516020808201835260008252600180548451600282841615610100026000190190921691909104601f81018490048402820184019095528481529293909183018282801561019f5780601f106101745761010080835404028352916020019161019f565b820191906000526020600020905b81548152906001019060200180831161018257829003601f168201915b505050505090505b905600a165627a7a72305820293955f201e1545746c248227c00553ddded3cab3195c1f640197fc52fb562600029000000000000000000000000000000000000000000000000000000000000002548656c6c6f000000000000000000000000000000000000000000000000000000"}],"id":1}' }
    let(:create_contract_response) { '{"jsonrpc":"2.0","result":"0x3e240","id":1}' }
    it "estimate" do
      expect(client).to receive(:send_single).once.with(create_contract_request).and_return(create_contract_response)
      expect(contract.estimate("Hello")).to eq 254528
    end

    it "rises if wrong number of args for constructor" do
      expect{ contract.estimate("arg", "extra arg") }.to raise_error(ArgumentError, "Wrong number of arguments in a constructor")
    end

  end

  context "deploy" do
    let(:create_contract_request)                 { '{"jsonrpc":"2.0","method":"eth_sendTransaction","params":[{"from":"0x27dcb234fab8190e53e2d949d7b2c37411efb72e","data":"0x606060405234610000576040516102c13803806102c1833981016040528051015b5b60008054600160a060020a03191633600160a060020a03161790555b8060019080519060200190828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f1061008957805160ff19168380011785556100b6565b828001600101855582156100b6579182015b828111156100b657825182559160200191906001019061009b565b5b506100d79291505b808211156100d357600081556001016100bf565b5090565b50505b505b6101d6806100eb6000396000f300606060405263ffffffff60e060020a60003504166341c0e1b5811461002f578063cfae32171461003e575b610000565b346100005761003c6100cb565b005b346100005761004b61010d565b604080516020808252835181830152835191928392908301918501908083838215610091575b80518252602083111561009157601f199092019160209182019101610071565b505050905090810190601f1680156100bd5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b6000543373ffffffffffffffffffffffffffffffffffffffff9081169116141561010a5760005473ffffffffffffffffffffffffffffffffffffffff16ff5b5b565b604080516020808201835260008252600180548451600282841615610100026000190190921691909104601f81018490048402820184019095528481529293909183018282801561019f5780601f106101745761010080835404028352916020019161019f565b820191906000526020600020905b81548152906001019060200180831161018257829003601f168201915b505050505090505b905600a165627a7a72305820293955f201e1545746c248227c00553ddded3cab3195c1f640197fc52fb562600029000000000000000000000000000000000000000000000000000000000000002548656c6c6f000000000000000000000000000000000000000000000000000000"}],"id":1}' }
    let(:create_contract_request_with_custom_gas) { '{"jsonrpc":"2.0","method":"eth_sendTransaction","params":[{"from":"0x27dcb234fab8190e53e2d949d7b2c37411efb72e","data":"0x606060405234610000576040516102c13803806102c1833981016040528051015b5b60008054600160a060020a03191633600160a060020a03161790555b8060019080519060200190828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f1061008957805160ff19168380011785556100b6565b828001600101855582156100b6579182015b828111156100b657825182559160200191906001019061009b565b5b506100d79291505b808211156100d357600081556001016100bf565b5090565b50505b505b6101d6806100eb6000396000f300606060405263ffffffff60e060020a60003504166341c0e1b5811461002f578063cfae32171461003e575b610000565b346100005761003c6100cb565b005b346100005761004b61010d565b604080516020808252835181830152835191928392908301918501908083838215610091575b80518252602083111561009157601f199092019160209182019101610071565b505050905090810190601f1680156100bd5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b6000543373ffffffffffffffffffffffffffffffffffffffff9081169116141561010a5760005473ffffffffffffffffffffffffffffffffffffffff16ff5b5b565b604080516020808201835260008252600180548451600282841615610100026000190190921691909104601f81018490048402820184019095528481529293909183018282801561019f5780601f106101745761010080835404028352916020019161019f565b820191906000526020600020905b81548152906001019060200180831161018257829003601f168201915b505050505090505b905600a165627a7a72305820293955f201e1545746c248227c00553ddded3cab3195c1f640197fc52fb562600029000000000000000000000000000000000000000000000000000000000000002548656c6c6f000000000000000000000000000000000000000000000000000000","gasPrice":"0xabe0"}],"id":1}' }
    let(:create_contract_request_with_gas_limit)  { '{"jsonrpc":"2.0","method":"eth_sendTransaction","params":[{"from":"0x27dcb234fab8190e53e2d949d7b2c37411efb72e","data":"0x606060405234610000576040516102c13803806102c1833981016040528051015b5b60008054600160a060020a03191633600160a060020a03161790555b8060019080519060200190828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f1061008957805160ff19168380011785556100b6565b828001600101855582156100b6579182015b828111156100b657825182559160200191906001019061009b565b5b506100d79291505b808211156100d357600081556001016100bf565b5090565b50505b505b6101d6806100eb6000396000f300606060405263ffffffff60e060020a60003504166341c0e1b5811461002f578063cfae32171461003e575b610000565b346100005761003c6100cb565b005b346100005761004b61010d565b604080516020808252835181830152835191928392908301918501908083838215610091575b80518252602083111561009157601f199092019160209182019101610071565b505050905090810190601f1680156100bd5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b6000543373ffffffffffffffffffffffffffffffffffffffff9081169116141561010a5760005473ffffffffffffffffffffffffffffffffffffffff16ff5b5b565b604080516020808201835260008252600180548451600282841615610100026000190190921691909104601f81018490048402820184019095528481529293909183018282801561019f5780601f106101745761010080835404028352916020019161019f565b820191906000526020600020905b81548152906001019060200180831161018257829003601f168201915b505050505090505b905600a165627a7a72305820293955f201e1545746c248227c00553ddded3cab3195c1f640197fc52fb562600029000000000000000000000000000000000000000000000000000000000000002548656c6c6f000000000000000000000000000000000000000000000000000000","gas":"0xabe0"}],"id":1}' }
    let(:create_contract_response)                { '{"jsonrpc":"2.0","result":"0x8f27c18ef7c9070884e6a0953be7611b2ab5958e7043398200dc6a6707a2bd4a","id":1}' }
    let(:create_contract_failed_response)         { '{"jsonrpc":"2.0","result":"0x","id":1}' }

    it "async" do
      expect(client).to receive(:send_single).once.with(create_contract_request).and_return(create_contract_response)
      expect(contract.deploy("Hello").id).to eq "0x8f27c18ef7c9070884e6a0953be7611b2ab5958e7043398200dc6a6707a2bd4a"
    end

    it "async with locked account" do
      expect(client).to receive(:send_single).once.with(create_contract_request).and_return(create_contract_failed_response)
      expect{ contract.deploy("Hello") }.to raise_error(IOError, "Failed to deploy, did you unlock 0x27dcb234fab8190e53e2d949d7b2c37411efb72e account? Transaction hash: 0x")
    end

    it "async with insufficient funds" do
      expect(client).to receive(:send_single).once.with(create_contract_request).and_return(insufficient_funds_result)
      expect{ contract.deploy("Hello") }.to raise_error(IOError, "Insufficient funds. The account you tried to send transaction from does not have enough funds.")
    end

    it "async with custom gas price" do
      expect(client).to receive(:send_single).once.with(create_contract_request_with_custom_gas).and_return(create_contract_response)
      contract.gas_price = 44000
      expect(contract.deploy("Hello").id).to eq "0x8f27c18ef7c9070884e6a0953be7611b2ab5958e7043398200dc6a6707a2bd4a"
    end

    it "async with custom gas limit" do
      expect(client).to receive(:send_single).once.with(create_contract_request_with_gas_limit).and_return(create_contract_response)
      contract.gas_limit = 44000
      expect(contract.deploy("Hello").id).to eq "0x8f27c18ef7c9070884e6a0953be7611b2ab5958e7043398200dc6a6707a2bd4a"
    end

    let(:transaction_receipt_request) { '{"jsonrpc":"2.0","method":"eth_getTransactionReceipt","params":["0x8f27c18ef7c9070884e6a0953be7611b2ab5958e7043398200dc6a6707a2bd4a"],"id":1}' }
    let(:transaction_receipt_response) { '{"jsonrpc":"2.0","result":{"blockHash":"0xc46f34137d2f6efb28b223527d30c6795a90e6d739327ee149e59da0bb135e18","blockNumber":"0x59b99","contractAddress":"0xb208cc15cb01ec6ac37eeeadb7847eacee706c47","cumulativeGasUsed":"0x179583","gasUsed":"0xe57e0","logs":[],"logsBloom":"0x","root":"0x9e6c00714e4fe68e97c6ca7db35981e266b83c360782d92783a4ebf93da6eae1","transactionHash":"0x8f27c18ef7c9070884e6a0953be7611b2ab5958e7043398200dc6a6707a2bd4a","transactionIndex":"0x9"},"id":1}' }
    it "sync" do
      expect(client).to receive(:send_single).once.with(create_contract_request).and_return(create_contract_response)
      expect(client).to receive(:send_single).once.with(transaction_receipt_request).and_return(transaction_receipt_response)
      expect(contract.deploy_and_wait("Hello", step: 0)).to eq "0xb208cc15cb01ec6ac37eeeadb7847eacee706c47"
    end

    it "rises if wrong number of args for constructor" do
      expect{ contract.deploy("arg", "extra arg") }.to raise_error(ArgumentError, "Wrong number of arguments in a constructor")
    end

  end

  context "transact" do
    let(:eth_send_request) { '{"jsonrpc":"2.0","method":"eth_sendTransaction","params":[{"to":"0xaf83b6f1162062aa6711de633821f3e66b6fb3a5","from":"0x27dcb234fab8190e53e2d949d7b2c37411efb72e","data":"0x41c0e1b5"}],"id":1}' }
    let(:eth_send_result) { '{"jsonrpc":"2.0","result":"0x2736d20b6e8698225c298fba56a90c0c6e95699f95e9c0b13909a730ea438623","id":1}' }
    subject { expect(contract.transact.kill.id).to eq '0x2736d20b6e8698225c298fba56a90c0c6e95699f95e9c0b13909a730ea438623' }
    it_behaves_like "communicate with node"
  end

  context "transact with custom gas" do
    let(:eth_send_request) { '{"jsonrpc":"2.0","method":"eth_sendTransaction","params":[{"to":"0xaf83b6f1162062aa6711de633821f3e66b6fb3a5","from":"0x27dcb234fab8190e53e2d949d7b2c37411efb72e","data":"0x41c0e1b5","gas":"0xabe0"}],"id":1}' }
    let(:eth_send_result) { '{"jsonrpc":"2.0","result":"0x2736d20b6e8698225c298fba56a90c0c6e95699f95e9c0b13909a730ea438623","id":1}' }
    it "communicate with node" do
      expect(client).to receive(:send_single).once.with(eth_send_request).and_return(eth_send_result)
      contract.gas_limit = 44000
      expect(contract.transact.kill.id).to eq '0x2736d20b6e8698225c298fba56a90c0c6e95699f95e9c0b13909a730ea438623'
    end
  end

  context "transact with custom gas price" do
    let(:eth_send_request) { '{"jsonrpc":"2.0","method":"eth_sendTransaction","params":[{"to":"0xaf83b6f1162062aa6711de633821f3e66b6fb3a5","from":"0x27dcb234fab8190e53e2d949d7b2c37411efb72e","data":"0x41c0e1b5","gasPrice":"0xabe0"}],"id":1}' }
    let(:eth_send_result) { '{"jsonrpc":"2.0","result":"0x2736d20b6e8698225c298fba56a90c0c6e95699f95e9c0b13909a730ea438623","id":1}' }
    it "communicate with node" do
      expect(client).to receive(:send_single).once.with(eth_send_request).and_return(eth_send_result)
      contract.gas_price = 44000
      expect(contract.transact.kill.id).to eq '0x2736d20b6e8698225c298fba56a90c0c6e95699f95e9c0b13909a730ea438623'
    end
  end

  context "transact with insufficient funds" do
    let(:eth_send_request) { '{"jsonrpc":"2.0","method":"eth_sendTransaction","params":[{"to":"0xaf83b6f1162062aa6711de633821f3e66b6fb3a5","from":"0x27dcb234fab8190e53e2d949d7b2c37411efb72e","data":"0x41c0e1b5"}],"id":1}' }
    it "communicate with node" do
      expect(client).to receive(:send_single).once.with(eth_send_request).and_return(insufficient_funds_result)
      expect{ contract.transact.kill }.to raise_error(IOError, "Insufficient funds. The account you tried to send transaction from does not have enough funds.")
    end
  end

  context "transact_and_wait" do
    let(:eth_send_request) { '{"jsonrpc":"2.0","method":"eth_sendTransaction","params":[{"to":"0xaf83b6f1162062aa6711de633821f3e66b6fb3a5","from":"0x27dcb234fab8190e53e2d949d7b2c37411efb72e","data":"0x41c0e1b5"}],"id":1}' }
    let(:eth_get_transaction_request) { '{"jsonrpc":"2.0","method":"eth_getTransactionByHash","params":[""],"id":1}' }
    let(:eth_get_transaction_result) { '{"jsonrpc":"2.0","result":{"blockHash":"0xc1e5032da79990789fb6933d31fb5670e66aec1e88fa98efbc1c9d4507c070ab","blockNumber":"0x56893","creates":null,"from":"0x27dcb234fab8190e53e2d949d7b2c37411efb72e","gas":"0xe57e0","gasPrice":"0x4a817c800","hash":"0x528b3c18433ea9b9089f0eef1f5be722934e629e441fa1af07f33531b20c22c9","input":"0x41c0e1b5","nonce":"0x25","publicKey":"0xccfdb8fdcf107fa9aa3fbaef7bc33c97685a7ab61f9cbef8e510fff848930b444e0ae2e66b27326b95cab0ff070c1db793f396c646ae2cb17ad539f41af23099","r":"0x07139d16062f86f003836a6b41ff2fba5c8988daa745c44cddeb807f7c5dee5e","raw":"0xf869258504a817c800830e57e0945b1141d29fad616d221fff559dcaa11bbb2ebcb7808441c0e1b52aa007139d16062f86f003836a6b41ff2fba5c8988daa745c44cddeb807f7c5dee5ea0415b0bdbc6bee69a8e6518abe914ae29a4f0a4a23f7aa9683f4fe5b16bafc0d9","s":"0x415b0bdbc6bee69a8e6518abe914ae29a4f0a4a23f7aa9683f4fe5b16bafc0d9","to":"0x5b1141d29fad616d221fff559dcaa11bbb2ebcb7","transactionIndex":"0x3","v":1,"value":"0x0"},"id":1}' }
    it "communicate with node" do
      expect(client).to receive(:send_single).once.with(eth_send_request).and_return(eth_send_result)
      expect(client).to receive(:send_single).once.with(eth_get_transaction_request).and_return(eth_get_transaction_result)
      contract.transact_and_wait.kill
    end
  end

  context "current block" do
    describe "#call" do
      let(:eth_send_request) { '{"jsonrpc":"2.0","method":"eth_call","params":[{"to":"0xaf83b6f1162062aa6711de633821f3e66b6fb3a5","from":"0x27dcb234fab8190e53e2d949d7b2c37411efb72e","data":"0xcfae3217"},"latest"],"id":1}' }
      let(:eth_send_result) { '{"jsonrpc":"2.0", "result": "0x0000000000000000000000000000000000000000000000000000000000000023616c610000000000000000000000000000000000000000000000000000000000", "id": 1}' }
      subject { expect(contract.call.greet).to eq "ala" }
      it_behaves_like "communicate with node"
    end

    describe "#call_raw" do
      let(:eth_send_request) { '{"jsonrpc":"2.0","method":"eth_call","params":[{"to":"0xaf83b6f1162062aa6711de633821f3e66b6fb3a5","from":"0x27dcb234fab8190e53e2d949d7b2c37411efb72e","data":"0xcfae3217"},"latest"],"id":1}' }
      let(:eth_send_result) { '{"jsonrpc":"2.0", "result": "0x0000000000000000000000000000000000000000000000000000000000000023616c610000000000000000000000000000000000000000000000000000000000", "id": 1}' }
      subject { expect(contract.call_raw.greet[:formatted]).to eq ["ala"] }
      it_behaves_like "communicate with node"
    end
  end

  context "old block" do
    before { client.block_number = 1 }

    describe "#call" do
      let(:eth_send_request) { '{"jsonrpc":"2.0","method":"eth_call","params":[{"to":"0xaf83b6f1162062aa6711de633821f3e66b6fb3a5","from":"0x27dcb234fab8190e53e2d949d7b2c37411efb72e","data":"0xcfae3217"},"0x1"],"id":1}' }
      let(:eth_send_result) { '{"jsonrpc":"2.0", "result": "0x0000000000000000000000000000000000000000000000000000000000000023616c610000000000000000000000000000000000000000000000000000000000", "id": 1}' }
      subject { expect(contract.call.greet).to eq "ala" }
      it_behaves_like "communicate with node"
    end

    describe "#call_raw" do
      let(:eth_send_request) { '{"jsonrpc":"2.0","method":"eth_call","params":[{"to":"0xaf83b6f1162062aa6711de633821f3e66b6fb3a5","from":"0x27dcb234fab8190e53e2d949d7b2c37411efb72e","data":"0xcfae3217"},"0x1"],"id":1}' }
      let(:eth_send_result) { '{"jsonrpc":"2.0", "result": "0x0000000000000000000000000000000000000000000000000000000000000023616c610000000000000000000000000000000000000000000000000000000000", "id": 1}' }
      subject { expect(contract.call_raw.greet[:formatted]).to eq ["ala"] }
      it_behaves_like "communicate with node"
    end
  end


  context "truffle" do
    let(:tpaths) { [ './spec/truffle' ] }

    it "finds artifacts with explicit path list" do
      expect(EvmClient::Contract.find_truffle_artifacts('TestContractOne', tpaths)).not_to eql(nil)
    end

    it "finds artifacts with implicit path list" do
      expect(EvmClient::Contract.find_truffle_artifacts('TestContractOne')).to eql(nil)
      EvmClient::Contract.truffle_paths.concat(tpaths)
      expect(EvmClient::Contract.find_truffle_artifacts('TestContractOne')).not_to eql(nil)
      EvmClient::Contract.truffle_paths = []
    end

    it "loads contract data from the Truffle artifacts" do
      # net_address is from the artifacts file for network id '1234'
      net_address = '0xc0c32feb41be1f1eba28f3612d3ca7e458974cdb'
      artifacts = EvmClient::Contract.find_truffle_artifacts('TestContractOne', tpaths)
      tcontract = EvmClient::Contract.create(name: "TestContractOne", truffle: { paths: tpaths }, client: client, address: address)

      expect(tcontract.parent.code).to eql(artifacts['bytecode'][2, artifacts['bytecode'].length])
      expect(tcontract.abi).to eql(artifacts['abi'])
      expect(tcontract.address).to eql(address)

      expect(tcontract.call.methods).to include(:counter_for)
      expect(tcontract.call.methods).to include(:add_counter)
      expect(tcontract.call.methods).to include(:remove_counter)

      expect(tcontract.transact.methods).to include(:counter_for)
      expect(tcontract.transact.methods).to include(:add_counter)
      expect(tcontract.transact.methods).to include(:remove_counter)

      expect(tcontract.transact_and_wait.methods).to include(:counter_for)
      expect(tcontract.transact_and_wait.methods).to include(:add_counter)
      expect(tcontract.transact_and_wait.methods).to include(:remove_counter)

      tcontract = EvmClient::Contract.create(name: "TestContractOne", truffle: { paths: tpaths }, client: client)

      expect(tcontract.address).to eql(net_address)
    end
  end

end
