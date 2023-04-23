script {
    use candymachine::candymachine;
    fun main(minter:&signer, mint_limit:u64,candymachine:address) {
        let i = 0;
        while (i < mint_limit) {
            candymachine::mint_script(minter,candymachine);
            i = i +1; 
        }
    }
}