import keccak256 from "keccak256";
import MerkleTree from "merkletreejs";
import { buffer } from "stream/consumers";
export const NODE_URL = "https://fullnode.devnet.aptoslabs.com/v1";
export const FAUCET_URL = "https://faucet.devnet.aptoslabs.com";
export const privateKey = '0xdb69ce5645931a5af81af335d0a5c650bf1256527bdcd9b249840d5746c265dd';


let whitelistAddresses = [
    "0x147e4d3a5b10eaed2a93536e284c23096dfcea9ac61f0a8420e5d01fbd8f0ea8",
    "0x09d4ee382de0fa20f889ac6158273f29c81a1fec7385e8e26801db2e9e0c2f32",
    "0x09d4ee382de0fa20f889ac6158273f29c81a1fec7385e8e26801db2e9e0c2f32",
  ];
  let buffer2= Buffer.from([0x62])
  let leafNodes1 = whitelistAddresses.map((address) => Buffer.from(address));
  let leafNodes = leafNodes1.map((address)=> Buffer.concat([address, buffer2]));
 // console.log(leafNodes)
  let tree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });
  console.log(tree)
  let proof = tree.getHexProof((keccak256('0x09d4ee382de0fa20f889ac6158273f29c81a1fec7385e8e26801db2e9e0c2f32')));

//console.log(keccak256('0x36346bbcda6f9f74cf36cff31e00ac83c9d8a512a6564c9f93b00d249e3b2b45'))

  export let root = tree.getRoot();

  function convert_to_bytes(v:string[]):Uint8Array{
    let len = v.length;
    let result = new Uint8Array(32*len);
    for(let i = 0;i<len;i++){
        result.set(Buffer.from(v[i].slice(2),'hex'),i*32);
    }
    return result;
  }

  export function get_proof(account:string):Uint8Array{
    let proof = tree.getHexProof((keccak256(account)));
    return convert_to_bytes(proof)
  }