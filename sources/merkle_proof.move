module candymachine::merkle_proof{
    use std::vector;
    use aptos_std::aptos_hash;

    const BYTESLENGHTMISMATCH:u64 = 0;

    public fun verify(proof:vector<vector<u8>>,root:vector<u8>,leaf:vector<u8>):bool{
        let computedHash = leaf;
        assert!(vector::length(&root)==32,BYTESLENGHTMISMATCH);
        assert!(vector::length(&leaf)==32,BYTESLENGHTMISMATCH);
        let i = 0;
        while (i < vector::length(&proof)) {
            let proofElement=*vector::borrow_mut(&mut proof, i);
            if (compare_vector(& computedHash,& proofElement)==1) {
                vector::append(&mut computedHash,proofElement);
                computedHash = aptos_hash::keccak256(computedHash)
            }
            else{
                vector::append(&mut proofElement,computedHash);
                computedHash = aptos_hash::keccak256(proofElement)
            };
            i = i+1
        };
        computedHash == root
    }
    fun compare_vector(a:&vector<u8>,b:&vector<u8>):u8{
        let index = 0;
        while(index < vector::length(a)){
            if(*vector::borrow(a,index) > *vector::borrow(b,index)){
                return 0
            };
            if(*vector::borrow(a,index) < *vector::borrow(b,index)){
                return 1
            };
            index = index +1;
        };
        1
    }
   #[test]
    fun test_merkle(){
        let leaf1=  x"d4dee0beab2d53f2cc83e567171bd2820e49898130a22622b10ead383e90bd77";
        let leaf2 = x"5f16f4c7f149ac4f9510d9cf8cf384038ad348b3bcdc01915f95de12df9d1b02";
        let leaf3 = x"c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";
        let leaf4 = x"0da6e343c6ae1c7615934b7a8150d3512a624666036c06a92a56bbdaa4099751";
        // finding out the root
        let root1 = find_root(leaf1,leaf2);
        let root2 = find_root(leaf3,leaf4);
        let final_root = find_root(root1,root2);
        //the proofs
        let proof1 = vector[leaf2,root2];
        let proof2 = vector[leaf1,root2];
        let proof3 = vector[leaf4,root1];
        let proof4 = vector[leaf3,root1];
        //here
        assert!(verify(proof1,final_root,leaf1),99);
        assert!(verify(proof2,final_root,leaf2),100);
        assert!(verify(proof3,final_root,leaf3),101);
        assert!(verify(proof4,final_root,leaf4),102);
    }
    #[test]
    #[expected_failure(abort_code = 196609, location = Self)]
    fun test_failure(){
        let leaf1=  x"d4dee0beab2d53f2cc83e567171bd2820e49898130a22622b10ead383e90bd77";
        let leaf2 = x"5f16f4c7f149ac4f9510d9cf8cf384038ad348b3bcdc01915f95de12df9d1b02";
        let leaf3 = x"c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";
        let leaf4 = x"0da6e343c6ae1c7615934b7a8150d3512a624666036c06a92a56bbdaa4099751";
        // finding out the root
        let root1 = find_root(leaf1,leaf2);
        let root2 = find_root(leaf3,leaf4);
        let final_root = find_root(root1,root2);
        //the proofs
        let proof1 = vector[leaf2,root2];
        let proof2 = vector[leaf1,root2];
        let proof3 = vector[leaf4,root1];
        let proof4 = vector[leaf3,root1];
        //here
        assert!(verify(proof1,final_root, x"0e5751c026e543b2e8ab2eb06099daa1d1e5df47778f7787faab45cdf12fe3a8"),196609);
        assert!(verify(proof2,final_root, x"0e5751c026e543b2e8ab2eb06099daa1d1e5df47778f7787faab45cdf12fe3a8"),196609);
        assert!(verify(proof3,final_root, x"0e5751c026e543b2e8ab2eb06099daa1d1e5df47778f7787faab45cdf12fe3a8"),196609);
        assert!(verify(proof4,final_root, x"0e5751c026e543b2e8ab2eb06099daa1d1e5df47778f7787faab45cdf12fe3a8"),196609);
    }
    public fun find_root(leaf1:vector<u8>,leaf2:vector<u8>):vector<u8>{
        let root= vector<u8>[];
        if (compare_vector(& leaf1,& leaf2)==1) {
                vector::append(&mut root,leaf1);
                vector::append(&mut root,leaf2);
                root = aptos_hash::keccak256(root);
            }
            else{
                vector::append(&mut root,leaf2);
                vector::append(&mut root,leaf1);
                root = aptos_hash::keccak256(root);
            };
        root
    }
   
}