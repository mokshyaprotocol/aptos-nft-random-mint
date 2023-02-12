import keccak256 from "keccak256";
import MerkleTree from "merkletreejs";
export const NODE_URL = "https://fullnode.devnet.aptoslabs.com/v1";
export const FAUCET_URL = "https://faucet.devnet.aptoslabs.com";
export const privateKey = '0xdb69ce5645931a5af81af335d0a5c650bf1256527bdcd9b249840d5746c265dd';


let whitelistAddresses = [
    "0x147e4d3a5b10eaed2a93536e284c23096dfcea9ac61f0a8420e5d01fbd8f0ea8",
    "0x09d4ee382de0fa20f889ac6158273f29c81a1fec7385e8e26801db2e9e0c2f32",
  ];
  let leafNodes = whitelistAddresses.map((address) => Buffer.from(address));
  let tree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });
  console.log(tree)

  export let root = tree.getRoot();
  export let proof = tree.getProof((keccak256("0x09d4ee382de0fa20f889ac6158273f29c81a1fec7385e8e26801db2e9e0c2f32")));

  function convert_to_bytes(v:string[]):Uint8Array{
    let len = v.length;
    let result = new Uint8Array(32*len);
    for(let i = 0;i<len;i++){
        result.set(Buffer.from(v[i].slice(2),'hex'),i*32);
    }
    return result;
  }
  console.log(root.toString("hex"))
  let x= root.toString("hex");
  console.log(root.slice(2).toString("hex"))
  export function get_proof(account:string):Uint8Array{
    let proof = tree.getHexProof((keccak256(account)));
    return convert_to_bytes(proof)
  }
console.log()