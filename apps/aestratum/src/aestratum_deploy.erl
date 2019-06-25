-module(aestratum_deploy).

%% If there is a need to redeploy the payment contract in the future.

-include_lib("aecontract/include/aecontract.hrl").

-export([deploy_payout_contract/1]).

%% TX creating the contract for mainnet: th_2raHdPQ8xtbE6oKh3z1pFmUpyFC5H7ZTBkNB8TuVydJjwedduL
deploy_payout_contract(#{public := PubKey, secret := PrivKey}) ->
    DefaultGasPrice  = max(aec_governance:minimum_gas_price(1), % latest prototocol on height 1
                           aec_tx_pool:minimum_miner_gas_price()),
    {value, Account} = aec_chain:get_account(PubKey),
    {ok, CData}      = aeb_aevm_abi:create_calldata(
                         "init", [], [], {tuple, [typerep, {tuple, []}]}),
    {ok, WrappedTx}  =
        aect_create_tx:new(#{owner_id    => aeser_id:create(account, PubKey),
                             nonce       => aec_accounts:nonce(Account) + 1,
                             code        => aect_sophia:serialize(compiled_contract()),
                             vm_version  => ?VM_AEVM_SOPHIA_3,
                             abi_version => ?ABI_AEVM_SOPHIA_1,
                             deposit     => 0,
                             amount      => 0,
                             gas         => 100000,
                             gas_price   => DefaultGasPrice,
                             fee         => 1400000 * DefaultGasPrice,
                             call_data   => CData}),
    {_, CreateTx} = aetx:specialize_type(WrappedTx),
    CtPubkey = aect_create_tx:contract_pubkey(CreateTx),
    BinaryTx = aec_governance:add_network_id(aetx:serialize_to_binary(WrappedTx)),
    SignedTx = aetx_sign:new(WrappedTx, [enacl:sign_detached(BinaryTx, PrivKey)]),
    TxHash   = aeser_api_encoder:encode(tx_hash, aetx_sign:hash(SignedTx)),
    ok       = aec_tx_pool:push(SignedTx),
    {ok, TxHash, CtPubkey}.


%% result of: aeso_compiler:from_string(ContractSourceCode, [])
compiled_contract() ->
    #{byte_code =>
          <<98,0,0,143,98,0,0,175,145,128,128,128,81,127,185,201,86,
            242,139,49,73,169,245,152,122,165,5,243,218,27,34,9,204,
            87,57,35,64,6,43,182,193,189,159,159,153,234,20,98,0,1,
            75,87,80,128,128,81,127,170,97,66,82,40,160,57,22,116,
            246,237,171,231,238,59,113,24,169,72,22,219,183,202,143,
            231,5,20,229,121,203,193,104,20,98,0,0,218,87,80,128,81,
            127,250,60,115,222,30,152,157,207,11,184,199,190,14,144,
            153,194,55,18,155,75,8,17,115,199,210,152,155,51,184,
            162,218,139,20,98,0,1,87,87,80,96,1,25,81,0,91,96,0,25,
            89,96,32,1,144,129,82,96,32,144,3,96,3,129,82,144,89,96,
            0,81,89,82,96,0,82,96,0,243,91,96,0,128,82,96,0,243,91,
            89,89,96,32,1,144,129,82,96,32,144,3,96,0,25,89,96,32,1,
            144,129,82,96,32,144,3,96,3,129,82,129,82,144,86,91,96,
            32,1,81,81,144,80,89,80,128,145,80,80,128,96,0,144,145,
            80,91,129,128,96,1,1,98,0,1,0,87,80,128,145,80,80,144,
            86,91,128,96,1,1,98,0,1,16,87,80,96,1,25,81,0,91,128,81,
            128,81,144,96,32,1,81,145,96,32,1,81,96,0,96,0,96,0,132,
            89,96,32,1,144,129,82,96,32,144,3,96,1,129,82,134,96,0,
            90,241,80,128,131,133,1,148,80,148,80,80,80,80,98,0,0,
            238,86,91,80,80,130,145,80,80,98,0,0,183,86,91,96,32,1,
            81,128,81,144,96,32,1,81,89,80,129,129,146,80,146,80,80,
            98,0,0,238,86>>,
      compiler_version => <<"3.1.0">>,
      contract_source =>
          "contract Payout =\n\n  public stateful function payout(xs : list((address, int))) : int =\n    payout'(xs, 0)\n\n  stateful function payout'(xs : list((address, int)), total : int) : int =\n    switch(xs)\n      [] => total\n      (address, tokens) :: xs' =>\n        Chain.spend(address, tokens)\n        payout'(xs', total + tokens)\n",
      type_info =>
          [{<<170,97,66,82,40,160,57,22,116,246,237,171,231,238,59,
              113,24,169,72,22,219,183,202,143,231,5,20,229,121,203,
              193,104>>,
            <<"payout">>,
            <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,96,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,160,255,255,255,255,
              255,255,255,255,255,255,255,255,255,255,255,255,255,255,
              255,255,255,255,255,255,255,255,255,255,255,255,255,255,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,224,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,32,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,96,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,128,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,1,192,255,255,255,255,255,255,255,255,255,
              255,255,255,255,255,255,255,255,255,255,255,255,255,255,
              255,255,255,255,255,255,255,255,255,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>>,
            <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0>>},
           {<<185,201,86,242,139,49,73,169,245,152,122,165,5,243,218,
              27,34,9,204,87,57,35,64,6,43,182,193,189,159,159,153,
              234>>,
            <<"init">>,
            <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,3,255,255,255,255,255,255,255,255,255,
              255,255,255,255,255,255,255,255,255,255,255,255,255,255,
              255,255,255,255,255,255,255,255,255>>,
            <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,96,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,160,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,192,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,1,0,255,255,255,255,255,255,255,255,
              255,255,255,255,255,255,255,255,255,255,255,255,255,
              255,255,255,255,255,255,255,255,255,255,255,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,
              255,255,255,255,255,255,255,255,255,255,255,255,255,
              255,255,255,255,255,255,255,255,255,255,255,255,255,
              255,255,255,255,255,255>>},
           {<<250,60,115,222,30,152,157,207,11,184,199,190,14,144,
              153,194,55,18,155,75,8,17,115,199,210,152,155,51,184,
              162,218,139>>,
            <<"payout'">>,
            <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,96,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,160,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,224,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,224,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,1,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,96,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,128,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,1,192,255,255,255,255,255,255,255,255,255,255,255,
              255,255,255,255,255,255,255,255,255,255,255,255,255,255,
              255,255,255,255,255,255,255,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,32,255,255,
              255,255,255,255,255,255,255,255,255,255,255,255,255,255,
              255,255,255,255,255,255,255,255,255,255,255,255,255,255,
              255,255,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0>>,
            <<0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
              0,0,0,0,0,0,0,0,0,0,0,0,0>>}]}.
